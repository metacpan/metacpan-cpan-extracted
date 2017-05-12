# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DbxrefSet.t'

#########################

BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 23;
}

#########################

use OBO::Util::DbxrefSet;
use OBO::Core::Dbxref;
use strict;

#################
# class methods #
#################
my $my_set = OBO::Util::DbxrefSet->new;
ok(1);

# three new dbxref's
my $ref1 = OBO::Core::Dbxref->new;
my $ref2 = OBO::Core::Dbxref->new;
my $ref3 = OBO::Core::Dbxref->new;

$ref1->name("APO:vm");
$ref2->name("APO:ls");
$ref3->name("APO:ea");

#######################
# object data methods #
#######################

# remove from my_set
$my_set->remove($ref1);
ok($my_set->size() == 0);
ok(!$my_set->contains($ref1));
$my_set->add($ref1);
ok($my_set->contains($ref1));
$my_set->remove($ref1);
ok($my_set->size() == 0);
ok(!$my_set->contains($ref1));

### set versions ###
$my_set->add($ref1);
ok($my_set->contains($ref1));
$my_set->add($ref2);
ok($my_set->contains($ref2));
$my_set->add($ref3);
ok($my_set->contains($ref3));

my $ref4 = OBO::Core::Dbxref->new;
my $ref5 = OBO::Core::Dbxref->new;
my $ref6 = OBO::Core::Dbxref->new;

$ref4->name("APO:ef");
$ref5->name("APO:sz");
$ref6->name("APO:qa");

$my_set->add_all($ref4, $ref5, $ref6);
ok($my_set->contains($ref4) && $my_set->contains($ref5) && $my_set->contains($ref6));

### get versions ###
#foreach ($my_set->get_set()) {
#	print $_, "\n";
#}

########################
# other object methods #
########################

$my_set->add_all($ref4, $ref5, $ref6);
ok($my_set->size() == 6);

# remove from my_set
$my_set->remove($ref4);
ok($my_set->size() == 5);
ok(!$my_set->contains($ref4));

my $ref7 = $ref4;
my $ref8 = $ref5;
my $ref9 = $ref6;

my $my_set2 = OBO::Util::DbxrefSet->new;
ok(1);

ok($my_set2->is_empty());
ok(!$my_set->equals($my_set2));

$my_set->add_all($ref4, $ref5, $ref6);
$my_set2->add_all($ref7, $ref8, $ref9, $ref1, $ref2, $ref3);
ok(!$my_set2->is_empty());
ok($my_set->contains($ref7) && $my_set->contains($ref8) && $my_set->contains($ref9));
ok($my_set->equals($my_set2));

ok($my_set2->size() == 6);

$my_set2->clear();
ok($my_set2->is_empty());
ok($my_set2->size() == 0);

ok(1);
