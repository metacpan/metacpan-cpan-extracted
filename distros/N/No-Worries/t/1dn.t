#!perl

use strict;
use warnings;
use Test::More tests => 16;

use No::Worries::DN qw(dn_parse dn_string);

our(%DN, $dn, $format, $string);

$DN{No::Worries::DN::FORMAT_RFC2253()} = "CN=John Doe,O=Acme Corporation,C=US";
$DN{No::Worries::DN::FORMAT_JAVA()}    = "CN=John Doe, O=Acme Corporation, C=US";
$DN{No::Worries::DN::FORMAT_OPENSSL()} = "/C=US/O=Acme Corporation/CN=John Doe";

foreach $format (keys(%DN)) {
    $dn = dn_parse($DN{$format});
    ok($dn, "dn_parse($DN{$format})");
    $string = dn_string($dn, $format);
    is($DN{$format}, $string, "dn_string($DN{$format}, $format)");
}

# more complex valid DNs
foreach $string (
    "/O=grid/O=users/O=somewhere/CN=Peter Doe",
    "/DC=ch/DC=cern/OU=Organic Units/OU=Users/CN=admin/CN=159427/CN=Robot: FOOBAR Admin/Email=foobar-admin\@cern.ch",
    "C=AT, O=AustrianGrid, OU=OEAWX, OU=oeawx-vienna, CN=host/wlcg321.oeawx.ac.at",
    "CN=host/wlcg123.sinp.msu.ru, OU=sinp.msu.ru, OU=hosts, O=RDIG, C=RU",
    "emailAddress=foo.support\@rl.ac.uk, CN=lnx123.pp.rl.ac.uk, L=RAL, OU=CLRC, O=eScience, C=UK",
) {
    $@ = "";
    eval { dn_parse($string) };
    is($@, "", "dn_parse($string) -> success");
}

# invalid DNs
foreach $string (
    "",
    "/abc=123",
    "C=IT/O=Vatican/OU=Host/L=Roma/CN=lx123.roma.it",
) {
    $@ = "";
    eval { dn_parse($string) };
    ok($@, "dn_parse($string) -> error");
}

# API errors
$@ = "";
eval { dn_parse([ 1, 2 ]) };
ok($@, "dn_parse([]) -> error");
$@ = "";
eval { dn_string("foo", "x") };
ok($@, "dn_string(foo, x) -> error");
