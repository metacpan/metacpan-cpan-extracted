# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl TermSet.t'

#########################

BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 36;
}

#########################

use OBO::Util::RelationshipTypeSet;
use OBO::Core::RelationshipType;

# new set
my $my_set = OBO::Util::RelationshipTypeSet->new();
ok(1);
ok($my_set->is_empty() == 1);

my @arr = $my_set->get_set();
ok($#{@arr} == -1);

# three new terms
my $r1 = OBO::Core::RelationshipType->new();
my $r2 = OBO::Core::RelationshipType->new();
my $r3 = OBO::Core::RelationshipType->new();

$r1->id("REL:0000001");
$r2->id("REL:0000002");
$r3->id("REL:0000003");

$r1->name("is a");
$r2->name("part of");
$r3->name("participates in");

# remove from my_set
my $rcode = $my_set->remove($r1);
ok($rcode == 0);
ok($my_set->size() == 0);
ok(!$my_set->contains($r1));
$my_set->add($r1);
ok($my_set->contains($r1));
$rcode = $my_set->remove($r1);
ok($rcode == 1);
ok($my_set->size() == 0);
ok(!$my_set->contains($r1));

$my_set->add($r1);
ok($my_set->contains($r1));
$my_set->add($r2);
ok($my_set->contains($r2));
$my_set->add($r3);
ok($my_set->contains($r3));

ok($my_set->size() == 3);
my $r3_idem = OBO::Core::RelationshipType->new();
$r3_idem->id("REL:0000003");
$r3_idem->name("participates in");
$my_set->add($r3_idem);
ok($my_set->contains($r3_idem));
ok($my_set->size() == 3);

$my_set->add($r3_idem);
$my_set->add($r3_idem);
$my_set->add($r3_idem);
$my_set->add($r3_idem);
$my_set->add($r3_idem);
ok($my_set->size() == 3);

my $r4 = OBO::Core::RelationshipType->new();
my $r5 = OBO::Core::RelationshipType->new();
my $r6 = OBO::Core::RelationshipType->new();

$r4->id("REL:0000004");
$r5->id("REL:0000005");
$r6->id("REL:0000006");

$r4->name("Four");
$r5->name("Five");
$r6->name("Six");

$my_set->add_all($r4, $r5, $r6);
ok($my_set->contains($r4) && $my_set->contains($r5) && $my_set->contains($r6));
ok($my_set->contains_id("REL:0000006"));
ok(!$my_set->contains_id("REL:0000007"));
ok($my_set->contains_name('Six'));
ok(!$my_set->contains_name('Seven'));

$my_set->add_all($r4, $r5, $r6);
ok($my_set->size() == 6);

# remove from my_set
$rcode = $my_set->remove($r4);
ok($rcode == 1);
ok($my_set->size() == 5);
ok(!$my_set->contains($r4));

my $r7 = $r4;
my $r8 = $r5;
my $r9 = $r6;

my $my_set2 = OBO::Util::RelationshipTypeSet->new();
ok(1);

ok($my_set2->is_empty());
ok(!$my_set->equals($my_set2));

$my_set->add_all($r4, $r5, $r6);
$my_set2->add_all($r7, $r8, $r9, $r1, $r2, $r3);
ok(!$my_set2->is_empty());
ok($my_set->contains($r7) && $my_set->contains($r8) && $my_set->contains($r9));
ok($my_set->equals($my_set2));

ok($my_set2->size() == 6);

$my_set2->clear();
ok($my_set2->is_empty());
ok($my_set2->size() == 0);

ok(1);