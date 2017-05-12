# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DbxrefSet.t'

#########################

BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 30;
}

#########################

use OBO::Core::IDspace;
use OBO::Util::IDspaceSet;

# new set
my $my_set = OBO::Util::IDspaceSet->new();
ok(1);
ok($my_set->is_empty() == 1);

my @arr = $my_set->get_set();
ok($#{@arr} == -1);

# three new synonyms
my $std1 = OBO::Core::IDspace->new();
my $std2 = OBO::Core::IDspace->new();
my $std3 = OBO::Core::IDspace->new();

# filling them...
$std1->as_string("GO", "urn:lsid:bioontology.org:GO:", "gene ontology terms");
$std2->as_string("XO", "urn:lsid:bioontology.org:XO:", "x ontology terms");
$std3->as_string("YO", "urn:lsid:bioontology.org:YO:", "y ontology terms");

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

my $std4 = OBO::Core::IDspace->new();
my $std5 = OBO::Core::IDspace->new();
my $std6 = OBO::Core::IDspace->new();

# filling them...
$std4->as_string("ZO", "urn:lsid:bioontology.org:ZO:", "z ontology terms");
$std5->as_string("AO", "urn:lsid:bioontology.org:AO:", "a ontology terms");
$std6->as_string("GO", "urn:lsid:bioontology.org:GO:", "gene ontology terms"); # repeated !!!

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
my $my_set2 = OBO::Util::IDspaceSet->new();
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
my $stdA = OBO::Core::IDspace->new();
my $stdB = OBO::Core::IDspace->new();

$stdA->as_string("OO", "urn:lsid:bioontology.org:OO:", "O ontology terms");
$stdB->as_string("OO", "urn:lsid:bioontology.org:OO:", "O ontology terms");

$my_set2->clear();
$my_set2->add_all($stdA, $stdB);
ok($my_set2->size() == 1);
ok($my_set2->contains($stdB));
ok($my_set2->contains($stdA));

ok(1);
