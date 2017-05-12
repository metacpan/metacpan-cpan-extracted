#!/usr/bin/perl -wT

use strict;

use Test::More tests => 28;

# Use
use_ok('Net::BGP::NLRI');
use Net::BGP::NLRI qw( :origin );

# Construction
my $empty = new Net::BGP::NLRI;
ok(ref $empty eq 'Net::BGP::NLRI','Simple construction');
my $data = new Net::BGP::NLRI(
	Aggregator	=>	[ 65020, '10.0.0.10' ],
	AtomicAggregate	=>	1,
	AsPath		=>	'65002 65010 65020 {65030,65050}',
	Communities	=>	[ '65002:10','65002:200' ],
	LocalPref	=>	10,
	MED		=>	42,
	Nexthop		=>	'10.0.0.9',
	Origin		=>	EGP,
	);
ok(ref $data eq 'Net::BGP::NLRI','Complex construction');

# Copying
my $clone1 = clone Net::BGP::NLRI($data);
ok(ref $clone1 eq 'Net::BGP::NLRI','Clone construction');
my $clone = $clone1->clone;
ok(ref $clone eq 'Net::BGP::NLRI','Cloning');

# Aggregator
ok($clone->aggregator->[0] == 65020,'Accessor: Aggregator AS');
ok($clone->aggregator->[1] eq '10.0.0.10','Accessor: Aggregator IP');
$clone->aggregator([65000,'127.0.0.1']);
ok($clone->aggregator->[0] == 65000,'Accessor: Aggregator modifyer');

# Atomic aggregate
ok($clone->atomic_aggregate,'Accessor: Atomic aggregate');
$clone->atomic_aggregate(0);
ok(! $clone->atomic_aggregate,'Accessor: Atomic aggregate modifyer');

# AS Path
ok($clone->as_path->asstring eq '65002 65010 65020 {65030,65050}','Accessor: AS Path');
$clone->as_path->prepend(65000);
ok($clone->as_path->asstring eq '65000 65002 65010 65020 {65030,65050}','Accessor: AS Path reference');
$clone->as_path('(65001) 65002');
ok($clone->as_path->asstring eq '(65001) 65002','Accessor: AS Path modifyer');

# Communities
ok($clone->communities->[0] eq '65002:10','Accessor: Communities');
$clone->communities->[0] = '65002:20';
ok($clone->communities->[0] eq '65002:20','Accessor: Communities reference');
$clone->communities(['65002:42']);
ok($clone->communities->[0] eq '65002:42','Accessor: Communities modifyer');

# LocalPref
ok($clone->local_pref == 10,'Accessor: Local Preference');
$clone->local_pref(20);
ok($clone->local_pref == 20,'Accessor: Local Preference modifyer');

# MED
ok($clone->med == 42,'Accessor: Multi Exit Discriminator');
$clone->med(20);
ok($clone->med == 20,'Accessor: Multi Exit Discriminator modifyer');

# Nexthop
ok($clone->next_hop eq '10.0.0.9','Accessor: Nexthop');
$clone->next_hop('10.0.0.42');
ok($clone->next_hop eq '10.0.0.42','Accessor: Nexthop modifyer');

# Preference comparison
ok($data > $clone,'Preference: Greater then (>)');
ok($clone < $data,'Preference: Less then (<)');
ok($clone1 == $data,'Preference: Equal (==)');
ok($clone != $data,'Preference: Not equal (!=)');

# Comparison
ok($clone1 eq $data,'Comparison: Equal (eq)');
ok($clone ne $data,'Comparison: Not equal (ne)');

__END__
