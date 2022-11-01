#!perl
#
# gemini URI tests. see also RFC 3986

use Test2::V0;
plan 34;

use Net::Gemini::URI;

for my $ref (
    [ undef,                  qr/URI undefined/,           'undef' ],
    [ 'http://example.org',   qr/URI unknown/,             'http' ],
    [ 'gemini://',            qr/authority is required/,   'noauth' ],
    [ 'gemini://user@[::1]',  qr/userinfo is not allowed/, 'user' ],
    [ 'gemini://_,-',         qr/unknown authority/,       'unkauth' ],
    [ 'gemini://[::1]:0',     qr/port is out of range/,    'lowport' ],
    [ 'gemini://[::1]:65536', qr/port is out of range/,    'highport' ],
) {
    my ( $u, $err ) = Net::Gemini::URI->new( $ref->[0] );
    is( $u, undef, $ref->[2] );
    like( $err, $ref->[1], $ref->[2] );
}

# RFC 3986 section 6.2.3 -- empty path should be normalized to a path of "/"
my ( $u, $err ) = Net::Gemini::URI->new('gemini://example.org');
is( $err,             undef );
is( $u,               'gemini://example.org/' );
is( $u->host,         'example.org' );
is( $u->port,         1965 );
is( [ $u->hostport ], [ 'example.org', 1965 ] );
is( $u->path,         '/' );
is( $u->query,        undef );
is( $u->fragment,     undef );

is( $u->host('example.com'), 'example.com' );
is( $u->port(999),           999 );
is( $u->path('/foo/bar'),    '/foo/bar' );
is( $u->query('foo=bar'),    'foo=bar' );
is( $u->fragment('foobar'),  'foobar' );
is( $u, 'gemini://example.com:999/foo/bar?foo=bar#foobar' );

# another section 6.2.3 thing, "normalization should not remove
# delimiters when their associated component is empty" so these are only
# left off when undef
$u->query('');
$u->fragment('');
is( $u, 'gemini://example.com:999/foo/bar?#' );

# can we dog food the ?# thing
is( ( Net::Gemini::URI->new($u) )[0], 'gemini://example.com:999/foo/bar?#' );

# do IPv6 address get [] added around them in the output?
is( ( Net::Gemini::URI->new('gemini://[::1]/') )[0], 'gemini://[::1]/' );

# also exercise the IPv4 code path
is( ( Net::Gemini::URI->new('gemini://127.0.0.1/') )[0],
    'gemini://127.0.0.1/' );

# illegal in gemini but should be allowed by the module (the length
# check happens, hopefully, over in Net::Gemini). also! the "authority"
# section is limited to 63 characters per hostname bit so a simple
# 'gemini://' . 'a' x 1024 *obviously* will not work
( $u, $err ) = Net::Gemini::URI->new( 'gemini://example.org/' . 'a' x 1004 );
is( $err,       undef );
is( length($u), 1025 );
