# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl GoaAssociationSet.t'

#########################

BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 32;
}

#########################

use OBO::Util::Set;
use OBO::APO::GoaAssociationSet;
use OBO::APO::GoaAssociation;
use strict;

#################
# class methods #
#################
my $my_set = OBO::APO::GoaAssociationSet->new();
ok(1);

# three new association's
my $assc1 = OBO::APO::GoaAssociation->new();
my $assc2 = OBO::APO::GoaAssociation->new();
my $assc3 = OBO::APO::GoaAssociation->new();

$assc1->annot_src("annot_src1");
$assc1->aspect("aspect1");
$assc1->assc_id("assc_id1");
$assc1->date("date1");
$assc1->description("description1");
$assc1->go_id("go_id1");
$assc1->obj_id("obj_id1");
$assc1->obj_src("obj_src1");
$assc1->obj_symb("obj_symb1");
$assc1->qualifier("qualifier1");
$assc1->refer("refer1");
$assc1->sup_ref("sup_ref1");
$assc1->synonym("synonym1");
$assc1->taxon("taxon1");
$assc1->type("type1");
$assc1->annot_src("annot_src1");

$assc2->annot_src("annot_src2");
$assc2->aspect("aspect2");
$assc2->assc_id("assc_id2");
$assc2->date("date2");
$assc2->description("description2");
$assc2->go_id("go_id2");
$assc2->obj_id("obj_id2");
$assc2->obj_src("obj_src2");
$assc2->obj_symb("obj_symb2");
$assc2->qualifier("qualifier2");
$assc2->refer("refer2");
$assc2->sup_ref("sup_ref2");
$assc2->synonym("synonym2");
$assc2->taxon("taxon2");
$assc2->type("type2");
$assc2->annot_src("annot_src2");

$assc3->annot_src("annot_src3");
$assc3->aspect("aspect3");
$assc3->assc_id("assc_id3");
$assc3->date("date3");
$assc3->description("description3");
$assc3->go_id("go_id3");
$assc3->obj_id("obj_id3");
$assc3->obj_src("obj_src3");
$assc3->obj_symb("obj_symb3");
$assc3->qualifier("qualifier3");
$assc3->refer("refer3");
$assc3->sup_ref("sup_ref3");
$assc3->synonym("synonym3");
$assc3->taxon("taxon3");
$assc3->type("type3");
$assc3->annot_src("annot_src3");


#######################
# object data methods #
#######################

# remove from my_set
$my_set->remove($assc1);
ok($my_set->size() == 0);
ok(!$my_set->contains($assc1));
$my_set->add($assc1);
ok($my_set->contains($assc1));
$my_set->remove($assc1);
ok($my_set->size() == 0);
ok(!$my_set->contains($assc1));

### add to the set ###
$my_set->add($assc1);
ok($my_set->contains($assc1));
$my_set->add($assc2);
ok($my_set->contains($assc2));
$my_set->add($assc3);
ok($my_set->contains($assc3));

my $assc4 = OBO::APO::GoaAssociation->new();
my $assc5 = OBO::APO::GoaAssociation->new();
my $assc6 = OBO::APO::GoaAssociation->new();

$assc4->annot_src("annot_src4");
$assc4->aspect("aspect4");
$assc4->assc_id("assc_id4");
$assc4->date("date4");
$assc4->description("description4");
$assc4->go_id("go_id4");
$assc4->obj_id("obj_id4");
$assc4->obj_src("obj_src4");
$assc4->obj_symb("obj_symb4");
$assc4->qualifier("qualifier4");
$assc4->refer("refer4");
$assc4->sup_ref("sup_ref4");
$assc4->synonym("synonym4");
$assc4->taxon("taxon4");
$assc4->type("type4");
$assc4->annot_src("annot_src4");

$assc5->annot_src("annot_src5");
$assc5->aspect("aspect5");
$assc5->assc_id("assc_id5");
$assc5->date("date5");
$assc5->description("description5");
$assc5->go_id("go_id5");
$assc5->obj_id("obj_id5");
$assc5->obj_src("obj_src5");
$assc5->obj_symb("obj_symb5");
$assc5->qualifier("qualifier5");
$assc5->refer("refer5");
$assc5->sup_ref("sup_ref5");
$assc5->synonym("synonym5");
$assc5->taxon("taxon5");
$assc5->type("type5");
$assc5->annot_src("annot_src5");

$assc6->annot_src("annot_src6");
$assc6->aspect("aspect6");
$assc6->assc_id("assc_id6");
$assc6->date("date6");
$assc6->description("description6");
$assc6->go_id("go_id6");
$assc6->obj_id("obj_id6");
$assc6->obj_src("obj_src6");
$assc6->obj_symb("obj_symb6");
$assc6->qualifier("qualifier6");
$assc6->refer("refer6");
$assc6->sup_ref("sup_ref6");
$assc6->synonym("synonym6");
$assc6->taxon("taxon6");
$assc6->type("type6");
$assc6->annot_src("annot_src6");


$my_set->add_all($assc4, $assc5, $assc6);
ok($my_set->contains($assc4) && $my_set->contains($assc5) && $my_set->contains($assc6));
# now my_set contains assc's 1-6
### get versions ###
#foreach ($my_set->get_set()) {
#	print $_, "\n";
#}

########################
# other object methods #
########################

$my_set->add_all($assc4, $assc5, $assc6);
ok($my_set->size() == 6);

# remove from my_set
$my_set->remove($assc4);
ok($my_set->size() == 5);
ok(!$my_set->contains($assc4));

my $assc7 = $assc4;
my $assc8 = $assc5;
my $assc9 = $assc6;
$my_set->add_all($assc8, $assc9);
ok($my_set->size() == 5);


my $my_set2 = OBO::APO::GoaAssociationSet->new();
ok(1);

ok($my_set2->is_empty());
ok(!$my_set->equals($my_set2));

$my_set->add_all($assc4, $assc5, $assc6);
ok($my_set->size() == 6);


$my_set2->add_all($assc7, $assc8, $assc9, $assc1, $assc2, $assc3);
ok(!$my_set2->is_empty());
ok($my_set->contains($assc7) && $my_set->contains($assc8) && $my_set->contains($assc9));
ok($my_set->equals($my_set2));



ok($my_set2->size() == 6);

# setting the values in $assc5 identical to those in $assc1
$assc5->annot_src("annot_src1");
$assc5->aspect("aspect1");
$assc5->assc_id("assc_id1");
$assc5->date("date1");
$assc5->description("description1");
$assc5->go_id("go_id1");
$assc5->obj_id("obj_id1");
$assc5->obj_src("obj_src1");
$assc5->obj_symb("obj_symb1");
$assc5->qualifier("qualifier1");
$assc5->refer("refer1");
$assc5->sup_ref("sup_ref1");
$assc5->synonym("synonym1");
$assc5->taxon("taxon1");
$assc5->type("type1");
$assc5->annot_src("annot_src1");
ok($my_set->size() == 6);
ok($my_set->size() == 6);

# eliminating redundancy
$my_set->remove_duplicates();
$my_set2->remove_duplicates();
ok($my_set->size() == 5);
ok($my_set2->size() == 5);

$my_set->clear();
ok($my_set->is_empty());
ok($my_set->size() == 0);
$my_set2->clear();
ok($my_set2->is_empty());
ok($my_set2->size() == 0);

$my_set->add_all($assc1, $assc2, $assc3);
$my_set2->add_all($assc5, $assc2, $assc3);
ok($my_set->equals($my_set2));

ok(1);