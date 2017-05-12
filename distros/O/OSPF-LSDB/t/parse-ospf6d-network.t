# parse ospf6d network file, compare results and check error handling

use strict;
use warnings;
use List::MoreUtils qw(first_index);
use Test::More tests => 17;

use OSPF::LSDB::ospf6d;
my $ospf = OSPF::LSDB::ospf6d->new();

my @networks = split(/^/m, <<EOF);

                Net Link States (Area 10.188.0.0)

LS age: 951
LS Type: Network
Link State ID: 0.0.0.1 (Interface ID of Designated Router)
Advertising Router: 10.188.50.50
LS Seq Number: 0x80000006
Checksum: 0x7b7f
Length: 32
Options: *|*|-|R|-|*|E|V6
Number of Routers: 2
    Attached Router: 10.188.1.10
    Attached Router: 10.188.50.50

EOF
$ospf->{network} = [ @networks ];
$ospf->parse_network();
is_deeply($ospf->{ospf}{database}{networks}, [ {
    address => '0.0.0.1',
    age => '951',
    area => '10.188.0.0',
    attachments => [
	{
	    routerid => '10.188.1.10',
	}, {
	    routerid => '10.188.50.50',
	}
    ],
    routerid => '10.188.50.50',
    sequence => '0x80000006',
} ], "network");

$ospf->{network} = [ @networks ];
foreach (@{$ospf->{network}}) {
    s/^    Attached Router: 10.188.50.50.*/ Net Link States (Area 51.0.0.0)/;
}
eval { $ospf->parse_network() };
ok($@, "error routers area not finished") or diag "parse_network did not die";
like($@, qr/51.0.0.0.*\n Attached routers of network 0.0.0.1\@10.188.50.50 in area 10.188.0.0 not finished./, "routers area not finished");

$ospf->{network} = [ @networks ];
foreach (@{$ospf->{network}}) {
    s/^Checksum: .*/ Net Link States (Area 51.0.0.0)/;
}
eval { $ospf->parse_network() };
ok($@, "error network area not finished") or diag "parse_network did not die";
like($@, qr/51.0.0.0.*\n Network 0.0.0.1\@10.188.50.50 in area 10.188.0.0 not finished./, "network area not finished");

$ospf->{network} = [ @networks ];
foreach (@{$ospf->{network}}) {
    s/^Number of Routers: 2/Number of Routers: 3/
}
eval { $ospf->parse_network() };
ok($@, "error network area too few routers") or diag "parse_network did not die";
like($@, qr/\n Too few attached routers at network 0.0.0.1\@10.188.50.50 in area 10.188.0.0./, "network area too few routers");

$ospf->{network} = [ grep {
    ! /^ +Net Link States/
} @networks ];
eval { $ospf->parse_network() };
ok($@, "error network undefined area") or diag "parse_network did not die";
like($@, qr/^LS.*\n No area for network defined./, "network undefined area");

$ospf->{network} = [ @networks ];
foreach (@{$ospf->{network}}) {
    s/^LS Type: Network/LS Type: foobar/;
}
eval { $ospf->parse_network() };
ok($@, "error network bad type") or diag "parse_network did not die";
like($@, qr/foobar.*\n Type of network-LSA is foobar and not Network in area 10.188.0.0./, "network bad type");

$ospf->{network} = [ @networks ];
foreach (@{$ospf->{network}}) {
    s/^Length:/Foobar:/
}
eval { $ospf->parse_network() };
ok($@, "error network bad line") or diag "parse_network did not die";
like($@, qr/Foobar.*\n Unknown line at network 0.0.0.1\@10.188.50.50 in area 10.188.0.0./, "network bad line");

$ospf->{network} = [ @networks ];
splice @{$ospf->{network}}, first_index { /^    Attached Router: 10.188.50.50/ } @networks;
eval { $ospf->parse_network() };
ok($@, "error routers not finished") or diag "parse_network did not die";
like($@, qr/^Attached routers of network 0.0.0.1\@10.188.50.50 in area 10.188.0.0 not finished./, "routers not finished");

$ospf->{network} = [ @networks ];
splice @{$ospf->{network}}, first_index { /^Checksum:/ } @networks;
eval { $ospf->parse_network() };
ok($@, "error network not finished") or diag "parse_network did not die";
like($@, qr/^Network 0.0.0.1\@10.188.50.50 in area 10.188.0.0 not finished./, "network not finished");
