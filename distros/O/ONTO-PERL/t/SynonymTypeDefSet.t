# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SynonymTypeDefSet.t'

#########################

BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 30;
}

#########################

use OBO::Util::SynonymTypeDefSet;
use OBO::Core::SynonymTypeDef;

# new set
my $my_set = OBO::Util::SynonymTypeDefSet->new();
ok(1);
ok($my_set->is_empty() == 1);

my @arr = $my_set->get_set();
ok($#{@arr} == -1);

# three new synonyms
my $std1 = OBO::Core::SynonymTypeDef->new();
my $std2 = OBO::Core::SynonymTypeDef->new();
my $std3 = OBO::Core::SynonymTypeDef->new();

# filling them...
$std1->as_string("goslim_plant1", "Plant GO slim1", "EXACT");
$std2->as_string("goslim_plant2", "Plant GO slim2", "EXACT");
$std3->as_string("goslim_plant3", "Plant GO slim3", "EXACT");

# tests with empty set
$my_set->remove($std1);
ok($my_set->size() == 0);
ok(!$my_set->contains($std1));

$my_set->add($std1);
ok($my_set->contains($std1));
$my_set->remove($std1);
ok($my_set->size() == 0);
ok(!$my_set->contains($std1));

# add's
$my_set->add($std1);
ok($my_set->contains($std1));
$my_set->add($std2);
ok($my_set->contains($std2));
$my_set->add($std3);
ok($my_set->contains($std3));

my $std4 = OBO::Core::SynonymTypeDef->new();
my $std5 = OBO::Core::SynonymTypeDef->new();
my $std6 = OBO::Core::SynonymTypeDef->new();

# filling them...
$std4->as_string("goslim_plant4", "Plant GO slim4", "EXACT");
$std5->as_string("goslim_plant5", "Plant GO slim5", "EXACT");
$std6->as_string("goslim_plant1", "Plant GO slim1", "EXACT"); # repeated !!!

$my_set->add_all($std4, $std5);
my $false = $my_set->add($std6);
ok($false == 0);
ok($my_set->contains($std4) && $my_set->contains($std5) && $my_set->contains($std6));

### get versions ###
#foreach ($my_set->get_set()) {
#	print $_, "\n";
#}

$my_set->add_all($std4, $std5, $std6);
ok($my_set->size() == 5);

# remove from my_set
$my_set->remove($std4);
ok($my_set->size() == 4);
ok(!$my_set->contains($std4));

my $std7 = $std4;
my $std8 = $std5;
my $std9 = $std6;

# a second set
my $my_set2 = OBO::Util::SynonymTypeDefSet->new();
ok(1);

ok($my_set2->is_empty());
ok(!$my_set->equals($my_set2));

my $add_all_check = $my_set->add_all($std4, $std5, $std6);
ok($add_all_check == 0);
$add_all_check = $my_set2->add_all($std7, $std8, $std9, $std1, $std2, $std3);
ok($add_all_check == 0);
ok(!$my_set2->is_empty());
ok($my_set->contains($std7) && $my_set->contains($std8) && $my_set->contains($std9));
# todo check the next test:
#ok($my_set->equals($my_set2));

ok($my_set2->size() == 5);

$my_set2->clear();
ok($my_set2->is_empty());
ok($my_set2->size() == 0);

#
# more tests
#
my $stdA = OBO::Core::SynonymTypeDef->new();
my $stdB = OBO::Core::SynonymTypeDef->new();

$stdA->as_string("dummy", "Plant dummy", "EXACT");
$stdB->as_string("dummy", "Plant dummy", "EXACT");

$my_set2->clear();
$my_set2->add_all($stdA, $stdB);
ok($my_set2->size() == 1);
ok($my_set2->contains($stdB));
ok($my_set2->contains($stdA));

ok(1);
