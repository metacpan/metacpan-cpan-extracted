# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl GoaAssociation.t'

#########################

BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 11;
}

#########################

use OBO::APO::GoaAssociation;
use strict;

# three new goa_association's
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


ok(!$assc2->equals($assc3));
ok(!$assc1->equals($assc3));
ok(!$assc1->equals($assc2));
ok($assc1->equals($assc1));
ok($assc2->equals($assc2));
ok($assc3->equals($assc3));

my $assc4 = $assc3;
ok($assc4->equals($assc3));
$assc3->annot_src("annot_src4");
ok($assc4->equals($assc3));

my $assc5 = OBO::APO::GoaAssociation->new();
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

ok($assc1->equals($assc5));

$assc5->annot_src("annot_src5");
ok(!$assc1->equals($assc5));
ok(1);