# parse ospf6d external file, compare results and check error handling

use strict;
use warnings;
use List::MoreUtils qw(first_index);
use Test::More tests => 11;

use OSPF::LSDB::ospf6d;
my $ospf = OSPF::LSDB::ospf6d->new();

my @externals = split(/^/m, <<EOF);

                Type-5 AS External Link States

LS age: 1378
LS Type: AS External
Link State ID: 0.0.0.1
Advertising Router: 10.188.50.50
LS Seq Number: 0x80000051
Checksum: 0x9bc8
Length: 28
    Flags: *|*|*|*|*|-|-|-
    Metric: 60 Type: 1
    Prefix: ::/0

EOF
$ospf->{external} = [ @externals ];
$ospf->parse_external();
is_deeply($ospf->{ospf}{database}{externals}, [ {
    address => '0.0.0.1',
    age => '1378',
    metric => 60,
    prefixaddress => '::',
    prefixlength => '0',
    routerid => '10.188.50.50',
    sequence => '0x80000051',
    type => 1,
} ], "external");

$ospf->{external} = [ @externals, " Type-5 AS External Link States\n" ];
eval { $ospf->parse_external() };
ok($@, "error externals too many") or diag "parse_external did not die";
like($@, qr/Type-5 AS External.*\n Too many external sections./, "externals too many");

$ospf->{external} = [ @externals ];
foreach (@{$ospf->{external}}) {
    s/^Checksum: .*/ Type-5 AS External Link States/,
}
eval { $ospf->parse_external() };
ok($@, "error external many not finished") or diag "parse_external did not die";
like($@, qr/Type-5 AS External.*\n External 0.0.0.1\@10.188.50.50 not finished./, "external many not finished");

$ospf->{external} = [ @externals ];
foreach (@{$ospf->{external}}) {
    s/^LS Type: AS External/LS Type: foobar/;
}
eval { $ospf->parse_external() };
ok($@, "error external bad type") or diag "parse_external did not die";
like($@, qr/foobar.*\n Type of external-LSA is foobar and not AS External./, "external bad type");

$ospf->{external} = [ @externals ];
foreach (@{$ospf->{external}}) {
    s/^Length:/Foobar:/
}
eval { $ospf->parse_external() };
ok($@, "error external bad line") or diag "parse_external did not die";
like($@, qr/Foobar.*\n Unknown line at external 0.0.0.1\@10.188.50.50./, "external bad line");

$ospf->{external} = [ @externals ];
splice @{$ospf->{external}}, first_index { /^Checksum:/ } @externals;
eval { $ospf->parse_external() };
ok($@, "error external not finished") or diag "parse_external did not die";
like($@, qr/^External 0.0.0.1\@10.188.50.50 not finished./, "external not finished");
