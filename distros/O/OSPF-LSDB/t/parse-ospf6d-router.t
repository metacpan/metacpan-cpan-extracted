# parse ospf6d router file, compare results and check error handling

use strict;
use warnings;
use List::MoreUtils qw(first_index);
use Test::More tests => 27;

use OSPF::LSDB::ospf6d;
my $ospf = OSPF::LSDB::ospf6d->new();

my @routers = split(/^/m, <<EOF);

                Router Link States (Area 10.188.0.0)

LS age: 908
LS Type: Router
Link State ID: 0.0.0.0
Advertising Router: 10.188.1.10
LS Seq Number: 0x80000059
Checksum: 0x6707
Length: 56
Flags: *|*|*|*|*|-|E|-
Options: *|*|-|R|-|*|E|V6
Number of Links: 2

    Link (Interface ID 0.0.0.1) connected to: Transit Network
    Designated Router ID: 10.188.50.50
    DR Interface ID: 0.0.0.1
    Metric: 10

    Link (Interface ID 0.0.0.6) connected to: Transit Network
    Designated Router ID: 10.188.50.50
    DR Interface ID: 0.0.0.1
    Metric: 10

LS age: 891
LS Type: Router
Link State ID: 0.0.0.0
Advertising Router: 10.188.50.50
LS Seq Number: 0x80000056
Checksum: 0x5b0b
Length: 40
Flags: *|*|*|*|*|-|E|-
Options: *|*|-|R|-|*|E|V6
Number of Links: 1

    Link (Interface ID 0.0.0.1) connected to: Transit Network
    Designated Router ID: 10.188.50.50
    DR Interface ID: 0.0.0.1
    Metric: 10

EOF
$ospf->{router} = [ @routers ];
$ospf->parse_router();
is_deeply($ospf->{ospf}{database}{routers}, [
    {
	age => '908',
	area => '10.188.0.0',
	bits => { B => 0, E => 1, V => 0, W => 0 },
	router => '0.0.0.0',
	routerid => '10.188.1.10',
	sequence => '0x80000059',
	transits => [ {
	    address => '0.0.0.1',
	    interface => '0.0.0.1',
	    routerid => '10.188.50.50',
	    metric => 10,
	}, {
	    address => '0.0.0.1',
	    interface => '0.0.0.6',
	    routerid => '10.188.50.50',
	    metric => 10,
	} ],
    },
    {
	age => '891',
	area => '10.188.0.0',
	bits => { B => 0, E => 1, V => 0, W => 0 },
	router => '0.0.0.0',
	routerid => '10.188.50.50',
	sequence => '0x80000056',
	transits => [ {
	    address => '0.0.0.1',
	    interface => '0.0.0.1',
	    routerid => '10.188.50.50',
	    metric => 10,
	} ],
    },
], "router");

$ospf->{router} = [ @routers ];
foreach (@{$ospf->{router}}) {
    s/^ +Metric: .*/ Router Link States (Area 51.0.0.0)/;
}
eval { $ospf->parse_router() };
ok($@, "error link area not finished") or diag "parse_router did not die";
like($@, qr/51.0.0.0.*\n Link 0.0.0.1\@10.188.50.50 of router 10.188.1.10 in area 10.188.0.0 not finished./, "link area not finished");

$ospf->{router} = [ @routers ];
foreach (@{$ospf->{router}}) {
    s/^ +Link .* connected to: Transit Network.*/ Router Link States (Area 51.0.0.0)/;
}
eval { $ospf->parse_router() };
ok($@, "error router area too few links") or diag "parse_router did not die";
like($@, qr/51.0.0.0.*\n Too few links at router 10.188.1.10 in area 10.188.0.0./, "router area too few links");

$ospf->{router} = [ @routers ];
foreach (@{$ospf->{router}}) {
    s/^Checksum: .*/ Router Link States (Area 51.0.0.0)/;
}
eval { $ospf->parse_router() };
ok($@, "error router area not finished") or diag "parse_router did not die";
like($@, qr/51.0.0.0.*\n Router 10.188.1.10 in area 10.188.0.0 not finished./, " router area not finished");

$ospf->{router} = [ grep {
    ! /^ +Link .* connected to:/
} @routers ];
eval { $ospf->parse_router() };
ok($@, "error link without type") or diag "parse_router did not die";
like($@, qr/Link 0.0.0.1\@10.188.50.50 of router 10.188.1.10 in area 10.188.0.0 without type./, "link without type");

$ospf->{router} = [ grep {
    ! /^ +Router Link States/
} @routers ];
eval { $ospf->parse_router() };
ok($@, "error router undefined area") or diag "parse_router did not die";
like($@, qr/^LS.*\n No area for router defined./, "router undefined area");

$ospf->{router} = [ @routers ];
foreach (@{$ospf->{router}}) {
    s/^Number of Links: 2/Number of Links: 1/;
}
eval { $ospf->parse_router() };
ok($@, "error router too many links") or diag "parse_router did not die";
like($@, qr/    Link.*\n Too many links at router 10.188.1.10 in area 10.188.0.0./, "router too many links");

$ospf->{router} = [ @routers ];
foreach (@{$ospf->{router}}) {
    s/^LS Type: Router/LS Type: foobar/;
}
eval { $ospf->parse_router() };
ok($@, "error router bad type") or diag "parse_router did not die";
like($@, qr/foobar.*\n Type of router-LSA is foobar and not Router in area 10.188.0.0./, "router bad type");

$ospf->{router} = [ @routers ];
foreach (@{$ospf->{router}}) {
    s/^(    Link .* connected to:) Transit Network/$1 foobar/;
}
eval { $ospf->parse_router() };
ok($@, "error link bad type") or diag "parse_router did not die";
like($@, qr/foobar.*\n Unknown link type foobar at router 10.188.1.10 in area 10.188.0.0./, "link bad type");

$ospf->{router} = [ @routers ];
foreach (@{$ospf->{router}}) {
    s/^    Metric:/    Foobar:/
}
eval { $ospf->parse_router() };
ok($@, "error link bad line") or diag "parse_router did not die";
like($@, qr/Foobar.*\n Unknown line at link 0.0.0.1\@10.188.50.50 of router 10.188.1.10 in area 10.188.0.0./, "link bad line");

$ospf->{router} = [ @routers ];
foreach (@{$ospf->{router}}) {
    s/^Length:/Foobar:/
}
eval { $ospf->parse_router() };
ok($@, "error router bad line") or diag "parse_router did not die";
like($@, qr/Foobar.*\n Unknown line at router 10.188.1.10 in area 10.188.0.0./, "router bad line");

$ospf->{router} = [ @routers ];
splice @{$ospf->{router}}, first_index { /^    Metric:/ } @routers;
eval { $ospf->parse_router() };
ok($@, "error link not finished") or diag "parse_router did not die";
like($@, qr/^Link 0.0.0.1\@10.188.50.50 of router 10.188.1.10 in area 10.188.0.0 not finished./, "link not finished");

$ospf->{router} = [ @routers ];
foreach (@{$ospf->{router}}) {
    s/^Number of Links: 1/Number of Links: 2/;
}
eval { $ospf->parse_router() };
ok($@, "error router too few links") or diag "parse_router did not die";
like($@, qr/^Too few links at router 10.188.50.50 in area 10.188.0.0./, "router too few links");

$ospf->{router} = [ @routers ];
splice @{$ospf->{router}}, first_index { /^Checksum: 0x5b0b/ } @routers;
eval { $ospf->parse_router() };
ok($@, "error router not finished") or diag "parse_router did not die";
like($@, qr/^Router 10.188.50.50 in area 10.188.0.0 not finished./, "router not finished");
