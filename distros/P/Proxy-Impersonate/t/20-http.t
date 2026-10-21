use v5.10; use strict; use warnings;
use Test::More;
use Proxy::Impersonate::HTTP qw(parse_request_head body_length coherent_headers response_head);

# incomplete head -> undef
is(parse_request_head("GET / HTTP/1.1\r\nHost: x"), undef, 'incomplete head is undef');

my $raw = "POST /p?q=1 HTTP/1.1\r\nHost: ex.com\r\nContent-Length: 5\r\n"
        . "Cookie: a=b\r\nUser-Agent: WebKit\r\n\r\nhello";
my $r = parse_request_head($raw);
is($r->{method}, 'POST', 'method parsed');
is($r->{target}, '/p?q=1', 'target parsed');
is($r->{version}, 'HTTP/1.1', 'version parsed');
is(substr($raw, $r->{header_end}), 'hello', 'header_end points at the body');

# header order + case preserved
is_deeply($r->{headers}[0], ['Host', 'ex.com'], 'first header pair preserves case');

my ($mode, $n) = body_length($r->{headers});
is($mode, 'length', 'content-length framing');
is($n, 5, 'content length is 5');

my ($cmode) = body_length([['Transfer-Encoding','chunked']]);
is($cmode, 'chunked', 'chunked framing detected');

my ($nmode) = body_length([['Host','x']]);
is($nmode, 'none', 'no body framing');

my $fwd = coherent_headers($r->{headers});
is($fwd->{cookie}, 'a=b', 'cookie forwarded (lower-cased)');
ok(!exists $fwd->{'user-agent'}, 'user-agent dropped (impersonate template wins)');
ok(!exists $fwd->{host}, 'host dropped (curl sets it from the URL)');

my $head = response_head(200, { 'content-type' => 'text/html', 'x-a' => '1' });
like($head, qr!\AHTTP/1\.1 200 OK\r\n!, 'status line with reason');
like($head, qr/content-type: text\/html\r\n/, 'header line present');
like($head, qr/\r\n\r\n\z/, 'ends with the blank line');
is(response_head(502, {}), "HTTP/1.1 502 Bad Gateway\r\n\r\n", '502 with no headers');

# coherence: forward WebKit's real per-request Sec-Fetch/Accept metadata.
# The 2nd coherent_headers arg is the "chrome target" flag (Accept synthesis).
{
    my $sub = coherent_headers([
        ['Host','ex.com'], ['Cookie','a=b'],
        ['Sec-Fetch-Site','same-origin'], ['Sec-Fetch-Mode','cors'], ['Sec-Fetch-Dest','empty'],
        ['Accept','*/*'], ['User-Agent','WebKit'],
    ], 1);
    is($sub->{'sec-fetch-mode'}, 'cors', 'Sec-Fetch-Mode forwarded (not curl navigate)');
    is($sub->{'sec-fetch-dest'}, 'empty', 'Sec-Fetch-Dest forwarded');
    is($sub->{accept}, '*/*', 'Accept synthesized for empty dest (*/*)');
    ok(!defined $sub->{'sec-fetch-user'}, 'Sec-Fetch-User marked for removal on a subresource');
    ok(exists $sub->{'sec-fetch-user'}, '...as an explicit undef (curl "Header:" removal)');
    ok(!defined $sub->{'upgrade-insecure-requests'}, 'UIR marked for removal on a subresource');
    ok(!exists $sub->{'user-agent'}, 'User-Agent still dropped (identity via override_headers)');
}
# a Chrome navigation: Sec-Fetch-User forwarded (WebKit sent it), UIR SYNTHESIZED
# (WebKit never sends it, but real Chrome sends it on every navigation), Chrome Accept
{
    my $nav = coherent_headers([
        ['Sec-Fetch-Mode','navigate'], ['Sec-Fetch-Dest','document'],
        ['Sec-Fetch-User','?1'],
        ['Accept','text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'],  # WebKit/Safari flavor
    ], 1);
    is($nav->{'sec-fetch-user'}, '?1', 'Sec-Fetch-User forwarded on a navigation');
    is($nav->{'upgrade-insecure-requests'}, '1', 'UIR synthesized on a Chrome navigation (WebKit never sends it)');
    like($nav->{accept}, qr/image\/avif.*application\/signed-exchange/,
         'document Accept synthesized to Chrome (not the forwarded Safari value)');
    unlike($nav->{accept}, qr/^text\/html,application\/xhtml\+xml,application\/xml;q=0\.9,\*\/\*/,
           'the Safari-flavored WebKit Accept is NOT forwarded verbatim');
}
# image destination -> Chrome image Accept (chrome target)
{
    my $img = coherent_headers([['Sec-Fetch-Dest','image']], 1);
    like($img->{accept}, qr{^image/avif,image/webp,image/apng}, 'image dest -> Chrome image Accept');
}
# an iframe/frame navigation uses the SAME Accept as a top-level document (Chrome)
{
    my $ifr = coherent_headers([['Sec-Fetch-Dest','iframe'], ['Accept','*/*']], 1);
    like($ifr->{accept}, qr/image\/avif.*application\/signed-exchange/,
         'iframe dest -> Chrome document Accept (not the */* it carried)');
    my $frm = coherent_headers([['Sec-Fetch-Dest','frame']], 1);
    like($frm->{accept}, qr/image\/avif.*application\/signed-exchange/,
         'frame dest -> Chrome document Accept');
}
# an unmapped dest carrying an app-set Accept forwards it (EventSource, fetch)
# instead of flattening to */*, which Chrome also sends and a strict endpoint needs
{
    my $sse = coherent_headers([['Sec-Fetch-Dest','empty'], ['Accept','text/event-stream']], 1);
    is($sse->{accept}, 'text/event-stream', 'empty dest keeps an app-set Accept (EventSource)');
    my $json = coherent_headers([['Sec-Fetch-Dest','empty'], ['Accept','application/json']], 1);
    is($json->{accept}, 'application/json', 'empty dest keeps an app-set Accept (fetch JSON)');
    my $bare = coherent_headers([['Sec-Fetch-Dest','empty']], 1);
    is($bare->{accept}, '*/*', 'empty dest with no request Accept -> */*');
}
# a SAFARI target (chrome flag false) forwards WebKit's OWN per-dest Accept and does
# NOT synthesize Chrome's -- a Chrome Accept next to a Safari JA4/UA is the tell.
{
    my $safari_accept = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8';
    my $doc = coherent_headers([['Sec-Fetch-Dest','document'], ['Accept',$safari_accept]], 0);
    is($doc->{accept}, $safari_accept, 'safari target forwards WebKit document Accept verbatim');
    unlike($doc->{accept}, qr/signed-exchange|image\/avif/,
           'safari target does NOT inject Chrome-only Accept tokens (avif/signed-exchange)');
    my $img = coherent_headers([['Sec-Fetch-Dest','image'], ['Accept','image/png,image/svg+xml,*/*;q=0.8']], 0);
    is($img->{accept}, 'image/png,image/svg+xml,*/*;q=0.8', 'safari target forwards WebKit image Accept (not Chrome image Accept)');
    ok(!defined $doc->{'upgrade-insecure-requests'}, 'a Safari navigation gets NO Upgrade-Insecure-Requests');
}
# Upgrade-Insecure-Requests: synthesized only for a Chrome navigation (Chrome sends
# it on every navigation; nothing on subresources; Safari sends it never)
{
    is(coherent_headers([['Sec-Fetch-Dest','document']], 1)->{'upgrade-insecure-requests'}, '1',
       'Chrome document navigation -> UIR 1 (synthesized)');
    is(coherent_headers([['Sec-Fetch-Dest','iframe']], 1)->{'upgrade-insecure-requests'}, '1',
       'Chrome iframe navigation -> UIR 1');
    ok(!defined coherent_headers([['Sec-Fetch-Dest','image']], 1)->{'upgrade-insecure-requests'},
       'Chrome subresource (image) -> no UIR');
    ok(!defined coherent_headers([['Sec-Fetch-Dest','empty']], 1)->{'upgrade-insecure-requests'},
       'Chrome fetch/xhr (empty) -> no UIR');
    ok(!defined coherent_headers([['Sec-Fetch-Dest','document']], 0)->{'upgrade-insecure-requests'},
       'Safari document navigation -> no UIR');
}
# Accept-Language is NOT forwarded (supplied as an identity header in Chrome format)
{
    my $al = coherent_headers([['Accept-Language','en-us, en;q=0.9'], ['Sec-Fetch-Dest','document']], 1);
    ok(!exists $al->{'accept-language'}, 'Accept-Language not forwarded (identity supplies Chrome format)');
}
# response_head emits one line per value for a repeated header
{
    my $rh = response_head(200, { 'set-cookie' => ['a=1','b=2'], 'content-type' => 'text/html' });
    my @sc = $rh =~ /set-cookie: (\S+)/g;
    is_deeply(\@sc, ['a=1','b=2'], 'multiple Set-Cookie lines emitted');
}
# response_head strips control chars (response-splitting guard)
{
    my $rh = response_head(200, { 'x-evil' => "ok\r\nInjected: 1" });
    unlike($rh, qr/\r\nInjected:/, 'CRLF in an upstream header value cannot split the response');
}

# RFC 7230 3.3.3: a Content-Length that is repeated with disagreeing values, or
# is not a plain non-negative integer, leaves the body unframeable. Guessing a
# length would strand the remainder in the read buffer to be re-parsed as a
# SECOND request -- the request-smuggling primitive -- so it is refused instead.
{
    my $head = sub { "POST / HTTP/1.1\r\nHost: x\r\n" . $_[0] . "\r\n\r\nAAAAA" };
    my @bad = (
        ['repeated and disagreeing' => "Content-Length: 5\r\nContent-Length: 10"],
        ['comma list disagreeing'   => 'Content-Length: 5, 10'],
        ['not a number'             => 'Content-Length: +5'],
        ['negative'                 => 'Content-Length: -1'],
    );
    for my $c (@bad) {
        my ($what, $hdr) = @$c;
        my $r = parse_request_head($head->($hdr));
        my ($mode) = body_length($r->{headers});
        is($mode, 'invalid', "$what Content-Length is refused");
    }
    # An identical repeat is legal and must still frame.
    my $r = parse_request_head($head->("Content-Length: 5\r\nContent-Length: 5"));
    my ($mode, $len) = body_length($r->{headers});
    is($mode, 'length', 'an identical repeat still frames');
    is($len, 5, '...with the right length');
}


for my $line ('Content-Length : 5', ' Content-Length: 5', 'broken',
              "X-Test: a\0b", "X-Test: a\nb") {
    ok(!parse_request_head("POST / HTTP/1.1\r\n$line\r\n\r\n"),
       'malformed header is refused');
}
{
    my $r = parse_request_head("GET / HTTP/1.1\r\nX-A: \t value \t\r\nX-B:\t \r\nX-C: x\r\n\r\n");
    is_deeply($r->{headers}, [['X-A', 'value'], ['X-B', ''], ['X-C', 'x']],
        'field parsing trims optional whitespace and retains empty and single-byte values');
}
is((body_length([['Transfer-Encoding', 'gzip']]))[0], 'chunked',
   'all transfer codings require a decoder');
is((body_length([['Content-Length', '5,']]))[0], 'invalid',
   'empty length in a comma list is refused');

{
    my $h = coherent_headers([
        ['X-CSRF-Token', 'token'], ['Range', 'bytes=100-'], ['If-None-Match', '"tag"'],
        ['Cache-Control', 'no-cache'], ['Connection', 'x-private'], ['X-Private', 'secret'],
        ['Proxy-Authorization', 'secret'], ['Sec-CH-UA-Arch', 'wrong'],
    ], 1);
    is($h->{'x-csrf-token'}, 'token', 'application headers survive');
    is($h->{range}, 'bytes=100-', 'range survives');
    is($h->{'accept-encoding'}, 'identity', 'range offsets refer to uncompressed bytes');
    is($h->{'if-none-match'}, '"tag"', 'cache validator survives');
    is($h->{'cache-control'}, 'no-cache', 'cache policy survives');
    ok(!exists $h->{'x-private'} && !exists $h->{'proxy-authorization'},
       'hop headers and proxy credentials stay local');
    ok(!exists $h->{'sec-ch-ua-arch'}, 'client hints come from the configured identity');
}

done_testing;
