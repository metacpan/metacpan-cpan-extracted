# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl InstanceSet.t'

#########################

BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 36;
}

#########################

use OBO::Util::InstanceSet;
use OBO::Core::Instance;

# new set
my $my_set = OBO::Util::InstanceSet->new();
ok(1);
ok($my_set->is_empty() == 1);

my @arr = $my_set->get_set();
ok($#{@arr} == -1);

# three new instances
my $n1 = OBO::Core::Instance->new();
my $n2 = OBO::Core::Instance->new();
my $n3 = OBO::Core::Instance->new();

$n1->id("APO:K0000001");
$n2->id("APO:K0000002");
$n3->id("APO:K0000003");

$n1->name("instance of One");
$n2->name("instance of Two");
$n3->name("instance of Three");

# remove from my_set
my $rcode = $my_set->remove($n1);
ok($rcode == 0);
ok($my_set->size() == 0);
ok(!$my_set->contains($n1));
$my_set->add($n1);
ok($my_set->contains($n1));
$rcode = $my_set->remove($n1);
ok($rcode == 1);
ok($my_set->size() == 0);
ok(!$my_set->contains($n1));

$my_set->add($n1);
ok($my_set->contains($n1));
$my_set->add($n2);
ok($my_set->contains($n2));
$my_set->add($n3);
ok($my_set->contains($n3));

ok($my_set->size() == 3);
my $n3_idem = OBO::Core::Instance->new();
$n3_idem->id("APO:K0000003");
$n3_idem->name("instance of Three");
$my_set->add($n3_idem);
ok($my_set->contains($n3_idem));
ok($my_set->size() == 3);

$my_set->add($n3_idem);
$my_set->add($n3_idem);
$my_set->add($n3_idem);
$my_set->add($n3_idem);
$my_set->add($n3_idem);
ok($my_set->size() == 3);

my $n4 = OBO::Core::Instance->new();
my $n5 = OBO::Core::Instance->new();
my $n6 = OBO::Core::Instance->new();

$n4->id("APO:K0000004");
$n5->id("APO:K0000005");
$n6->id("APO:K0000006");

$n4->name("instance of Four");
$n5->name("instance of Five");
$n6->name("instance of Six");

$my_set->add_all($n4, $n5, $n6);
ok($my_set->contains($n4) && $my_set->contains($n5) && $my_set->contains($n6));
ok($my_set->contains_id("APO:K0000006"));
ok(!$my_set->contains_id("APO:K0000007"));
ok($my_set->contains_name('instance of Six'));
ok(!$my_set->contains_name('instance of Seven'));

$my_set->add_all($n4, $n5, $n6);
ok($my_set->size() == 6);

# remove from my_set
$rcode = $my_set->remove($n4);
ok($rcode == 1);
ok($my_set->size() == 5);
ok(!$my_set->contains($n4));

my $n7 = $n4;
my $n8 = $n5;
my $n9 = $n6;

my $my_set2 = OBO::Util::InstanceSet->new();
ok(1);

ok($my_set2->is_empty());
ok(!$my_set->equals($my_set2));

$my_set->add_all($n4, $n5, $n6);
$my_set2->add_all($n7, $n8, $n9, $n1, $n2, $n3);
ok(!$my_set2->is_empty());
ok($my_set->contains($n7) && $my_set->contains($n8) && $my_set->contains($n9));
ok($my_set->equals($my_set2));

ok($my_set2->size() == 6);

$my_set2->clear();
ok($my_set2->is_empty());
ok($my_set2->size() == 0);

ok(1);