#!/usr/local/bin/perl
##----------------------------------------------------------------------------
## Regexp patterns from RFC 3986 - t/01_rfc3986.t
## Test suite for Regexp::Common::URI::RFC3986
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More;

use Regexp::Common::URI::RFC3986 qw /:ALL/;

# Module loads and exports the expected variables
my @expected_vars = qw(
    $digit $upalpha $lowalpha $alpha $alphanum $hex $hexdig $escaped $pct_encoded
    $mark $unreserved $sub_delims $reserved $pchar $uric $urics $userinfo
    $userinfo_no_colon $uric_no_slash $query $fragment $param $segment $segment_nz
    $segment_nz_nc $path_abempty $path_absolute $path_noscheme $path_rootless
    $path_empty $path_segments $ftp_segments $rel_segment $abs_path $rel_path $path
    $port $dec_octet $IPv4address $hextet $ls32 $IPv6address $IPvFuture $IP_literal
    $toplabel $domainlabel $hostname $host $hostport $server $reg_name $authority
    $scheme $net_path $opaque_part $hier_part $relative_part $relativeURI $absoluteURI
    $relative_ref $URI_reference $IDN_DOT $ACE $IDN_U_LABEL $IDN_HOST
);

plan tests => 162;

# Export presence
foreach my $var ( @expected_vars )
{
    ( my $name = $var ) =~ s/^\$//;
    no strict 'refs';
    ok( defined( ${ "Regexp::Common::URI::RFC3986::$name" } ), "exported: \$$name" );
}

# Helper: build anchored regex from a string fragment
sub re { qr/^(?:$_[0])$/ }

# NOTE: $dec_octet / $IPv4address
foreach my $good ( qw( 0 9 99 100 199 200 249 250 255 ) )
{
    like( $good, re( $dec_octet ), "dec_octet PASS: $good" );
}

unlike( '256', re( $dec_octet ), 'dec_octet FAIL: 256' );

foreach my $good ( qw( 0.0.0.0 127.0.0.1 192.168.1.1 255.255.255.255 ) )
{
    like( $good, re( $IPv4address ), "IPv4address PASS: $good" );
}

foreach my $bad ( qw( 256.0.0.1 1.2.3 1.2.3.4.5 ) )
{
    unlike( $bad, re( $IPv4address ), "IPv4address FAIL: $bad" );
}

# NOTE: $IPv6address
my @good_ipv6 = (
    '2001:db8::1',
    '::1',
    '::',
    'fe80::1',
    '2001:db8:85a3::8a2e:370:7334',
    '::ffff:192.0.2.1',        # IPv4-mapped
    '2001:db8::',
    '0:0:0:0:0:0:0:1',
    '0:0:0:0:0:0:192.168.0.1', # ls32 = IPv4
);

foreach my $addr ( @good_ipv6 )
{
    like( $addr, re( $IPv6address ), "IPv6address PASS: $addr" );
}

unlike( 'gg::1',        re( $IPv6address ), 'IPv6address FAIL: gg::1'                    );
unlike( '2001:db8:::1', re( $IPv6address ), 'IPv6address FAIL: 2001:db8:::1'             );
unlike( '12345::1',     re( $IPv6address ), 'IPv6address FAIL: 12345::1 (5-char hextet)' );

# NOTE: $IPvFuture / $IP_literal
foreach my $good ( 'v7.fe80', 'vF.a-b~', 'v1.:', 'vAB.unreserved+ok' )
{
    like( $good, re( $IPvFuture ), "IPvFuture PASS: $good" );
}

foreach my $bad ( 'vZ.abc', 'v1.' )
{
    unlike( $bad, re( $IPvFuture ), "IPvFuture FAIL: $bad" );
}

like( '[2001:db8::1]',  re( $IP_literal ), 'IP_literal PASS: [2001:db8::1]'    );
like( '[::1]',          re( $IP_literal ), 'IP_literal PASS: [::1]'            );
like( '[v7.fe80]',      re( $IP_literal ), 'IP_literal PASS: [v7.fe80]'        );
unlike( '2001:db8::1',  re( $IP_literal ), 'IP_literal FAIL: missing brackets' );
unlike( '[2001:db8::1', re( $IP_literal ), 'IP_literal FAIL: missing ]'        );
unlike( '[]',           re( $IP_literal ), 'IP_literal FAIL: empty []'         );

# NOTE: $reg_name / $host
foreach my $good ( '', 'example.com', 'xn--nxasmq6b.jp', '%41%42' )
{
    like( $good, re( $reg_name ), "reg_name PASS: '$good'" );
}

unlike( 'exam ple', re( $reg_name ), 'reg_name FAIL: space in name' );
unlike( 'exam<ple', re( $reg_name ), 'reg_name FAIL: < in name'     );

# host accepts IP-literal, IPv4, or reg-name
like( '[::1]',       re( $host ), 'host PASS: IPv6 literal'          );
like( '127.0.0.1',   re( $host ), 'host PASS: IPv4'                  );
like( 'example.com', re( $host ), 'host PASS: reg-name'              );
like( '',            re( $host ), 'host PASS: empty (reg-name is *)' );

# NOTE: $userinfo / $authority
foreach my $good ( '', 'user', 'user:pass', 'user%40name' )
{
    like( $good, re( $userinfo ), "userinfo PASS: '$good'" );
}

like( 'user@example.com',       re( $authority ), 'authority PASS: user@host'         );
like( 'example.com:8080',       re( $authority ), 'authority PASS: host:port'         );
like( 'user:pw@example.com:80', re( $authority ), 'authority PASS: full authority'    );
unlike( 'user name@host',       re( $authority ), 'authority FAIL: space in userinfo' );

# NOTE: $scheme
foreach my $good ( qw( http https ftp svn+ssh coap+tcp ) )
{
    like( $good, re( $scheme ), "scheme PASS: $good" );
}

foreach my $bad ( qw( 1http -bad .bad ) )
{
    unlike( $bad, re( $scheme ), "scheme FAIL: $bad" );
}

# NOTE: Path productions
like( '/foo/bar',   re( $path_abempty ),  'path_abempty PASS: /foo/bar'      );
like( '',           re( $path_abempty ),  'path_abempty PASS: empty'         );
like( '/foo',       re( $path_absolute ), 'path_absolute PASS: /foo'         );
like( 'foo/bar',    re( $path_rootless ), 'path_rootless PASS: foo/bar'      );
like( 'foo',        re( $path_noscheme ), 'path_noscheme PASS: foo'          );
like( '',           re( $path_empty ),    'path_empty PASS: empty string'    );
unlike( 'foo/bar',  re( $path_absolute ), 'path_absolute FAIL: no leading /' );
unlike( '',         re( $path_rootless ), 'path_rootless FAIL: empty'        );

# NOTE: $query / $fragment
foreach my $good ( '', 'key=value', 'a=1&b=2', '%3E%FF', 'path/like?query' )
{
    like( $good, re( $query ), "query PASS: '$good'" );
}

unlike( 'qu#ry', re( $query ),    'query FAIL: # in query'         );
unlike( '#frag', re( $fragment ), 'fragment FAIL: leading #'       );
like(   'frag',  re( $fragment ), 'fragment PASS: simple fragment' );

# NOTE: $URI_reference (integration)
my @good_uris = (
    'http://example.com',
    'https://user:pw@example.com:8080/path?q=1#frag',
    'ftp://ftp.example.org/pub/file.tar.gz',
    '//example.com/path',
    '/absolute/path',
    'relative/path',
    '',
);

foreach my $uri ( @good_uris )
{
    like( $uri, re( $URI_reference ), "URI_reference PASS: '$uri'" );
}

unlike( "http://exa mple.com", re( $URI_reference ), 'URI_reference FAIL: space in host' );

# NOTE: IDN helpers
like( 'example',      re( $IDN_U_LABEL ), 'IDN_U_LABEL PASS: ASCII label'    );
like( 'münchen',      re( $IDN_U_LABEL ), 'IDN_U_LABEL PASS: Unicode label'  );
like( 'xn--nxasmq6b', re( $IDN_U_LABEL ), 'IDN_U_LABEL PASS: ACE label'      );
unlike( '-bad',       re( $IDN_U_LABEL ), 'IDN_U_LABEL FAIL: leading hyphen' );
like( 'example.com',  re( $IDN_HOST ),    'IDN_HOST PASS: ASCII domain'      );
like( 'münchen.de',   re( $IDN_HOST ),    'IDN_HOST PASS: Unicode domain'    );

done_testing;

__END__
