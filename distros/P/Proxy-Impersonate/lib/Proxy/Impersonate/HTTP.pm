package Proxy::Impersonate::HTTP;
use v5.10; use strict; use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(parse_request_head body_length coherent_headers response_head strip_hop_headers);

my %REASON = (
    200=>'OK', 201=>'Created', 204=>'No Content', 205=>'Reset Content',
    301=>'Moved Permanently', 302=>'Found', 303=>'See Other',
    304=>'Not Modified', 307=>'Temporary Redirect', 308=>'Permanent Redirect',
    400=>'Bad Request', 401=>'Unauthorized', 403=>'Forbidden', 404=>'Not Found',
    411=>'Length Required', 417=>'Expectation Failed',
    500=>'Internal Server Error', 502=>'Bad Gateway', 503=>'Service Unavailable',
    504=>'Gateway Timeout',
);

# Forward WebKit's real per-request headers so the origin sees a coherent request
# CONTEXT, not curl-impersonate's static navigation defaults. curl's template
# hard-codes Sec-Fetch-Mode: navigate / Sec-Fetch-Dest: document / Accept:
# text/html on EVERY request, which makes every subresource (image/script/XHR)
# look like a top-level document load -- a glaring tell. WebKit computes correct
# per-request Sec-Fetch-* + Accept, so forwarding them (they override the template
# in place) fixes it. The User-Agent/Sec-CH-UA identity headers are supplied
# separately via override_headers.
my %HOP = map { $_ => 1 } qw(
    connection keep-alive proxy-connection proxy-authenticate proxy-authorization
    te trailer transfer-encoding upgrade
);
my %DROP = (%HOP, map { $_ => 1 } qw(
    host content-length expect user-agent accept accept-language accept-encoding
    upgrade-insecure-requests priority http2-settings
));

sub strip_hop_headers {
    my ($h) = @_;
    if (my $conn = $h->{connection}) {
        delete @{$h}{map { split /\s*,\s*/, lc $_ }
                         (ref $conn eq 'ARRAY' ? @$conn : $conn)};
    }
    delete @{$h}{keys %HOP};
    return $h;
}
# Accept-Language is NOT forwarded: WebKit/libsoup may render the profile
# languages in a non-Chrome format (comma-space, lower-cased region), a tell next
# to a Chrome JA4. It is supplied as an identity header (override_headers) in the
# exact Chrome format instead -- see EV::WebKit::Fingerprint::identity_headers.
# Headers a real browser sends only on a USER-ACTIVATED navigation: if WebKit did
# not send one, strip curl's template default (undef => "Header:") so a subresource
# (or an automated navigation) does not carry e.g. Sec-Fetch-User: ?1. NB
# Upgrade-Insecure-Requests is NOT here -- it is not user-gated (Chrome sends it on
# every navigation) and WebKit never emits it, so it is synthesized per target +
# destination in coherent_headers, not merely stripped.
my %CONDITIONAL = map { $_ => 1 } qw(sec-fetch-user);
# Chrome's per-destination Accept for the browser-FLAVORED destinations. NOT
# forwarded from WebKit for these (whose Accept is Safari-flavored -- a Chrome/JA4
# request with a Safari Accept is a tell) and NOT left as curl's static document
# default (wrong for subresources). Synthesized from Sec-Fetch-Dest so the value
# is Chrome's AND matches the request context. A frame navigation (iframe/frame)
# uses the same Accept as a top-level document.
my $DOC_ACCEPT = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7';
my %CHROME_ACCEPT = (
    document => $DOC_ACCEPT,
    iframe   => $DOC_ACCEPT,
    frame    => $DOC_ACCEPT,
    image    => 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
    style    => 'text/css,*/*;q=0.1',
);

# Parse an HTTP/1.x request head. Returns undef if the head is incomplete
# (no CRLFCRLF yet), else a hashref. headers is an ordered arrayref of [k,v]
# pairs, preserving case and order as received.
sub parse_request_head {
    my ($buf) = @_;
    my $end = index($buf, "\r\n\r\n");
    return undef if $end < 0;
    my $head = substr($buf, 0, $end);
    my ($line, @lines) = split /\r\n/, $head;
    return undef unless defined $line;
    my ($method, $target, $version) = $line =~ m{\A([!#\x24%&'*+.^_`|~0-9A-Za-z-]+) +([^\x00-\x20\x7f]+) +(HTTP/1\.[01])\z}
        or return undef;
    my @pairs;
    for my $h (@lines) {
        my ($k, $v) = $h =~ /\A([!#\x24%&'*+.^_`|~0-9A-Za-z-]+):[ \t]*([^\0\r\n]*[^ \t\0\r\n]|)[ \t]*\z/
            or return undef;
        push @pairs, [$k, $v];
    }
    return {
        method => $method, target => $target, version => $version,
        headers => \@pairs, header_end => $end + 4,
    };
}

sub _get {
    my ($pairs, $name) = @_;
    $name = lc $name;
    for (@$pairs) { return $_->[1] if lc($_->[0]) eq $name }
    return undef;
}

# How the request/response body is framed. Returns ('chunked') or
# ('length', $n) or ('none').
sub body_length {
    my ($pairs) = @_;
    my $te = _get($pairs, 'transfer-encoding');
    return (length($te) ? 'chunked' : 'invalid') if defined $te;
    my @cl = map { $_->[1] } grep { lc($_->[0]) eq 'content-length' } @$pairs;
    if (@cl) {
        # RFC 7230 3.3.3: repeated (or comma-listed) values must all agree, and
        # the value must be a plain non-negative integer. Anything else leaves
        # the body unframeable -- and taking a guess would leave the remainder
        # in the buffer to be re-parsed as a SECOND request, which is exactly
        # the request-smuggling primitive. Refuse instead.
        my %v = map { $_ => 1 } map { split /\s*,\s*/, $_, -1 } @cl;
        my @vals = keys %v;
        return ('invalid') if @vals != 1 || $vals[0] !~ /^\d+$/;
        return ('length', $vals[0] + 0);
    }
    return ('none');
}

# The request headers to forward upstream, lower-cased. A value of undef means
# "remove this header from the impersonate template".
sub coherent_headers {
    my ($pairs, $chrome) = @_;
    my (%out, %seen, $dest, $req_accept, @connection);
    for (@$pairs) {
        my $k = lc $_->[0];
        $dest       = $_->[1] if $k eq 'sec-fetch-dest';
        $req_accept = $_->[1] if $k eq 'accept';
        push @connection, split /\s*,\s*/, lc $_->[1] if $k eq 'connection';
        next if $DROP{$k} || index($k, 'sec-ch-') == 0;
        $out{$k} = $_->[1];
        $seen{$k} = 1 if $CONDITIONAL{$k};
    }
    $out{$_} = undef for grep { !$seen{$_} } keys %CONDITIONAL;
    # Upgrade-Insecure-Requests: real Chrome sends "1" on every navigation
    # (document/iframe/frame) and nothing on a subresource; Safari sends it on
    # neither; WebKit emits it never. So strip curl's static template UIR by default
    # and synthesize "1" only for a Chrome-target navigation (below).
    $out{'upgrade-insecure-requests'} = undef;
    # Accept, target-family-aware. For a CHROME target WebKit's own Accept is
    # Safari-flavored (a tell next to a Chrome JA4), so synthesize Chrome's per-
    # destination value (%CHROME_ACCEPT); for an unmapped dest that carried an
    # app-set Accept (EventSource text/event-stream, fetch application/json --
    # browser-agnostic, which Chrome also sends) forward it rather than flattening
    # to */*; else */*. For a SAFARI target WebKit IS WebKit, so its own per-
    # request Accept is already the right family AND per-destination -> forward it
    # unchanged (synthesizing Chrome's here would be the same tell, reversed).
    # Only acts when the request carried Sec-Fetch-Dest (a real WebKit request);
    # otherwise curl's template Accept stands.
    if (defined $dest) {
        my $d = lc $dest;
        $out{'upgrade-insecure-requests'} = '1'
            if $chrome && ($d eq 'document' || $d eq 'iframe' || $d eq 'frame');
        if ($chrome) {
            $out{accept} = exists $CHROME_ACCEPT{$d} ? $CHROME_ACCEPT{$d}
                         : defined $req_accept        ? $req_accept
                         :                              '*/*';
        }
        elsif (defined $req_accept) { $out{accept} = $req_accept }
        else                        { $out{accept} = '*/*' }   # symmetry: never leak curl's template Accept
    }
    delete @out{@connection} if @connection;
    $out{'accept-encoding'} = 'identity' if exists $out{range};
    return \%out;
}

# Serialise a response status line + headers + terminating blank line. A header
# whose value is an arrayref (a repeated header, e.g. Set-Cookie) emits one line
# per value. Control chars in names/values are stripped (response-splitting guard).
sub response_head {
    my ($status, $headers) = @_;
    my $reason = $REASON{$status} // 'Status';
    my $out = "HTTP/1.1 $status $reason\r\n";
    for my $k (sort keys %$headers) {
        my $v = $headers->{$k};
        next unless defined $v;
        (my $ck = $k) =~ tr/\r\n\0//d;
        for my $val (ref $v eq 'ARRAY' ? @$v : $v) {
            next unless defined $val;
            (my $cv = $val) =~ tr/\r\n\0//d;
            $out .= "$ck: $cv\r\n";
        }
    }
    $out .= "\r\n";
    return $out;
}

1;

__END__

=head1 NAME

Proxy::Impersonate::HTTP - request/response head parsing for the proxy

=head1 DESCRIPTION

The small HTTP codec L<Proxy::Impersonate::Connection> runs on: parse a request
head, work out how the body is delimited, decide which client headers may be
forwarded on top of the impersonation template, and format a response head.
Nothing here is exported by default and you do not normally touch it directly.

C<coherent_headers> is the interesting one: it drops the headers
C<libcurl-impersonate> supplies from its own fingerprint template
(C<User-Agent>, C<Accept>, C<Accept-Language>, C<Sec-CH-UA>, ...) and keeps only
what the client sent that must be carried through -- C<Cookie>, C<Referer>,
C<Sec-Fetch-*> and friends. Forwarding the client's own template headers would
break the very fingerprint this proxy exists to reproduce, which is also why an
C<on_request> handler sees the kept set rather than the whole request.

=cut
