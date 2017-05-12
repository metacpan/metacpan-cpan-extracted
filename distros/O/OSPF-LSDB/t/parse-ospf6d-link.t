# parse ospf6d link file, compare results and check error handling

use strict;
use warnings;
use List::MoreUtils qw(first_index);
use Test::More tests => 17;

use OSPF::LSDB::ospf6d;
my $ospf = OSPF::LSDB::ospf6d->new();

my @links = split(/^/m, <<EOF);

                Link (Type-8) Link States (Area 10.188.0.0 Interface hme0)

LS age: 1205
LS Type: Link
Link State ID: 0.0.0.1 (Interface ID of Advertising Router)
Advertising Router: 10.188.0.16
LS Seq Number: 0x80000022
Checksum: 0x6f94
Length: 44
Options: *|*|-|R|-|*|E|V6
Link Local Address: fe80::a00:20ff:fece:a11c
Number of Prefixes: 0

LS age: 389
LS Type: Link
Link State ID: 0.0.0.3 (Interface ID of Advertising Router)
Advertising Router: 10.188.0.254
LS Seq Number: 0x800008f1
Checksum: 0x8a98
Length: 44
Options: *|*|-|R|-|*|E|V6
Link Local Address: fe80::230:64ff:fe02:13b
Number of Prefixes: 0


                Link (Type-8) Link States (Area 10.188.0.0 Interface em0)

LS age: 1205
LS Type: Link
Link State ID: 0.0.0.3 (Interface ID of Advertising Router)
Advertising Router: 10.188.0.16
LS Seq Number: 0x80000022
Checksum: 0xcd38
Length: 44
Options: *|*|-|R|-|*|E|V6
Link Local Address: fe80::204:23ff:fede:c7e2
Number of Prefixes: 0

LS age: 389
LS Type: Link
Link State ID: 0.0.0.1 (Interface ID of Advertising Router)
Advertising Router: 10.188.0.254
LS Seq Number: 0x80000919
Checksum: 0x0f1d
Length: 68
Options: *|*|-|R|-|*|E|V6
Link Local Address: fe80::230:64ff:fe02:139
Number of Prefixes: 2
    Prefix: fdd7:e83e:66bc:2::/64
    Prefix: 2a01:198:24d:2::/64

EOF
$ospf->{link} = [ @links ];
$ospf->parse_link();
is_deeply($ospf->{ospf}{database}{links}, [
    {
	age => '1205',
	area => '10.188.0.0',
	interface => '0.0.0.1',
	linklocal => 'fe80::a00:20ff:fece:a11c',
	routerid => '10.188.0.16',
	sequence => '0x80000022',
    },
    {
	age => '389',
	area => '10.188.0.0',
	interface => '0.0.0.3',
	linklocal => 'fe80::230:64ff:fe02:13b',
	routerid => '10.188.0.254',
	sequence => '0x800008f1',
    },
    {
	age => '1205',
	area => '10.188.0.0',
	interface => '0.0.0.3',
	linklocal => 'fe80::204:23ff:fede:c7e2',
	routerid => '10.188.0.16',
	sequence => '0x80000022',
    },
    {
	age => '389',
	area => '10.188.0.0',
	interface => '0.0.0.1',
	linklocal => 'fe80::230:64ff:fe02:139',
	routerid => '10.188.0.254',
	sequence => '0x80000919',
	prefixes => [ {
	    prefixaddress   => 'fdd7:e83e:66bc:2::',
	    prefixlength    => 64,
	}, {
	    prefixaddress   => '2a01:198:24d:2::',
	    prefixlength    => 64,
	} ],
    },
], "linkrouter");

$ospf->{link} = [ @links ];
foreach (@{$ospf->{link}}) {
    s/^ +Prefix: 2a01:198:24d:2::\/64.*/ Link (Type-8) Link States (Area 51.0.0.0 Interface foo0)/
}
eval { $ospf->parse_link() };
ok($@, "error link area not finished") or diag "parse_link did not die";
like($@, qr/51.0.0.0.*\n Prefixes of link 0.0.0.1\@10.188.0.254 in area 10.188.0.0 not finished./, " prefix area not finished");

$ospf->{link} = [ @links ];
foreach (@{$ospf->{link}}) {
    s/^Checksum: .*/ Link (Type-8) Link States (Area 51.0.0.0 Interface foo0)/
}
eval { $ospf->parse_link() };
ok($@, "error link area not finished") or diag "parse_link did not die";
like($@, qr/51.0.0.0.*\n Link 0.0.0.1\@10.188.0.16 in area 10.188.0.0 not finished./, " link area not finished");

$ospf->{link} = [ @links ];
foreach (@{$ospf->{link}}) {
    s/^Number of Prefixes: 2/Number of Prefixes: 3/;
}
eval { $ospf->parse_link() };
ok($@, "error link area too few prefixes") or diag "parse_link did not die";
like($@, qr/\n Too few prefixes at link 0.0.0.1\@10.188.0.254 in area 10.188.0.0./, "link area too few prefixes");

$ospf->{link} = [ grep {
    ! /^ +Link \(Type-8\) Link States/
} @links ];
eval { $ospf->parse_link() };
ok($@, "error link undefined area") or diag "parse_link did not die";
like($@, qr/^LS.*\n No area for link defined./, "link undefined area");

$ospf->{link} = [ @links ];
foreach (@{$ospf->{link}}) {
    s/^LS Type: Link/LS Type: foobar/;
}
eval { $ospf->parse_link() };
ok($@, "error link bad type") or diag "parse_link did not die";
like($@, qr/foobar.*\n Type of link-LSA is foobar and not Link in area 10.188.0.0./, "link bad type");

$ospf->{link} = [ @links ];
foreach (@{$ospf->{link}}) {
    s/^Length:/Foobar:/
}
eval { $ospf->parse_link() };
ok($@, "error link bad line") or diag "parse_link did not die";
like($@, qr/Foobar.*\n Unknown line at link 0.0.0.1\@10.188.0.16 in area 10.188.0.0./, "link bad line");

$ospf->{link} = [ @links ];
splice @{$ospf->{link}}, first_index { /^    2a01:198:24d:2::\/64/ } @links;
eval { $ospf->parse_link() };
ok($@, "error prefix not finished") or diag "parse_link did not die";
like($@, qr/^Prefixes of link 0.0.0.1\@10.188.0.254 in area 10.188.0.0 not finished./, "prefix not finished");

$ospf->{link} = [ @links ];
splice @{$ospf->{link}}, first_index { /^Checksum: 0x0f1d/ } @links;
eval { $ospf->parse_link() };
ok($@, "error link not finished") or diag "parse_link did not die";
like($@, qr/^Link 0.0.0.1\@10.188.0.254 in area 10.188.0.0 not finished./, "link not finished");
