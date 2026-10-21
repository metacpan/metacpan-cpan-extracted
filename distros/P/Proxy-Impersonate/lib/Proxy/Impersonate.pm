package Proxy::Impersonate;
use v5.10; use strict; use warnings;
use Carp ();
use EV;
use Socket;
use Scalar::Util ();
use File::Temp ();
use Curl::Impersonate 0.03;
use Proxy::Impersonate::Cert;
use Proxy::Impersonate::Connection;

our $VERSION = '0.03';

sub new {
    my ($class, %o) = @_;
    # A client that resets mid-response makes a write raise SIGPIPE, whose default
    # disposition terminates the process -- and since this proxy runs in-process
    # with EV::WebKit, that would take the browser down before the graceful abort
    # path runs. Ignore it (standard for a network server).
    $SIG{PIPE} = 'IGNORE';
    my $target = $o{impersonate} or Carp::croak('new: impersonate target required');
    my ($host, $port) = ($o{listen} // '127.0.0.1:0') =~ /^(.+):(\d+)$/
        or Carp::croak('new: listen must be host:port');
    my $temp_dir = defined $o{cert_dir} ? undef : File::Temp->newdir;
    my $cert_dir = $o{cert_dir} // "$temp_dir";

    socket(my $srv, PF_INET, SOCK_STREAM, 0) or Carp::croak("socket: $!");
    setsockopt($srv, SOL_SOCKET, SO_REUSEADDR, 1);
    bind($srv, sockaddr_in($port, inet_aton($host))) or Carp::croak("bind: $!");
    listen($srv, 128) or Carp::croak("listen: $!");
    $srv->blocking(0);
    my $bound = (sockaddr_in(getsockname($srv)))[0];

    my $self = bless {
        srv     => $srv,
        port    => $bound,
        cert    => Proxy::Impersonate::Cert->new(cert_dir => $cert_dir),
        cert_dir=> $cert_dir,
        temp_dir=> $temp_dir,
        target  => $target,
        # Is the impersonate target a Chromium family? Decides whether the per-
        # request Accept is synthesized to Chrome's value or WebKit's own (Safari-
        # correct) value is forwarded -- so a Safari target does not present a Chrome
        # Accept. Chromium engines (Chrome/Edge/Chromium) send the same Accept; a
        # non-matching Chromium target name can force it with an explicit chrome => .
        chrome  => (($o{chrome} // ($target =~ /chrome|chromium|edge/i)) ? 1 : 0),
        timeout => $o{timeout} // 30,
        verify  => defined $o{verify} ? $o{verify} : 1,
        follow  => $o{follow_redirects} // 0,
        override => $o{override_headers} // {},   # forced on every upstream request
        on_request => $o{on_request},             # optional per-request interception hook
        on_response => $o{on_response},           # optional per-response hook
        high_entropy => $o{high_entropy_headers} // {}, # added per-host after Accept-CH
        hints    => {},                           # host -> { hint-name => 1 } (Accept-CH seen)
        multi   => Curl::Impersonate->multi,
        multi_state => {},
        conns   => {},
        cio     => {},   # curl fd => EV::io watcher
    }, $class;

    $self->_wire_multi;
    # weaken $self in the accept watcher: otherwise $self -> {aw} -> closure -> $self
    # is a cycle that keeps the daemon (and its listen socket) alive -- still
    # accepting -- after the caller drops its reference without stop()/shutdown().
    # The documented usage (hold the ref, then stop/shutdown) is unaffected.
    Scalar::Util::weaken(my $wself = $self);
    $self->{aw} = EV::io(fileno($srv), EV::READ, sub { $wself && $wself->_accept });
    return $self;
}

sub port     { $_[0]{port} }
sub cert_dir { $_[0]{cert_dir} }

# Drive Curl::Impersonate::Multi from the EV loop via its socket-action surface.
# The stored callbacks close over $self and the multi; weaken both so they do NOT
# form a reference cycle (multi -> callback -> $self -> $self->{multi} = multi)
# that would keep the multi alive and prevent its DESTROY (curl_multi_cleanup)
# from ever running -- a per-session leak of the handle + its upstream sockets.
sub _wire_multi {
    my ($self) = @_;
    my $m = $self->{multi};
    my $state = $self->{multi_state};
    Scalar::Util::weaken(my $wself = $self);
    Scalar::Util::weaken(my $wm    = $m);
    $m->set_socket_callback(sub {
        my ($fd, $what) = @_;
        return unless $wself && $wm && !$wself->{_shutdown};
        if ($what == 4) { delete $wself->{cio}{$fd}; return }  # CURL_POLL_REMOVE
        my $events = 0;
        $events |= EV::READ  if $what & 1;                     # POLL_IN
        $events |= EV::WRITE if $what & 2;                     # POLL_OUT
        $wself->{cio}{$fd} = EV::io($fd, $events, sub {
            my (undef, $revents) = @_;
            return unless $wm;
            my $ev = 0;
            $ev |= 1 if $revents & EV::READ;
            $ev |= 2 if $revents & EV::WRITE;
            $ev = 3 unless $ev;                                # fallback: try both
            local $state->{busy} = 1;
            $wm->socket_action($fd, $ev);
        });
    });
    $m->set_timer_callback(sub {
        my ($ms) = @_;
        return unless $wself && $wm && !$wself->{_shutdown};
        if ($ms < 0) { undef $wself->{ctimer}; return }
        $wself->{ctimer} = EV::timer($ms / 1000, 0, sub {
            local $state->{busy} = 1;
            $wm->socket_action(-1, 0) if $wm;
        });
    });
}

sub _accept {
    my ($self) = @_;
    Scalar::Util::weaken(my $wself = $self);
    while (accept(my $cli, $self->{srv})) {
        my $conn = Proxy::Impersonate::Connection->new(
            fd    => $cli,
            cert  => $self->{cert},
            multi => $self->{multi},
            multi_state => $self->{multi_state},
            override => $self->{override},
            on_request => $self->{on_request},
            on_response => $self->{on_response},
            chrome => $self->{chrome},
            high_entropy => $self->{high_entropy},
            hints => $self->{hints},
            make_handle => sub {
                Curl::Impersonate->new(
                    impersonate => $wself->{target},
                    verify      => $wself->{verify},
                    timeout     => $wself->{timeout},
                    decode      => 1,
                    ($wself->{follow} ? (follow_redirects => 1) : ()),
                );
            },
            on_close => sub { delete $wself->{conns}{ $_[0] } if $wself },
        );
        $self->{conns}{$conn} = $conn;
        $conn->start;
    }
}

sub run  { EV::run }
sub stop {
    my ($self) = @_;
    undef $self->{aw};
    close delete $self->{srv} if $self->{srv};
    EV::break(EV::BREAK_ALL);
}

# In-process teardown: stop accepting, close active connections, release the
# curl_multi wiring. Unlike stop(), does NOT EV::break -- the caller's shared
# loop keeps running (e.g. EV::WebKit's browser loop).
sub shutdown {
    my ($self) = @_;
    $self->{_shutdown} = 1;
    undef $self->{aw};
    close delete $self->{srv} if $self->{srv};
    my @conns = values %{ $self->{conns} || {} };   # snapshot: _close mutates {conns} via on_close
    $self->{conns} = {};
    for my $c (@conns) { eval { $c->_close } }
    $self->{cio} = {};
    undef $self->{ctimer};
    undef $self->{multi};
    delete @{$self}{qw(on_request on_response)};
    return $self;
}

sub DESTROY { $_[0]->shutdown }

1;

__END__

=head1 NAME

Proxy::Impersonate - EV MITM proxy that re-originates with a browser TLS/HTTP2 fingerprint

=head1 SYNOPSIS

    use EV;
    use Proxy::Impersonate;

    my $proxy = Proxy::Impersonate->new(
        impersonate => 'chrome131',
        listen      => '127.0.0.1:0',   # ephemeral port
        cert_dir    => '/path/to/ca',   # persists the self-signed cert
    );
    printf "proxy on 127.0.0.1:%d\n", $proxy->port;
    $proxy->run;   # EV loop

A client (or EV::WebKit) uses it as an HTTP/HTTPS forward proxy. For HTTPS the
client issues C<CONNECT host:443>; the proxy terminates that TLS with its own
cert, then re-originates the request upstream through L<Curl::Impersonate> so the
origin sees the chosen browser's TLS (JA3/JA4) and HTTP/2 (Akamai) fingerprint.

=head1 DESCRIPTION

EV::WebKit cannot present a browser's connection fingerprint itself -- WebKitGTK
speaks GnuTLS/libsoup. This proxy sits in front of it: it MITMs WebKit's TLS on
localhost, reads the plaintext request, and sends it upstream with a real
browser's handshake via C<libcurl-impersonate>. The origin's TLS/HTTP2
fingerprint therefore matches the impersonated browser, not WebKit.

It is an HTTP client, not a browser: it reproduces the B<connection>
fingerprint only. HTTP/3 and WebSockets are out of scope in this release, as are
streaming request uploads. A CONNECT client must wait for the C<200> response
before beginning its TLS handshake: a ClientHello optimistically coalesced into
the CONNECT segment is not supported (the connection is closed rather than left
to stall). Browsers and libsoup -- the intended clients -- already do this.

B<Header-order ceiling:> curl-impersonate reproduces the target's TLS (JA3/JA4)
and HTTP/2 (Akamai) fingerprints exactly, and template headers keep their
positions. But headers the proxy adds that are not in the template (Cookie,
Referer, and the high-entropy Sec-CH-UA hints) are appended after the template
block rather than in the browser's exact positions, so a header-order-only hash
(e.g. JA4H) will not match on requests carrying them. The dominant fingerprints
(JA3/JA4/Akamai) are unaffected.

B<Priority ceiling:> the proxy synthesizes a per-destination Accept, but the
HTTP/2 request priority (the C<priority> header and any PRIORITY_UPDATE frames)
comes from curl-impersonate's static template, not from the resource type. Chrome
varies urgency per resource; the proxy does not, so a resource-priority-aware
fingerprinter could tell subresources apart. This lives in curl-impersonate's
protocol layer, not in a header the proxy re-writes.

=head1 TRUST MODEL

WebKitGTK 6.0 exposes no way to trust a custom CA (its network process honors
neither C<SSL_CERT_FILE> nor a settable C<GTlsDatabase>; this was verified by a
spike). So the proxy presents a single self-signed cert and the WebKit side is
told to accept it:

    # on the EV::WebKit network session (sub-project 3 wires this):
    $session->set_tls_errors_policy('ignore');
    $browser->set_proxy("http://127.0.0.1:" . $proxy->port);

This is safe: the WebKit-to-proxy hop is localhost, and the proxy re-verifies the
real origin certificate upstream (C<< verify => 1 >>, the default).

=head1 METHODS

=head2 new

    my $proxy = Proxy::Impersonate->new(%opt);

=over 4

=item impersonate => $target

Required. The L<Curl::Impersonate> target (e.g. C<'chrome131'>) applied to every
upstream request. Keep it coherent with EV::WebKit's C<fingerprint> profile.

=item listen => 'host:port'

Bind address; default C<'127.0.0.1:0'> (an ephemeral port, reported by L</port>).

=item cert_dir => $path

Where the self-signed cert is persisted. Defaults to a temporary directory
(mode 0700), which is the safe case.

If you point this at a location of your own, note that an B<existing> key there
is adopted, and whoever can write that key can impersonate this proxy to the
client it fronts -- which is configured to accept its certificate. So a key
that is group- or world-accessible, owned by another user, or a symlink is
B<refused> rather than used. Keep it 0600 and yours.

=item on_request => sub { my ($req) = @_; ... }

Per-request interception hook, called after TLS termination and before anything
goes upstream -- so it sees B<every> request the client makes (navigations,
subresources, XHR, fetch), and can rewrite, answer or refuse each one.

C<$req> is a hashref with C<method>, C<url>, C<headers> (a lowercase-keyed
hashref), C<body> and C<host> (the bare hostname). Modify C<method>, C<url>,
C<headers> or C<body> in place to rewrite the request:

    on_request => sub {
        my ($req) = @_;
        $req->{url} =~ s{^https://cdn\.}{https://local-mirror.};
        $req->{headers}{'x-trace'} = 'yes';
        return;                       # proceed with the rewrite
    }

Return value decides what happens next:

=over 4

=item nothing (or C<undef>)

The request proceeds, carrying whatever rewrites the handler made.

=item a hashref

Answered locally; the network is never touched. Keys: C<status> (default 200),
C<headers>, C<body>. C<Content-Length> is B<computed from the body>, not taken
from the handler, so a handler that disagrees with its own body cannot
desynchronise the connection. Useful for mocking an endpoint, or for blocking
with a visible answer:

    return { status => 403, body => 'blocked' } if $req->{host} =~ /ads\./;

=item the string C<'abort'>

The connection is closed without any response -- the closest thing to a
network-level block.

=back

B<What the handler sees in C<headers>> is the set this proxy forces on top of
L<Curl::Impersonate>'s template: what the client sent that must be carried
through (C<Cookie>, C<Referer>, C<Sec-Fetch-*>, C<Content-Type>, ...). It does
B<not> include the headers curl-impersonate supplies from its fingerprint
template (C<User-Agent>, C<Accept>, C<Accept-Language>, C<Sec-CH-UA>, ...) --
forwarding the client's own would break the very fingerprint this proxy exists
to reproduce. Setting any of those keys still works and overrides the template;
you simply cannot read their template values here.

A handler that B<dies> refuses the request with a 502 and warns. It fails closed
deliberately: this hook is used to block traffic, so an exception must not
quietly let through exactly what the caller was trying to stop.

=item on_response => sub { my ($res) = @_; ... }

The counterpart to C<on_request>, called when the upstream response head
arrives -- before any of it reaches the client, so the status and headers can
be observed or rewritten. Stripping a policy header is the usual reason:

    on_response => sub {
        my ($res) = @_;
        delete $res->{headers}{'content-security-policy'};
        delete $res->{headers}{'x-frame-options'};
        return;
    }

C<$res> has C<status>, C<headers> (lowercase-keyed), and -- for context -- the
request's C<url>, C<method> and C<host>. Modify C<status> or C<headers> in
place; the return value is ignored.

B<The framing is not yours.> C<Content-Length>, C<Connection> and the
hop-by-hop headers are snapshotted before the hook and forced back after it: a
handler that edits them does not desynchronise its own connection, it
desynchronises the client's. Setting C<content-length> to a value that
disagrees with the body, or reintroducing C<transfer-encoding>, therefore has
no effect.

Bodies are out of scope: they stream through with backpressure, and buffering
them to offer a rewrite would defeat that. Use C<on_request>'s synthetic
response if you need to replace content wholesale.

A handler that B<dies> passes the response through unchanged and warns. It
fails B<open>, unlike C<on_request>: the request has already been made and the
response already fetched, so there is no security decision left to protect, and
breaking the page over a bug in an observer would be the worse outcome.

=item timeout => $seconds

Per-request upstream timeout. Default 30.

=item verify => $bool

Verify the real origin's certificate upstream. Default true; leave it on.

=item follow_redirects => $bool

Whether the upstream client follows redirects. Default false -- the browser
handles 3xx itself, so the proxy forwards them.

=back

=head2 port

The bound listen port (useful with C<listen =E<gt> '...:0'>).

=head2 cert_dir

The directory holding the self-signed cert.

=head2 run

Run the EV loop. Blocks until L</stop> or C<EV::break>.

=head2 stop

Stop accepting and break the EV loop. Use this when the proxy owns the loop --
i.e. when you called L</run>.

=head2 shutdown

Stop accepting, close every active connection, and release the C<curl_multi>
wiring -- B<without> breaking the EV loop, so a caller whose loop is shared
keeps running. That is the difference from L</stop>: this is the in-process
teardown, and it is what L<EV::WebKit> calls when the browser it fronts quits.

Safe to call more than once, and safe from inside a callback: it is plain
EV/Perl with no GObject-Introspection dispatch to unwind.

=head1 REQUEST HANDLING LIMITS

The proxy refuses what it cannot frame exactly, because guessing would leave
bytes in the read buffer to be re-parsed as a second request:

=over 4

=item * A request head over 64KB is closed, which also caps a slow-drip head.

=item * A transfer-encoded request body gets C<411>: streaming uploads are out
of scope.

=item * A C<Content-Length> that is repeated with disagreeing values, or is not
a plain non-negative integer, gets C<400>. An identical repeat is legal and is
accepted.

=item * A header value containing NUL, CR or LF gets C<400>. RFC 9110 bars all
three from a field value; CR and LF cannot survive the line split, but a NUL
can, and forwarded headers are re-sent upstream.

=back

Request bodies are buffered whole before being forwarded -- there is no
streaming upload path, and therefore no size cap. A client that uploads a
gigabyte makes the proxy hold a gigabyte. That is tolerable because the
listener is bound to localhost by default and fronts one browser, but it is
worth knowing before binding it anywhere else.

=head1 REQUIREMENTS

L<Curl::Impersonate> 0.03 or later, L<Net::SSLeay>, L<EV>.

=head1 SEE ALSO

L<Curl::Impersonate>, L<EV::WebKit>

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
