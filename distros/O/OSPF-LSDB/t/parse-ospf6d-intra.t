# parse ospf6d intra file, compare results and check error handling

use strict;
use warnings;
use List::MoreUtils qw(first_index);
use Test::More tests => 24;

use OSPF::LSDB::ospf6d;
my $ospf = OSPF::LSDB::ospf6d->new();

my @intras = split(/^/m, <<EOF);

                Intra Area Prefix Link States (Area 10.188.0.0)

LS age: 1177
LS Type: Intra Area (Prefix)
Link State ID: 1.0.0.0
Advertising Router: 10.188.0.16
LS Seq Number: 0x80000008
Checksum: 0xeea0
Length: 72
Referenced LS Type: Router
Referenced Link State ID: 0.0.0.0
Referenced Advertising Router: 10.188.0.16
Number of Prefixes: 2
    Prefix: fdd7:e83e:66bc:0:a00:20ff:fece:a11c/128 Options: *|*|*|-|-|x|LA|-
    Prefix: 2a01:198:24d:0:a00:20ff:fece:a11c/128 Options: *|*|*|-|-|x|LA|-

LS age: 1173
LS Type: Intra Area (Prefix)
Link State ID: 0.0.0.1
Advertising Router: 10.188.0.254
LS Seq Number: 0x80000008
Checksum: 0xa209
Length: 56
Referenced LS Type: Network
Referenced Link State ID: 0.0.0.1
Referenced Advertising Router: 10.188.0.254
Number of Prefixes: 2
    Prefix: 2a01:198:24d:2::/64
    Prefix: fdd7:e83e:66bc:2::/64

LS age: 3600
LS Type: Intra Area (Prefix)
Link State ID: 0.0.0.3
Advertising Router: 10.188.0.254
LS Seq Number: 0x80000001
Checksum: 0x077a
Length: 32
Referenced LS Type: Network
Referenced Link State ID: 0.0.0.3
Referenced Advertising Router: 10.188.0.254
Number of Prefixes: 0

LS age: 1173
LS Type: Intra Area (Prefix)
Link State ID: 1.0.0.0
Advertising Router: 10.188.0.254
LS Seq Number: 0x80000914
Checksum: 0x947b
Length: 72
Referenced LS Type: Router
Referenced Link State ID: 0.0.0.0
Referenced Advertising Router: 10.188.0.254
Number of Prefixes: 2
    Prefix: fdd7:e83e:66bc:0:2d0:b7ff:fe09:ed7b/128 Options: *|*|*|-|-|x|LA|-
    Prefix: 2a01:198:24d:0:2d0:b7ff:fe09:ed7b/128 Options: *|*|*|-|-|x|LA|-

EOF
$ospf->{intra} = [ @intras ];
$ospf->parse_intra();
is_deeply($ospf->{ospf}{database}{intrarouters}, [
    {
	address => '1.0.0.0',
	age => '1177',
	area => '10.188.0.0',
	interface => '0.0.0.0',
	router => '10.188.0.16',
	routerid => '10.188.0.16',
	sequence => '0x80000008',
	prefixes => [ {
	    prefixaddress   => 'fdd7:e83e:66bc:0:a00:20ff:fece:a11c',
	    prefixlength    => 128,
	}, {
	    prefixaddress   => '2a01:198:24d:0:a00:20ff:fece:a11c',
	    prefixlength    => 128,
	} ],
    },
    {
	address => '1.0.0.0',
	age => '1173',
	area => '10.188.0.0',
	interface => '0.0.0.0',
	router => '10.188.0.254',
	routerid => '10.188.0.254',
	sequence => '0x80000914',
	prefixes => [ {
	    prefixaddress   => 'fdd7:e83e:66bc:0:2d0:b7ff:fe09:ed7b',
	    prefixlength    => 128,
	}, {
	    prefixaddress   => '2a01:198:24d:0:2d0:b7ff:fe09:ed7b',
	    prefixlength    => 128,
	} ],
    },
], "intrarouter");
is_deeply($ospf->{ospf}{database}{intranetworks}, [
    {
	address => '0.0.0.1',
	age => '1173',
	area => '10.188.0.0',
	interface => '0.0.0.1',
	router => '10.188.0.254',
	routerid => '10.188.0.254',
	sequence => '0x80000008',
	prefixes => [ {
	    prefixaddress   => '2a01:198:24d:2::',
	    prefixlength    => 64,
	}, {
	    prefixaddress   => 'fdd7:e83e:66bc:2::',
	    prefixlength    => 64,
	} ],
    },
    {
	address => '0.0.0.3',
	age => '3600',
	area => '10.188.0.0',
	interface => '0.0.0.3',
	router => '10.188.0.254',
	routerid => '10.188.0.254',
	sequence => '0x80000001',
    },
], "intrarouter");

$ospf->{intra} = [ @intras ];
foreach (@{$ospf->{intra}}) {
    s/^ +Prefix: 2a01:198:24d:0:a00:20ff:fece:a11c\/128.*/ Intra Area Prefix Link States (Area 51.0.0.0)/;
}
eval { $ospf->parse_intra() };
ok($@, "error intra area not finished") or diag "parse_intra did not die";
like($@, qr/51.0.0.0.*\n Prefixes of intra-area-prefix 1.0.0.0\@10.188.0.16 in area 10.188.0.0 not finished./, " prefix area not finished");

$ospf->{intra} = [ @intras ];
foreach (@{$ospf->{intra}}) {
    s/^Checksum: .*/ Intra Area Prefix Link States (Area 51.0.0.0)/;
}
eval { $ospf->parse_intra() };
ok($@, "error intra area not finished") or diag "parse_intra did not die";
like($@, qr/51.0.0.0.*\n Intra-area-prefix 1.0.0.0\@10.188.0.16 in area 10.188.0.0 not finished./, " intra area not finished");

$ospf->{intra} = [ @intras ];
foreach (@{$ospf->{intra}}) {
    s/^Number of Prefixes: 2/Number of Prefixes: 3/;
}
eval { $ospf->parse_intra() };
ok($@, "error intra area too few prefixes") or diag "parse_intra did not die";
like($@, qr/\n Too few prefixes at intra-area-prefix 1.0.0.0\@10.188.0.16 in area 10.188.0.0./, "intra area too few prefixes");

$ospf->{intra} = [ @intras ];
foreach (@{$ospf->{intra}}) {
    s/^Referenced LS Type: Router//;
}
eval { $ospf->parse_intra() };
ok($@, "error intra no type") or diag "parse_intra did not die";
like($@, qr/\n Intra-area-prefix 1.0.0.0\@10.188.0.16 in area 10.188.0.0 has no referenced LS type./, "intra bad type");

$ospf->{intra} = [ grep {
    ! /^ +Intra Area Prefix Link States/
} @intras ];
eval { $ospf->parse_intra() };
ok($@, "error intra undefined area") or diag "parse_intra did not die";
like($@, qr/^LS.*\n No area for intra-area-prefix defined./, "intra undefined area");

$ospf->{intra} = [ @intras ];
foreach (@{$ospf->{intra}}) {
    s/^LS Type: Intra Area \(Prefix\)/LS Type: foobar/;
}
eval { $ospf->parse_intra() };
ok($@, "error intra bad type") or diag "parse_intra did not die";
like($@, qr/foobar.*\n Type of intra-area-prefix-LSA is foobar and not Intra Area \(Prefix\) in area 10.188.0.0./, "intra bad type");

$ospf->{intra} = [ @intras ];
foreach (@{$ospf->{intra}}) {
    s/^Referenced Link State ID: .*/Referenced LS Type: foobar/;
}
eval { $ospf->parse_intra() };
ok($@, "error intra multiple referenced type") or diag "parse_intra did not die";
like($@, qr/Referenced LS Type: foobar\n Referenced LS type given more than once at intra-area-prefix 1.0.0.0\@10.188.0.16 in area 10.188.0.0./, "intra multiple referenced type");

$ospf->{intra} = [ @intras ];
foreach (@{$ospf->{intra}}) {
    s/^Referenced LS Type: Router/Referenced LS Type: foobar/;
}
eval { $ospf->parse_intra() };
ok($@, "error intra bad referenced type") or diag "parse_intra did not die";
like($@, qr/Referenced LS Type: foobar\n Unknown referenced LS type foobar at intra-area-prefix 1.0.0.0\@10.188.0.16 in area 10.188.0.0./, "intra bad referenced type");

$ospf->{intra} = [ @intras ];
foreach (@{$ospf->{intra}}) {
    s/^Length:/Foobar:/
}
eval { $ospf->parse_intra() };
ok($@, "error intra bad line") or diag "parse_intra did not die";
like($@, qr/Foobar.*\n Unknown line at intra-area-prefix 1.0.0.0\@10.188.0.16 in area 10.188.0.0./, "intra bad line");

$ospf->{intra} = [ @intras ];
splice @{$ospf->{intra}}, first_index { /^    Prefix: 2a01:198:24d:0:2d0:b7ff:fe09:ed7b\/128/ } @intras;
eval { $ospf->parse_intra() };
ok($@, "error prefix not finished") or diag "parse_intra did not die";
like($@, qr/^Prefixes of intra-area-prefix 1.0.0.0\@10.188.0.254 in area 10.188.0.0 not finished./, "prefix not finished");

$ospf->{intra} = [ @intras ];
splice @{$ospf->{intra}}, first_index { /^Checksum: 0x947b/ } @intras;
eval { $ospf->parse_intra() };
ok($@, "error intra not finished") or diag "parse_intra did not die";
like($@, qr/^Intra-area-prefix 1.0.0.0\@10.188.0.254 in area 10.188.0.0 not finished./, "intra not finished");
