# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl OBO_ID_Set.t'

#########################

BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 20;
}

#########################

use OBO::XO::OBO_ID_Set;
use OBO::XO::OBO_ID;
use strict;

my $my_set = OBO::XO::OBO_ID_Set->new();
ok(1);

my $id1 = OBO::XO::OBO_ID->new();
$id1->id_as_string("TO:000001");
$my_set->add($id1);
ok($my_set->contains($id1));

my $id2 = OBO::XO::OBO_ID->new();
$id2->id_as_string("TO:000002");
my $id3 = OBO::XO::OBO_ID->new();
$id3->id_as_string("TO:000003");
my $id4 = OBO::XO::OBO_ID->new();
ok(!$my_set->contains($id4));

$id4->id_as_string("TO:000004");
$my_set->add_all($id1, $id2, $id3, $id4);
ok($my_set->contains($id2) && $my_set->contains($id3) && $my_set->contains($id4));

my $id5_string = "TO:000005";
my $id5 = $my_set->add_as_string($id5_string);
ok($my_set->contains($id5)); 

$my_set->add_as_string($id5_string);
$my_set->add_as_string($id5_string);
$my_set->add_as_string($id5_string);
$my_set->add_as_string($id5_string);
ok($my_set->size() == 5);

my $my_set2 = OBO::XO::OBO_ID_Set->new();
ok(1);

$my_set2->add_all_as_string("TO:000001", "TO:000002", "TO:000003", "TO:000004");
ok(!$my_set->equals($my_set2));
ok($my_set2->size() == 4);

my $id5_2 = $my_set2->add_as_string($id5_string);
ok($my_set2->size() == 5);
ok($my_set->contains($id5_2));
ok($my_set->equals($my_set2));
$my_set->remove($id3);

ok($my_set->contains($id2) && $my_set->contains($id1) && $my_set->contains($id4) && $my_set->contains($id5));
ok($my_set->size() == 4);
$my_set->remove($id5);

ok($my_set->contains($id2) && $my_set->contains($id1) && $my_set->contains($id4));
ok($my_set->size() == 3);
$my_set->clear();
ok(!$my_set->contains($id2) || !$my_set->contains($id1) || !$my_set->contains($id4));

ok($my_set->size() == 0);
ok($my_set->is_empty());

ok(1);
