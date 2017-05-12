# parse ospfd external file, compare results and check error handling

use strict;
use warnings;
use List::MoreUtils qw(first_index);
use Test::More tests => 11;

use OSPF::LSDB::ospfd;
my $ospf = OSPF::LSDB::ospfd->new();

my @externals = split(/^/m, <<EOF);

                Type-5 AS External Link States

LS age: 1162
Options: *|*|-|-|-|-|-|*
LS Type: AS External
Link State ID: 0.0.0.0 (External Network Number)
Advertising Router: 10.188.2.254
LS Seq Number: 0x80000032
Checksum: 0xbe39
Length: 36
Network Mask: 0.0.0.0
    Metric type: 1
    Metric: 100
    Forwarding Address: 0.0.0.0
    External Route Tag: 0

EOF
$ospf->{external} = [ @externals ];
$ospf->parse_external();
is_deeply($ospf->{ospf}{database}{externals}, [ {
    address => '0.0.0.0',
    age => '1162',
    forward => '0.0.0.0',
    metric => 100,
    netmask => '0.0.0.0',
    routerid => '10.188.2.254',
    sequence => '0x80000032',
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
like($@, qr/Type-5 AS External.*\n External 0.0.0.0 not finished./, "external many not finished");

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
like($@, qr/Foobar.*\n Unknown line at external 0.0.0.0./, "external bad line");

$ospf->{external} = [ @externals ];
splice @{$ospf->{external}}, first_index { /^Checksum:/ } @externals;
eval { $ospf->parse_external() };
ok($@, "error external not finished") or diag "parse_external did not die";
like($@, qr/^External 0.0.0.0 not finished./, "external not finished");
