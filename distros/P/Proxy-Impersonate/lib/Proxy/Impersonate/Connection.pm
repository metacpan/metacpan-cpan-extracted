package Proxy::Impersonate::Connection;
use v5.10; use strict; use warnings;
use EV;
use Errno qw(EAGAIN EWOULDBLOCK);
use Net::SSLeay ();
use Proxy::Impersonate::HTTP qw(parse_request_head body_length coherent_headers response_head strip_hop_headers);

# Per-WebKit-connection state machine. States:
#   plain     -- reading plaintext (initial: HTTP proxy request or CONNECT)
#   handshake -- Net::SSLeay server handshake in progress (post-CONNECT)
#   tls       -- reading decrypted requests over the terminated tunnel
# One request is in flight at a time (keep-alive, not pipelining); the upstream
# is driven by the shared Curl::Impersonate::Multi (wired to EV by the daemon).

my $HIWAT = 262144;   # pause upstream when this many bytes are queued to WebKit
my $IDLE  = 120;      # close a client that makes no read/write progress for this long
my $MAXHEAD = 65536;  # reject a request head larger than this (also caps a slow-drip head)

sub new {
    my ($class, %o) = @_;
    return bless {
        sock        => $o{fd},
        cert        => $o{cert},          # Proxy::Impersonate::Cert
        multi       => $o{multi},         # Curl::Impersonate::Multi (shared)
        multi_state => $o{multi_state} // {},
        override    => $o{override} // {},# headers forced on every upstream request
        chrome      => $o{chrome} // 0,   # is the impersonate target a Chrome family (Accept synthesis)
        high_entropy => $o{high_entropy} // {},   # high-entropy client hints (Accept-CH-gated)
        hints       => $o{hints} // {},   # shared: host -> { hint-name => 1 }
        make_handle => $o{make_handle},   # sub { Curl::Impersonate->new(...) }
        on_request  => $o{on_request},   # optional interception hook -- see _forward
        on_response => $o{on_response},  # optional response hook -- see _forward
        on_close    => $o{on_close} // sub {},
        state       => 'plain',
        rbuf        => '',
        wbuf        => '',
    }, $class;
}

sub start {
    my ($self) = @_;
    $self->{sock}->blocking(0);
    $self->_arm_read;
    # Reclaim a client that stalls -- a partial head, a wedged handshake, or a peer
    # that stops reading a paused download -- which would otherwise keep this
    # Connection pinned in the daemon's {conns} with its read watcher armed forever.
    # A repeating timer reset on I/O progress (_touch); fires only when truly idle.
    $self->{idle} = EV::timer($IDLE, $IDLE, sub { $self->_close });
    return $self;
}

# --- EV watcher management (one read + one write watcher, armed as needed) ---
sub _arm_read    { my $s = shift; $s->{io_r} ||= EV::io(fileno($s->{sock}), EV::READ,  sub { $s->_readable }) }
sub _arm_write   { my $s = shift; $s->{io_w} ||= EV::io(fileno($s->{sock}), EV::WRITE, sub { $s->_writable }) }
sub _disarm_write { $_[0]{io_w} = undef }
sub _touch        { $_[0]{idle}->again if $_[0]{idle} }   # reset the idle timeout on I/O progress

# --- readable: handshake, or decrypt/read into rbuf, then process ---
sub _readable {
    my ($self) = @_;
    return if $self->{_dead} || $self->{_closing};
    $self->_touch;
    # Bytes arriving during the deferred-TLS window (the 200 is still flushing, so
    # the tunnel is not up) mean the client sent before reading the 200 -- non-
    # compliant. Fast-close rather than read them into rbuf, where set_fd's later
    # handshake could never see them (they would stall to the idle timeout). This
    # mirrors the coalesced-ClientHello guard on the immediate CONNECT path.
    return $self->_close if $self->{_tls_pending};
    return $self->_do_handshake if $self->{state} eq 'handshake';
    if ($self->{ssl}) {
        while (1) {
            my ($got, $rv) = Net::SSLeay::read($self->{ssl}, 32768);
            if (defined $rv && $rv > 0) { $self->{rbuf} .= $got; next }   # drain pending
            my $e = Net::SSLeay::get_error($self->{ssl}, defined $rv ? $rv : -1);
            last if $e == Net::SSLeay::ERROR_WANT_READ();
            if ($e == Net::SSLeay::ERROR_WANT_WRITE()) { $self->_arm_write; last }
            return $self->_close;                      # ZERO_RETURN (EOF) or error
        }
    } else {
        my $n = sysread($self->{sock}, my $data, 32768);
        if (!defined $n) { return if $! == EAGAIN || $! == EWOULDBLOCK; return $self->_close }
        return $self->_close if $n == 0;               # EOF
        $self->{rbuf} .= $data;
    }
    $self->_process;
    # a prior SSL_write that wanted-read retries now that we've fed the SSL layer
    $self->_flush if !$self->{_dead} && length $self->{wbuf};
}

# --- parse + dispatch whole requests from rbuf ---
sub _process {
    my ($self) = @_;
    while (!$self->{_dead} && !$self->{_closing}) {
        return if $self->{inflight} || $self->{close_after_flush};
        my $end = index($self->{rbuf}, "\r\n\r\n");
        if ($end < 0) {                                # head incomplete: keep reading,
            return $self->_close if length($self->{rbuf}) > $MAXHEAD;  # unless it is a runaway
            return;                                    # (a never-terminating / slow-drip head)
        }
        return $self->_close if $end + 4 > $MAXHEAD;
        my $head = substr($self->{rbuf}, 0, $end + 4);
        my $r = parse_request_head($head);
        return $self->_reject(400, 'malformed request head') unless $r;
        my ($mode, $len) = body_length($r->{headers});
        return $self->_reject(400, 'invalid request framing') if $mode eq 'invalid';
        return $self->_reject(411, 'transfer-encoded request bodies are not supported')
            if $mode eq 'chunked';
        if ($self->{state} eq 'plain' && $r->{method} eq 'CONNECT') {
            return $self->_reject(400, 'invalid CONNECT authority')
                unless $r->{target} =~ /\A(?:\[[^\]]+\]|[^:\/?#@]+):\d+\z/ && !$len;
            substr($self->{rbuf}, 0, $end + 4, '');    # consume head
            # A compliant client waits for our 200 before starting TLS, so nothing
            # follows the CONNECT head yet. If a client optimistically COALESCED its
            # ClientHello into this segment, those bytes are now stranded in rbuf --
            # _begin_tls binds OpenSSL to the socket (set_fd), so a buffered
            # ClientHello is invisible to the handshake and it would stall until the
            # idle timeout. Fail fast and honestly rather than a 120s hang.
            return $self->_close if length $self->{rbuf};
            $self->{connect_host} = $r->{target};      # full authority host:port (curl strips :443)
            $self->{state} = 'tls';
            $self->_write_raw("HTTP/1.1 200 Connection established\r\n\r\n");
            # Begin TLS only once the 200 -- plus any pre-TLS plaintext still queued
            # from a prior pipelined response to a slow client -- has flushed.
            # Otherwise _begin_tls flips state to handshake, _writable routes to the
            # handshake (not _flush), and the queued 200 is stranded. _flush resumes
            # this via _tls_pending when wbuf drains to empty.
            if (length $self->{wbuf}) { $self->{_tls_pending} = 1 }
            elsif ($self->{cert})     { $self->_begin_tls }   # (test passes cert=>undef)
            return;
        }
        my $need = $end + 4 + ($mode eq 'length' ? $len : 0);
        if ($mode eq 'length' && length($self->{rbuf}) < $need) {
            if (!$self->{sent_continue}) {
                my @expect = map { lc $_->[1] } grep { lc($_->[0]) eq 'expect' } @{$r->{headers}};
                if (@expect) {
                    return $self->_reject(417, 'unsupported expectation')
                        if grep { $_ ne '100-continue' } @expect;
                    $self->{sent_continue} = 1;
                    $self->_write_client("HTTP/1.1 100 Continue\r\n\r\n");
                }
            }
            return;
        }
        delete $self->{sent_continue};
        substr($self->{rbuf}, 0, $end + 4, '');        # consume head
        my $body = ($mode eq 'length' && $len) ? substr($self->{rbuf}, 0, $len, '') : '';
        $r->{body} = $body;
        my $connection = lc join ',', $head =~ /\r\nconnection:[ \t]*([^\r\n]*)/ig;
        $self->{request_close} = $connection =~ /(?:^|,)\s*close\s*(?:,|$)/
            || ($r->{version} eq 'HTTP/1.0' && $connection !~ /(?:^|,)\s*keep-alive\s*(?:,|$)/);
        $self->_forward($r, absolute => ($self->{state} eq 'plain'));
        return;                                        # inflight set; resume on on_done
    }
}

sub _reject {
    my ($self, $status, $msg) = @_;
    $self->{rbuf} = '';
    $self->{_closing} = $self->{close_after_flush} = $self->{response_complete} = 1;
    $self->_write_client(response_head($status,
        { 'content-type' => 'text/plain', 'content-length' => length($msg),
          connection => 'close' }) . $msg);
    $self->_maybe_close_after_flush;
}

sub _bodyless { $_[0] eq 'HEAD' || $_[1] < 200 || $_[1] == 204 || $_[1] == 205 || $_[1] == 304 }

# --- forward one request upstream and stream the response back ---
sub _forward {
    my ($self, $r, %opt) = @_;
    my $url = $opt{absolute} ? $r->{target} : "https://$self->{connect_host}$r->{target}";
    my $fwd = coherent_headers($r->{headers}, $self->{chrome});
    # forced identity headers (UA + low-entropy client hints) over curl's defaults
    $fwd = { %$fwd, %{ $self->{override} } };
    # high-entropy client hints only for a host that has sent Accept-CH (as Chrome
    # does). Derive the bare host for that key: prefer the CONNECT authority (tls),
    # else the absolute-request URL's authority (plain). Handle a bracketed IPv6
    # literal ([::1]:443 -> ::1), not just host:port -- else distinct IPv6 origins
    # collide under a truncated key.
    my $auth = $self->{connect_host};
    ($auth) = $url =~ m{^https?://([^/]+)} if !defined $auth;
    $auth //= '';
    my $host;
    if    ($auth =~ /^\[([^\]]+)\]/) { $host = $1 }   # [ipv6](:port)?
    elsif ($auth =~ /^([^:]+)/)      { $host = $1 }   # host(:port)?
    $self->{_req_host} = $host;
    if ($host && (my $want = $self->{hints}{$host})) {
        $fwd->{$_} = $self->{high_entropy}{$_}
            for grep { exists $self->{high_entropy}{$_} } keys %$want;
    }
    # Interception point. Everything the request will be is now assembled and
    # still plaintext -- after TLS termination, before anything goes upstream --
    # so a hook here sees EVERY request the browser makes (navigations,
    # subresources, XHR, fetch), which no WebKit-side API does, and can rewrite
    # it, answer it locally, or refuse it.
    if (my $cb = $self->{on_request}) {
        my $req = { method => $r->{method}, url => $url, headers => $fwd,
                    body => $r->{body}, host => $host };
        my $res = eval { $cb->($req) };
        return if $self->{_dead} || $self->{_closing};
        if ($@) {
            # Fail CLOSED, like the sibling on_policy gate in EV::WebKit: this
            # hook is used to BLOCK requests, so a handler that dies must not
            # quietly let the request through -- that is precisely the traffic
            # the caller was trying to stop.
            warn "Proxy::Impersonate: on_request died (refusing the request): $@";
            $res = { status => 502, body => 'on_request handler died' };
        }
        else {
            # Honour in-place rewrites of any field.
            ($url, $fwd) = ($req->{url}, $req->{headers} // {});
            $r->{method} = $req->{method};
            $r->{body}   = $req->{body};
        }
        if (ref $res eq 'HASH') {
            # A synthetic response: answer from here and never touch the
            # network. Content-Length is computed rather than trusted, so a
            # handler cannot desynchronise the connection by disagreeing with
            # its own body.
            my $body = defined $res->{body} ? $res->{body} : '';
            utf8::encode($body) if utf8::is_utf8($body);
            my %h = map { lc($_) => $res->{headers}{$_} } keys %{ $res->{headers} // {} };
            strip_hop_headers(\%h);
            delete $h{'content-length'};
            $h{'content-type'} //= 'text/plain';
            $h{'content-length'} = length $body;
            my $status = $res->{status} || 200;
            delete $h{'content-length'} if $status == 204 || $status == 304 || $status < 200;
            $h{'content-length'} = 0 if $status == 205;
            $body = '' if _bodyless($r->{method}, $status);
            if ($self->{request_close}) {
                $h{connection} = 'close';
                $self->{close_after_flush} = 1;
            }
            $self->{wrote_headers}     = 1;
            $self->{response_complete} = 1;
            $self->_write_client(response_head($status, \%h) . $body);
            return $self->_maybe_close_after_flush if $self->{close_after_flush};
            # Keep-alive is safe here precisely because the length is exact.
            $self->_reset_for_next;
            $self->_process;
            return;
        }
        return $self->_close if defined $res && !ref $res && $res eq 'abort';
    }
    $self->{wrote_headers} = 0;
    $self->{response_complete} = 0;
    $self->{close_after_flush} = 0;
    $self->{chunked} = 0;
    my $suppress_body = 0;
    # Guarded: add_streaming validates what it is handed and croaks on anything
    # it will not send. Escaping here would unwind out of an EV watcher and take
    # the daemon with it, so answer the client instead.
    my $added = eval {
        my $h = $self->{inflight} = $self->{make_handle}->();
        $self->{multi}->add_streaming($h,
        { method => $r->{method}, url => $url, headers => $fwd, body => $r->{body} },
        {
            on_headers => sub {
                my ($status, $hdrs) = @_;
                return if $self->{_dead} || $self->{_closing};
                $self->{wrote_headers} = 1;
                # learn which high-entropy hints this host wants (Accept-CH), so
                # later requests to it carry them -- matching Chrome's behavior
                if (defined $self->{_req_host} && (my $ach = $hdrs->{'accept-ch'})) {
                    # bound memory on a long-running proxy: the per-host map has no
                    # TTL, so clear it if it grows large (hints are cheaply re-learned)
                    %{ $self->{hints} } = () if keys %{ $self->{hints} } > 4096;
                    my $h = ref $ach eq 'ARRAY' ? join(',', @$ach) : $ach;
                    for my $req (split /\s*,\s*/, lc $h) {
                        $self->{hints}{$self->{_req_host}}{$req} = 1
                            if exists $self->{high_entropy}{$req};
                    }
                }
                my %h = %$hdrs;
                strip_hop_headers(\%h);
                # The handle is built with decode => 1, so a compressed body
                # arrives already decompressed while the origin's own
                # Content-Encoding and Content-Length still describe the bytes
                # BEFORE decoding. Forwarding either would have the client
                # inflate an already-inflated body, or cut it at the compressed
                # length. Both headers go, and the length that replaces them is
                # chunked framing -- WebKit cannot decode zstd, which real Chrome
                # advertises, so passing the encoding through renders the page as
                # binary. HEAD/304 must also drop encoded metadata, or a cache
                # update would label its already-decoded body as compressed.
                my $bodyless = _bodyless($r->{method}, $status);
                if (defined $h{'content-encoding'}) {
                    delete @h{qw(content-encoding content-length)};
                    if (!$bodyless) {
                        if ($r->{version} eq 'HTTP/1.0') {
                            $h{connection} = 'close';
                            $self->{close_after_flush} = 1;
                        }
                        else {
                            $h{'transfer-encoding'} = 'chunked';
                            $self->{chunked} = 1;
                        }
                    }
                }
                elsif (!$bodyless && !exists $h{'content-length'}) {
                    # length unknown and nothing to re-frame: delimit by closing
                    $h{connection} = 'close';
                    $self->{close_after_flush} = 1;
                }
                # Response interception, the counterpart to on_request. Status and
                # headers may be rewritten -- stripping Content-Security-Policy or
                # X-Frame-Options is the usual reason -- but the FRAMING is ours,
                # not the handler's: content-length and the hop-by-hop set are
                # snapshotted here and forced back afterwards, because a handler
                # that edits them does not desynchronise its own connection, it
                # desynchronises the browser's.
                if (my $cb = $self->{on_response}) {
                    my $framing_len  = $h{'content-length'};
                    my $framing_conn = $h{connection};
                    my $framing_te   = $h{'transfer-encoding'};
                    my $res = { status => $status,
                                headers => { map { $_ => ref $h{$_} eq 'ARRAY' ? [@{$h{$_}}] : $h{$_} } keys %h },
                                url => $url, method => $r->{method}, host => $host };
                    if (eval { $cb->($res); 1 }) {
                        $status = $res->{status} if defined $res->{status};
                        %h = map { lc($_) => $res->{headers}{$_} } keys %{ $res->{headers} }
                            if ref $res->{headers} eq 'HASH';
                    }
                    else {
                        # Fail OPEN here, unlike on_request. This hook observes a
                        # response that has already been fetched; refusing it would
                        # break a page over a bug in an observer, and there is no
                        # security decision left to fail closed on -- the request
                        # was already made.
                        warn "Proxy::Impersonate: on_response died (passing the response through): $@";
                    }
                    return if $self->{_dead} || $self->{_closing};
                    strip_hop_headers(\%h);
                    defined $framing_len  ? ($h{'content-length'} = $framing_len)
                                          : delete $h{'content-length'};
                    defined $framing_conn ? ($h{connection} = $framing_conn)
                                          : delete $h{connection};
                    defined $framing_te   ? ($h{'transfer-encoding'} = $framing_te)
                                          : delete $h{'transfer-encoding'};
                }
                my $final_bodyless = _bodyless($r->{method}, $status);
                $suppress_body = $final_bodyless || $bodyless;
                if ($suppress_body) {
                    $self->{chunked} = $self->{close_after_flush} = 0;
                    delete @h{qw(transfer-encoding connection)};
                    if (!$final_bodyless) {
                        delete $h{'content-encoding'};
                        $h{'content-length'} = 0;
                    }
                    delete $h{'content-length'} if $status == 204 || $status < 200;
                    $h{'content-length'} = 0 if $status == 205;
                    delete $h{'content-length'} if $status == 304;
                }
                if ($self->{request_close}) {
                    $h{connection} = 'close';
                    $self->{close_after_flush} = 1;
                }
                $self->_write_client(response_head($status, \%h));
            },
            on_body => sub {
                my ($chunk) = @_;
                return 2 if $self->{_write_dead};
                return 0 if $suppress_body;
                # Pause BEFORE consuming when already backed up: libcurl treats a
                # CURL_WRITEFUNC_PAUSE return as "this chunk was NOT consumed" and
                # re-delivers it on resume. Appending it here AND pausing would then
                # write it twice -- corrupting (duplicating a 16 KiB block in) any
                # response larger than HIWAT. Resume only fires once wbuf has drained
                # to empty, so the replayed chunk is appended exactly once.
                if (length($self->{wbuf}) >= $HIWAT) { $self->{paused} = 1; return 1 }
                # Framed here, not in on_headers: a paused chunk is re-delivered
                # on resume, and the pause above returns before consuming it, so
                # each chunk is wrapped exactly once.
                $chunk = sprintf("%X\r\n", length $chunk) . $chunk . "\r\n"
                    if $self->{chunked} && length $chunk;
                $self->_write_client($chunk);
                return 2 if $self->{_write_dead};                # write just failed -> abort
                return 0;
            },
            on_done => sub {
                my ($err) = @_;
                delete $self->{inflight};
                return $self->_close if $self->{_write_dead} || $self->{_dead} || $self->{_closing};
                if ($err && !$self->{wrote_headers}) {           # failed before any byte
                    my $msg = "upstream error: $err";
                    $self->_write_client(response_head(502,
                        { 'content-type' => 'text/plain', 'content-length' => length($msg),
                          'connection' => 'close' }) . $msg);
                    $self->{close_after_flush} = 1;
                    $self->{response_complete} = 1;
                    return $self->_maybe_close_after_flush;
                }
                return $self->_close if $err;                    # failed mid-stream -> abort
                # Close the chunked body. Only on success: a truncated response
                # must NOT be terminated, or the client accepts a short body as
                # complete -- the abort above is what tells it something broke.
                if ($self->{chunked}) {
                    $self->_write_client("0\r\n\r\n");
                    return $self->_close if $self->{_write_dead};
                }
                $self->{response_complete} = 1;
                if ($self->{close_after_flush}) { $self->_maybe_close_after_flush }
                else { $self->_reset_for_next; $self->_process }  # keep-alive
            },
        }); 1 };
    if (!$added) {
        my $why = $@ || 'upstream refused the request';
        $why =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//;
        warn "Proxy::Impersonate: could not forward the request: $why\n";
        delete $self->{inflight};
        my $msg = 'could not forward the request';
        $self->{wrote_headers}     = 1;
        $self->{response_complete} = 1;
        $self->_write_client(response_head(502,
            { 'content-type' => 'text/plain', 'content-length' => length($msg),
              'connection' => 'close' }) . $msg);
        $self->{close_after_flush} = 1;
        return $self->_maybe_close_after_flush;
    }
}

sub _reset_for_next {
    my ($self) = @_;
    delete @{$self}{qw(wrote_headers response_complete close_after_flush _write_dead chunked request_close)};
}

sub _maybe_close_after_flush {
    my ($self) = @_;
    $self->_close if $self->{close_after_flush} && $self->{response_complete}
                  && !length($self->{wbuf}) && !$self->{inflight};
}

# --- Net::SSLeay server handshake, EV-driven ---
sub _begin_tls {
    my ($self) = @_;
    my $ctx = $self->{ctx} = Net::SSLeay::CTX_new();
    Net::SSLeay::CTX_set_options($ctx, &Net::SSLeay::OP_ALL);
    # After SSL_write returns WANT_WRITE, an upstream on_body appends to wbuf before
    # the retry, which can realloc (move) the Perl PV. Without this mode OpenSSL
    # rejects a moved retry buffer with "bad write retry" (fatal) and the HTTPS
    # response is silently truncated -- exactly the backpressure path HIWAT builds.
    # 0x2 == SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER (fixed OpenSSL value; the pending
    # prefix bytes are never mutated, only appended after, so the mode is safe).
    Net::SSLeay::CTX_set_mode($ctx, 0x2);
    $self->{cert}->apply_to_ctx($ctx);
    my $ssl = $self->{ssl} = Net::SSLeay::new($ctx);
    Net::SSLeay::set_fd($ssl, fileno($self->{sock}));
    $self->{state} = 'handshake';
    $self->_do_handshake;
}

sub _do_handshake {
    my ($self) = @_;
    my $rc = Net::SSLeay::accept($self->{ssl});
    # On success, drain via _readable (SSL_read loop), not _process: a TLS 1.3
    # client's Finished + first request can coalesce into one segment, leaving the
    # request buffered inside OpenSSL where a bare _process (which only reads rbuf)
    # would never see it -> hang.
    if ($rc > 0) { $self->{state} = 'tls'; $self->_disarm_write; return $self->_readable }
    my $e = Net::SSLeay::get_error($self->{ssl}, $rc);
    if    ($e == Net::SSLeay::ERROR_WANT_READ())  { $self->_disarm_write }   # read watcher already armed
    elsif ($e == Net::SSLeay::ERROR_WANT_WRITE()) { $self->_arm_write }
    else  { $self->_close }
}

# --- writable: continue a handshake, or flush the client write buffer ---
sub _writable {
    my ($self) = @_;
    return $self->_do_handshake if $self->{state} eq 'handshake';
    $self->_flush;
}

sub _write_raw    { my ($self, $d) = @_; $self->{wbuf} .= $d; $self->_flush }   # pre-TLS plaintext
sub _write_client { my ($self, $d) = @_; $self->{wbuf} .= $d; $self->_flush }

# A fatal write to the client: never _close synchronously from here, because
# _flush can run inside an upstream on_body/on_headers callback and _close would
# reentrantly remove() the in-flight handle. Mark the write dead so on_body
# aborts the transfer (curl -> on_done -> safe _close); close directly only when
# no forward is in flight.
sub _fail_write {
    my ($self) = @_;
    $self->{_write_dead} = 1;
    $self->_disarm_write;                          # nothing more to write; don't spin
    if ($self->{inflight}) {
        # wake a paused upstream so on_body sees _write_dead and aborts promptly
        # (instead of waiting for the request timeout)
        if ($self->{paused}) {
            $self->{paused} = 0;
            local $self->{multi_state}{busy} = 1;
            eval { $self->{multi}->resume($self->{inflight}) };
        }
        return;
    }
    $self->_close;
}

sub _flush {
    my ($self) = @_;
    if (!length $self->{wbuf}) { $self->_disarm_write; return }   # nothing to write; drop the watcher
    my $n;
    if ($self->{ssl}) {
        # A WANT retry must keep its original byte count even if wbuf grew.
        my $pending = $self->{ssl_write_len};
        $n = defined $pending
            ? Net::SSLeay::write_partial($self->{ssl}, 0, $pending, $self->{wbuf})
            : Net::SSLeay::write($self->{ssl}, $self->{wbuf});
        if (!defined $n || $n <= 0) {
            my $e = Net::SSLeay::get_error($self->{ssl}, defined $n ? $n : -1);
            if ($e == Net::SSLeay::ERROR_WANT_WRITE() || $e == Net::SSLeay::ERROR_WANT_READ()) {
                $self->{ssl_write_len} //= length $self->{wbuf};
                return $self->_arm_write if $e == Net::SSLeay::ERROR_WANT_WRITE();
                $self->_disarm_write; return;
            }
            return $self->_fail_write;
        }
        delete $self->{ssl_write_len} if defined $pending;
    } else {
        $n = syswrite($self->{sock}, $self->{wbuf});
        if (!defined $n) { return $self->_arm_write if $! == EAGAIN || $! == EWOULDBLOCK; return $self->_fail_write }
    }
    substr($self->{wbuf}, 0, $n, '');
    $self->{idle}->again if $self->{idle};                   # wrote bytes -> progress
    if (length $self->{wbuf}) { return $self->_arm_write }   # partial; finish later
    $self->_disarm_write;
    # pre-TLS plaintext (the CONNECT 200, possibly behind a prior response tail) has
    # now fully flushed -> it is safe to start the handshake (deferred from CONNECT)
    if (delete $self->{_tls_pending} && $self->{cert}) { return $self->_begin_tls }
    if ($self->{paused}) {                                   # room again -> resume upstream
        $self->{paused} = 0;
        local $self->{multi_state}{busy} = 1;
        $self->{multi}->resume($self->{inflight}) if $self->{inflight};
    }
    $self->_maybe_close_after_flush if $self->{close_after_flush};
}

sub _close {
    my ($self) = @_;
    return if $self->{_dead};
    $self->{_write_dead} = 1;
    if ($self->{multi_state}{busy}) {
        $self->{_closing} = 1;
        $self->{closer} ||= EV::timer(0, 0, sub { delete $self->{closer}; $self->_close });
        return;
    }
    $self->{_dead} = 1;
    $self->{io_r} = undef; $self->{io_w} = undef; $self->{idle} = undef; $self->{closer} = undef;
    if ($self->{inflight}) { eval { $self->{multi}->remove($self->{inflight}) }; delete $self->{inflight} }
    if ($self->{ssl}) { Net::SSLeay::free($self->{ssl}); undef $self->{ssl} }
    if ($self->{ctx}) { Net::SSLeay::CTX_free($self->{ctx}); undef $self->{ctx} }
    close $self->{sock} if $self->{sock};
    my $on_close = delete $self->{on_close};
    delete @{$self}{qw(make_handle on_request on_response)};
    $on_close->($self) if $on_close;
}

1;

__END__

=head1 NAME

Proxy::Impersonate::Connection - one client connection's state machine

=head1 DESCRIPTION

One instance per client connection, created by L<Proxy::Impersonate> on accept.
Reads a plaintext proxy request or a C<CONNECT>, terminates TLS for the latter
with L<Proxy::Impersonate::Cert>, then forwards each request upstream through
the shared L<Curl::Impersonate> multi handle and streams the response back --
with backpressure, so a slow client cannot make the proxy buffer without bound.
You do not normally touch it directly.

The C<on_request> hook documented in L<Proxy::Impersonate/new> fires here, in
C<_forward>: after TLS termination and before anything goes upstream, which is
the only point where the request exists in plaintext and is still changeable.

=cut
