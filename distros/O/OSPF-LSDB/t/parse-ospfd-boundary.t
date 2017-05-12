# parse ospfd boundary file, compare results and check error handling

use strict;
use warnings;
use List::MoreUtils qw(first_index);
use Test::More tests => 11;

use OSPF::LSDB::ospfd;
my $ospf = OSPF::LSDB::ospfd->new();

my @boundarys = split(/^/m, <<EOF);

                Summary Router Link States (Area 23.0.0.0)

LS age: 1103
Options: *|*|-|-|-|-|E|*
LS Type: Summary (Router)
Link State ID: 172.30.5.5 (ASBR Router ID)
Advertising Router: 172.16.0.47
LS Seq Number: 0x80000189
Checksum: 0x7294
Length: 28
Network Mask: 0.0.0.0
Metric: 11

EOF
$ospf->{boundary} = [ @boundarys ];
$ospf->parse_boundary();
is_deeply($ospf->{ospf}{database}{boundarys}, [ {
    age => '1103',
    area => '23.0.0.0',
    asbrouter => '172.30.5.5',
    metric => 11,
    routerid => '172.16.0.47',
    sequence => '0x80000189',
} ], "boundary");

$ospf->{boundary} = [ @boundarys ];
foreach (@{$ospf->{boundary}}) {
    s/^Checksum: .*/ Summary Router Link States (Area 51.0.0.0)/;
}
eval { $ospf->parse_boundary() };
ok($@, "error boundary area not finished") or diag "parse_boundary did not die";
like($@, qr/51.0.0.0.*\n Boundary 172.30.5.5 in area 23.0.0.0 not finished./, "boundary area not finished");

$ospf->{boundary} = [ grep {
    ! /^ +Summary Router Link States/
} @boundarys ];
eval { $ospf->parse_boundary() };
ok($@, "error boundary undefined area") or diag "parse_boundary did not die";
like($@, qr/^LS.*\n No area for boundary defined./, "boundary undefined area");

$ospf->{boundary} = [ @boundarys ];
foreach (@{$ospf->{boundary}}) {
    s/^LS Type: Summary \(Router\)/LS Type: foobar/;
}
eval { $ospf->parse_boundary() };
ok($@, "error boundary bad type") or diag "parse_boundary did not die";
like($@, qr/foobar.*\n Type of boundary-LSA is foobar and not Summary \(Router\) in area 23.0.0.0./, "boundary bad type");

$ospf->{boundary} = [ @boundarys ];
foreach (@{$ospf->{boundary}}) {
    s/^Length:/Foobar:/
}
eval { $ospf->parse_boundary() };
ok($@, "error boundary bad line") or diag "parse_boundary did not die";
like($@, qr/Foobar.*\n Unknown line at boundary 172.30.5.5 in area 23.0.0.0./, "boundary bad line");

$ospf->{boundary} = [ @boundarys ];
splice @{$ospf->{boundary}}, first_index { /^Checksum:/ } @boundarys;
eval { $ospf->parse_boundary() };
ok($@, "error boundary not finished") or diag "parse_boundary did not die";
like($@, qr/^Boundary 172.30.5.5 in area 23.0.0.0 not finished./, "boundary not finished");
