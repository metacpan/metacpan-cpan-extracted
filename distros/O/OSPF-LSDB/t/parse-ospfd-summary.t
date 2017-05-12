# parse ospfd summary file, compare results and check error handling

use strict;
use warnings;
use List::MoreUtils qw(first_index);
use Test::More tests => 11;

use OSPF::LSDB::ospfd;
my $ospf = OSPF::LSDB::ospfd->new();

my @summarys = split(/^/m, <<EOF);

                Summary Net Link States (Area 23.0.0.0)

LS age: 536
Options: *|*|-|-|-|-|E|*
LS Type: Summary (Network)
Link State ID: 172.19.5.0 (Network ID)
Advertising Router: 172.16.0.47
LS Seq Number: 0x80000323
Checksum: 0x76f9
Length: 28
Network Mask: 255.255.255.0
Metric: 23

EOF
$ospf->{summary} = [ @summarys ];
$ospf->parse_summary();
is_deeply($ospf->{ospf}{database}{summarys}, [ {
    address => '172.19.5.0',
    age => '536',
    area => '23.0.0.0',
    metric => 23,
    netmask => '255.255.255.0',
    routerid => '172.16.0.47',
    sequence => '0x80000323',
} ], "summary");

$ospf->{summary} = [ @summarys ];
foreach (@{$ospf->{summary}}) {
    s/^Checksum: .*/ Summary Net Link States (Area 51.0.0.0)/;
}
eval { $ospf->parse_summary() };
ok($@, "error summary area not finished") or diag "parse_summary did not die";
like($@, qr/51.0.0.0.*\n Summary 172.19.5.0 in area 23.0.0.0 not finished./, "summary area not finished");

$ospf->{summary} = [ grep {
    ! /^ +Summary Net Link States/
} @summarys ];
eval { $ospf->parse_summary() };
ok($@, "error summary undefined area") or diag "parse_summary did not die";
like($@, qr/^LS.*\n No area for summary defined./, "summary undefined area");

$ospf->{summary} = [ @summarys ];
foreach (@{$ospf->{summary}}) {
    s/^LS Type: Summary \(Network\)/LS Type: foobar/;
}
eval { $ospf->parse_summary() };
ok($@, "error summary bad type") or diag "parse_summary did not die";
like($@, qr/foobar.*\n Type of summary-LSA is foobar and not Summary \(Network\) in area 23.0.0.0./, "summary bad type");

$ospf->{summary} = [ @summarys ];
foreach (@{$ospf->{summary}}) {
    s/^Length:/Foobar:/
}
eval { $ospf->parse_summary() };
ok($@, "error summary bad line") or diag "parse_summary did not die";
like($@, qr/Foobar.*\n Unknown line at summary 172.19.5.0 in area 23.0.0.0./, "summary bad line");

$ospf->{summary} = [ @summarys ];
splice @{$ospf->{summary}}, first_index { /^Checksum:/ } @summarys;
eval { $ospf->parse_summary() };
ok($@, "error summary not finished") or diag "parse_summary did not die";
like($@, qr/^Summary 172.19.5.0 in area 23.0.0.0 not finished./, "summary not finished");
