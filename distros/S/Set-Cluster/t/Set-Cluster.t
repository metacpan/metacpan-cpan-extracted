
use strict;
use Test::More tests => 24;
BEGIN { use_ok('Set::Cluster') };

my $c = Set::Cluster->new;
isa_ok( $c, "Set::Cluster");

my $items = { 
	Oranges => 17, 
	Apples => 3, 
	Lemons => 10, 
	Pears => 12, 
	Strawberries => 15,
	Melons => 10,
	Kiwis => 5,
	Bananas => 12,
	};
my @nodes = qw(A B C);

$c->setup( nodes => [@nodes], items => $items );

my $result = Set::Cluster::Result->new;
isa_ok( $result, "Set::Cluster::Result");
foreach my $n (@nodes) {
	$result->{$n} = [];
}
cmp_ok( $c->lowest($result), 'eq', "A", "Got lowest (ordered by name)");
$result->{A} = ['Lemons'];
$result->{B} = ['Apples'];
cmp_ok( $c->lowest($result), 'eq', "C", "Got lowest (by weight)");

$c->calculate(0);
cmp_ok( scalar keys %{$c->results}, '==', 1, "Got 1 scenario, for just a distribution");

$c->calculate(1);
cmp_ok( scalar keys %{$c->results}, '==', 4, "Got 4 scenarios for a single failure");

my @a = $c->items( node => "A", fail => "B" );
cmp_ok( join(',', sort @a), 'eq', "Lemons,Oranges,Strawberries", "items list okay");

@a = $c->takeover( node => "A", fail => "C" );
cmp_ok( join(",", sort @a), 'eq', "Kiwis,Pears", "takeover list okay");

$c->calculate(2);
cmp_ok( scalar keys %{$c->results}, '==', 10, "Got 10 scenarios for a dual failure");

$c->calculate(3);
cmp_ok( scalar keys %{$c->results}, '==', 10, "Triple failure not possible!");

$c->calculate(30);
cmp_ok( scalar keys %{$c->results}, '==', 10, "30 levels certainly doesn't make sense!");

my $hash = $c->hash_by_item;
cmp_ok( scalar keys %$hash, '==', 8, "8 items in hash");
cmp_ok( $hash->{Strawberries}, "eq", "B", "Strawberries in node B");

$hash = $c->hash_by_item( fail => "B" );
cmp_ok( scalar keys %$hash, "==", 8, "Still 8 items");
cmp_ok( $hash->{Strawberries}, "ne", "B", "Strawberries distributed somewhere else");

# Test with objects as nodes
my $a = Set::Cluster->new;
my $b = Set::Cluster->new;
$c = Set::Cluster->new;
$c->setup( nodes => [($a, $b)], items => $items );
$c->calculate(1);

$hash = $c->hash_by_item;
my $node = $hash->{Strawberries};
isa_ok($node, "Set::Cluster", "Returns back object");

my @items_of_a = sort $c->items( node => $a );
my @takenover_from_a = sort $c->takeover( node => $b, fail => $a );
cmp_ok( join(",", @items_of_a), "eq", join(",", @takenover_from_a), "Items taken over correctly");


{
# Dummy object type
package Test::Set::Cluster::Item;
use strict;
use warnings;
use Class::Struct;
struct "Test::Set::Cluster::Item" => {
	weight => '$',
	};
}

# Test with objects as items
my $x = Test::Set::Cluster::Item->new( weight => 5 );
my $y = Test::Set::Cluster::Item->new( weight => 15 );
my $z = Test::Set::Cluster::Item->new( weight => 12 );

$c = Set::Cluster->new;
$c->setup( nodes => [$a, $b], items => [$x, $y, $z]);
$c->calculate(1);

my @items = $c->items( node => $a );
isa_ok( $items[0], "Test::Set::Cluster::Item", "Returns back object from items");
@items = $c->items( node => $b );
isa_ok( $items[0], "Test::Set::Cluster::Item", "Returns back object from items");
my @takeover = $c->takeover( node => $a, fail => $b );
isa_ok( $takeover[0], "Test::Set::Cluster::Item", "Returns back object from takeover");
$hash = $c->hash_by_item( fail => $b );
isa_ok( $hash->{$y}, "Set::Cluster", "hash_by_item's objects");
cmp_ok( $hash->{$takeover[0]}, "eq", $a, "and is consistent" );


# Test failure if object does not support weight method
$z = Set::Cluster->new;
$c = Set::Cluster->new;
eval '$c->setup( nodes => [$a, $b], items => [$x, $y, $z] )';

isnt( $@, "", "Caught object without weight method");


