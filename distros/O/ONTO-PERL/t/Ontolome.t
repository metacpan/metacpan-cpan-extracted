# $Id: Ontolome.t 1642 2013-09-05 14:10:35Z easr $
#
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Ontolome.t'

#########################

BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 192 - 3;
}

#########################

use strict;

use OBO::Core::Ontology;
use OBO::Util::Ontolome;
use OBO::Core::Term;
use OBO::Core::Relationship;
use OBO::Core::RelationshipType;
use OBO::Parser::OBOParser;

# new ontolome
my $ome1   = OBO::Util::Ontolome->new();
my $onto1  = OBO::Core::Ontology->new();
my $onto2  = OBO::Core::Ontology->new();
my $onto22 = OBO::Core::Ontology->new();

my $onto3 = $ome1->union($onto1, $onto2);
ok($onto3->get_number_of_terms() == 0);
ok($onto3->get_number_of_relationships() == 0);

my $n1 = OBO::Core::Term->new();
my $n2 = OBO::Core::Term->new();

$n1->id('APO:D0000001');
$n2->id('APO:D0000001'); # same ID!

$n1->name('One');
$n2->name('One');

$n2->def_as_string('My definition.', '[APO:ea]');

$onto1->add_term($n1);
$onto2->add_term($n2);

$n1->xref_set_as_string('[DO:0000001]');
$n2->xref_set_as_string('[DO:0000002]');

ok($onto1->get_number_of_terms() == 1);
$onto3 = $ome1->union($onto1, $onto2);
ok($onto1->get_number_of_terms() == 1);
ok($onto3->get_number_of_terms() == 1);
ok($onto3->get_number_of_relationships() == 0);

my $n = $onto3->get_term_by_id('APO:D0000001');
ok($n->name() eq 'One');
ok($n->def_as_string() eq "\"My definition.\" [APO:ea]");
ok($n->xref_set()->get_set() == 2);

# more terms in onto1
my $n3 = OBO::Core::Term->new();
my $n5 = OBO::Core::Term->new();
$n3->id('APO:D0000003');
$n5->id('APO:D0000005');
$n3->name('Three');
$n5->name('Five');

$onto1->add_term($n3);
$onto1->add_term($n5);

ok($onto1->get_number_of_terms() == 3);

# two new relationships
my $r51 = OBO::Core::Relationship->new();
my $r31 = OBO::Core::Relationship->new();

$r51->id('APO:D0000005_is_a_APO:D0000001');
$r31->id('APO:D0000003_part_of_APO:D0000001');
$r51->type('is_a');
$r31->type('part_of');
$r51->link($n5, $n1); 
$r31->link($n3, $n1);

$onto1->add_relationship_type_as_string('is_a', 'is_a');
$onto1->add_relationship_type_as_string('part_of', 'part_of');

$onto1->add_relationship($r51);
$onto1->add_relationship($r31);

ok($onto1->get_number_of_terms() ==3);

# more terms in onto2
my $n4 = OBO::Core::Term->new();
my $n6 = OBO::Core::Term->new();
$n4->id('APO:D0000004');
$n6->id('APO:D0000006');
$n4->name('Four');
$n6->name('Six');

$onto2->add_term($n4);
$onto2->add_term($n6);

# two new relationships
my $r42 = OBO::Core::Relationship->new();
my $r64 = OBO::Core::Relationship->new();

$r42->id('APO:D0000004_is_a_APO:D0000001');
$r64->id('APO:D0000006_part_of_APO:D0000004');
$r42->type('is_a');
$r64->type('part_of');
$r42->link($n4, $n2); 
$r64->link($n6, $n4);

$onto2->add_relationship_type_as_string('is_a', 'is_a');
$onto2->add_relationship_type_as_string('part_of', 'part_of');

$onto2->add_relationship($r42);
$onto2->add_relationship($r64);

ok($onto1->get_number_of_terms() == 3);

my $onto4 = $ome1->union($onto1, $onto2);

ok($onto1->get_number_of_terms() == 3);
ok($onto4->get_number_of_terms() == 5);
ok($onto4->get_number_of_relationships() >= 4); # diff arch: '>='

my $nn1 = $onto4->get_term_by_id('APO:D0000001');
my @relatives1 = @{$onto4->get_descendent_terms($nn1)};
ok(scalar(@relatives1) == 4);

my $nn6 = $onto4->get_term_by_id('APO:D0000006');
my @relatives2 = @{$onto4->get_ancestor_terms($nn6)};
ok(scalar(@relatives2) == 2);

my $nn5 = $onto4->get_term_by_id('APO:D0000005');
my @relatives3 = @{$onto4->get_ancestor_terms($nn5)};
ok(scalar(@relatives3) == 1);

ok($onto1->get_number_of_terms() == 3);
my $inter_onto = $ome1->intersection($onto1, $onto2);
ok($onto1->get_number_of_terms == 3);
ok($onto2->get_number_of_terms == 3);
ok($inter_onto->get_number_of_terms() == 1);
ok($inter_onto->get_number_of_relationships() == 0);

my $inter_onto_reflex = $ome1->intersection($inter_onto, $inter_onto);
ok($inter_onto_reflex->get_number_of_terms() == 1);
ok($inter_onto_reflex->get_number_of_relationships() == 0);

my $onto1_reflex = $ome1->intersection($onto1, $onto1);
ok($onto1_reflex->get_number_of_terms() == 3);
ok($onto1_reflex->get_number_of_relationships() == 2);

my $t1  = OBO::Core::Term->new();
my $t2  = OBO::Core::Term->new();
my $t3  = OBO::Core::Term->new();
my $t4  = OBO::Core::Term->new();
my $t5  = OBO::Core::Term->new();
my $t6  = OBO::Core::Term->new();
my $t7  = OBO::Core::Term->new();
my $t8  = OBO::Core::Term->new();
my $t9  = OBO::Core::Term->new();
my $t10 = OBO::Core::Term->new();
my $t11 = OBO::Core::Term->new();
my $t12 = OBO::Core::Term->new();

$t1->id('APO:T0000001');
$t2->id('APO:T0000002');
$t3->id('APO:T0000003');
$t4->id('APO:T0000004');
$t5->id('APO:T0000005');
$t6->id('APO:T0000006');
$t7->id('APO:T0000007');
$t8->id('APO:T0000008');
$t9->id('APO:T0000009');
$t10->id('APO:T0000010');
$t11->id('APO:T0000011');
$t12->id('APO:T0000012');

$t1->name('t1');
$t2->name('t2');
$t3->name('t3');
$t4->name('t4');
$t5->name('t5');
$t6->name('t6');
$t7->name('t7');
$t8->name('t8');
$t9->name('t9');
$t10->name('t10');
$t11->name('t11');
$t12->name('t12');

$onto22->add_relationship_type_as_string('is_a', 'is_a');
$onto22->add_relationship_type_as_string('part_of', 'part_of');
$onto22->get_relationship_type_by_id('is_a')->is_transitive();
$onto22->create_rel($t2, 'is_a', $t1);
$onto22->create_rel($t3, 'is_a', $t2);
$onto22->create_rel($t4, 'is_a', $t3);
$onto22->create_rel($t5, 'is_a', $t2);
$onto22->create_rel($t2, 'is_a', $t6);
$onto22->create_rel($t2, 'is_a', $t7);
$onto22->create_rel($t1, 'is_a', $t8);
$onto22->create_rel($t6, 'is_a', $t8);
$onto22->create_rel($t1, 'part_of', $t10);
$onto22->create_rel($t10, 'is_a', $t9);
$onto22->create_rel($t7, 'part_of', $t11);
$onto22->create_rel($t12, 'is_a', $t9);

my $onto22_reflex = $ome1->intersection($onto22, $onto22);
ok($onto22_reflex->get_number_of_terms() == 12);
ok($onto22_reflex->get_number_of_relationships() == 12);
ok($onto22_reflex->has_relationship_id('APO:T0000002_is_a_APO:T0000001'));

my $onto23 = OBO::Core::Ontology->new();
my $tt0  = OBO::Core::Term->new();
my $tt1  = OBO::Core::Term->new();
my $tt4  = OBO::Core::Term->new();
my $tt5  = OBO::Core::Term->new();
my $tt6  = OBO::Core::Term->new();
my $tt8  = OBO::Core::Term->new();
my $tt9  = OBO::Core::Term->new();
my $tt11 = OBO::Core::Term->new(); 

$tt0->id('APO:T0000000');
$tt1->id('APO:T0000001');
$tt4->id('APO:T0000004');
$tt5->id('APO:T0000005');
$tt6->id('APO:T0000006');
$tt8->id('APO:T0000008');
$tt9->id('APO:T0000009');
$tt11->id('APO:T0000011');

$tt0->name('t0');
$tt1->name('t1');
$tt4->name('t4');
$tt5->name('t5');
$tt6->name('t6');
$tt8->name('t8');
$tt9->name('t9');
$tt11->name('t11');

$onto23->add_relationship_type_as_string('is_a', 'is_a');
$onto23->get_relationship_type_by_id('is_a')->is_transitive();
$onto23->create_rel($tt1, 'is_a', $tt0);
$onto23->create_rel($tt4, 'is_a', $tt1);
$onto23->create_rel($tt5, 'is_a', $tt1);
$onto23->create_rel($tt4, 'is_a', $tt6);
$onto23->create_rel($tt0, 'is_a', $tt8);
$onto23->create_rel($tt8, 'is_a', $tt9);
$onto23->create_rel($tt5, 'is_a', $tt11);

my $onto22_23 = $ome1->intersection($onto23, $onto22);
ok($onto22_23->get_number_of_terms() == 7);
ok($onto22_23->get_number_of_relationships() == 4);
ok($onto22_23->has_relationship_id('APO:T0000004_is_a_APO:T0000001'));
ok($onto22_23->has_relationship_id('APO:T0000005_is_a_APO:T0000001'));
ok($onto22_23->has_relationship_id('APO:T0000004_is_a_APO:T0000006'));
ok(!($onto22_23->has_relationship_id('APO:T0000005_is_a_APO:T0000006')));
ok($onto22_23->has_relationship_id('APO:T0000001_is_a_APO:T0000008'));
ok(!($onto22_23->has_relationship_id('APO:T0000006_is_a_APO:T0000008')));
ok(!($onto22_23->has_relationship_id('APO:T0000001_is_a_APO:T0000009')));
ok(!($onto22_23->has_relationship_id('APO:T0000005_is_a_APO:T0000011')));

my $o1  = OBO::Core::Ontology->new();
my $d5  = OBO::Core::Term->new();
my $d2  = OBO::Core::Term->new();
my $d6  = OBO::Core::Term->new();
my $d1  = OBO::Core::Term->new();
my $d7  = OBO::Core::Term->new();
my $d8  = OBO::Core::Term->new();
my $d10 = OBO::Core::Term->new();
my $d11 = OBO::Core::Term->new();
my $d20  = OBO::Core::Term->new();
my $d21  = OBO::Core::Term->new();
my $d32  = OBO::Core::Term->new();
my $d23  = OBO::Core::Term->new();
my $d24  = OBO::Core::Term->new();
my $d25  = OBO::Core::Term->new();
my $d26  = OBO::Core::Term->new();
my $d27  = OBO::Core::Term->new();
my $d28  = OBO::Core::Term->new();
my $d29  = OBO::Core::Term->new();

$d5->id('5');
$d2->id('2');
$d6->id('6');
$d1->id('1');
$d7->id('7');
$d8->id('8');
$d10->id('10');
$d11->id('11');
$d20->id('20');
$d21->id('21');
$d32->id('32');
$d23->id('23');
$d24->id('24');
$d25->id('25');
$d26->id('26');
$d27->id('27');
$d28->id('28');
$d29->id('29');

$d5->name('5');
$d2->name('2');
$d6->name('6');
$d1->name('1');
$d7->name('7');
$d8->name('8');
$d10->name('10');
$d11->name('11');
$d20->name('20');
$d21->name('21');
$d32->name('32');
$d23->name('23');
$d24->name('24');
$d25->name('25');
$d26->name('26');
$d27->name('27');
$d28->name('28');
$d29->name('29');

my $r = 'is_a';
$o1->add_relationship_type_as_string($r, $r);
$o1->create_rel($d5,$r,$d2);
$o1->create_rel($d2,$r,$d6);
$o1->create_rel($d2,$r,$d1);
$o1->create_rel($d2,$r,$d7);
$o1->create_rel($d7,$r,$d8);
$o1->create_rel($d7,$r,$d11);
$o1->create_rel($d1,$r,$d10);
$o1->create_rel($d1,$r,$d8);
$o1->create_rel($d5,$r,$d23);
$o1->create_rel($d11,$r,$d28);
$o1->create_rel($d28,$r,$d29);
$o1->create_rel($d8,$r,$d27);
$o1->create_rel($d27,$r,$d26);
$o1->create_rel($d10,$r,$d24);
$o1->create_rel($d24,$r,$d25);
$o1->create_rel($d25,$r,$d26);
$o1->create_rel($d6,$r,$d20);
$o1->create_rel($d20,$r,$d21);
$o1->create_rel($d20,$r,$d32);
$o1->create_rel($d21,$r,$d25);

my $o2   = OBO::Core::Ontology->new();
my $d52  = OBO::Core::Term->new();
my $d22  = OBO::Core::Term->new();
my $d62  = OBO::Core::Term->new();
my $d12  = OBO::Core::Term->new();
my $d72  = OBO::Core::Term->new();
my $d82  = OBO::Core::Term->new();
my $d102 = OBO::Core::Term->new();
my $d112 = OBO::Core::Term->new();

$d52->id("5");
$d22->id("2");
$d62->id("6");
$d12->id("1");
$d72->id("7");
$d82->id("8");
$d102->id("10");
$d112->id("11");

$d52->name("5");
$d22->name("2");
$d62->name("6");
$d12->name("1");
$d72->name("7");
$d82->name("8");
$d102->name("10");
$d112->name("11");

$r = 'is_a';
$o2->add_relationship_type_as_string($r, $r);
$o2->create_rel($d5,$r,$d112);
$o2->create_rel($d5,$r,$d102);
#$o2->create_rel($d2,$r,$d1);
#$o2->create_rel($d2,$r,$d7);
#$o2->create_rel($d7,$r,$d8);
#$o2->create_rel($d7,$r,$d11);
#$o2->create_rel($d1,$r,$d10);
#$o2->create_rel($d1,$r,$d8);

$ome1->intersection($o2, $o1);

#
# get_paths_term_terms
#
my $stop = OBO::Util::Set->new();
$stop->add($d26->id());
$stop->add($d27->id());
$stop->add($d25->id());

my @ref_paths = $o1->get_paths_term_terms($d2->id(), $stop);

ok($#ref_paths ==  7);

my $cc = 0;
map {map {$cc++} @$_} @ref_paths;
ok ($cc ==  32);

my $o3  = OBO::Core::Ontology->new();
my $de5  = OBO::Core::Term->new();
my $de2  = OBO::Core::Term->new();
my $de6  = OBO::Core::Term->new();
my $de1  = OBO::Core::Term->new();
my $de7  = OBO::Core::Term->new();
my $de8  = OBO::Core::Term->new();
my $de10 = OBO::Core::Term->new();
my $de11 = OBO::Core::Term->new();

my $de20  = OBO::Core::Term->new();
my $de21  = OBO::Core::Term->new();
my $de32  = OBO::Core::Term->new();
my $de23  = OBO::Core::Term->new();
my $de24  = OBO::Core::Term->new();
my $de25  = OBO::Core::Term->new();
my $de26  = OBO::Core::Term->new();
my $de27  = OBO::Core::Term->new();
my $de28  = OBO::Core::Term->new();
my $de29  = OBO::Core::Term->new();

$de5->id('5');
$de2->id('2');
$de6->id('6');
$de1->id('1');
$de7->id('7');
$de8->id('8');
$de10->id('10');
$de11->id('11');
$de20->id('20');
$de21->id('21');
$de32->id('32');
$de23->id('23');
$de24->id('24');
$de25->id('25');
$de26->id('26');
$de27->id('27');
$de28->id('28');
$de29->id('29');

$de5->name('5');
$de2->name('2');
$de6->name('6');
$de1->name('1');
$de7->name('7');
$de8->name('8');
$de10->name('10');
$de11->name('11');
$de20->name('20');
$de21->name('21');
$de32->name('32');
$de23->name('23');
$de24->name('24');
$de25->name('25');
$de26->name('26');
$de27->name('27');
$de28->name('28');
$de29->name('29');

my $s = 'part_of';
$o3->add_relationship_type_as_string($r, $r);
$o3->add_relationship_type_as_string($s, $s);
$o3->create_rel($de5,$r,$de8);
$o3->create_rel($de8,$r,$de11);
$o3->create_rel($de11,$r,$de28);
$o3->create_rel($de28,$r,$de26);
$o3->create_rel($de28,$s,$de29); # part_of !!!
$o3->create_rel($de5,$r,$de24);
$o3->create_rel($de24,$r,$de23);

my $ontito = $ome1->intersection($o1, $o3);
ok($ontito->get_number_of_terms() == 8);
ok($ontito->get_number_of_relationships() == 6);
ok($ontito->has_relationship_id('5_is_a_8'));
ok($ontito->has_relationship_id('8_is_a_26'));
ok(!($ontito->has_relationship_id('5_is_a_26')));
ok($ontito->has_relationship_id('5_is_a_11'));
ok($ontito->has_relationship_id('11_is_a_28'));
ok(!($ontito->has_relationship_id('5_is_a_28')));
ok(!($ontito->has_relationship_id('28_part_of_29')));
ok(!($ontito->has_relationship_id('5_is_a_29')));
ok(!($ontito->has_relationship_id('11_is_a_29')));
ok($ontito->has_relationship_id('5_is_a_24'));
ok($ontito->has_relationship_id('5_is_a_23'));

#
# from GO
#
my $go = OBO::Core::Ontology->new();
my $id = OBO::Core::IDspace->new();
$id->as_string('GO', 'urn:lsid:bioontology.org:GO:', 'gene ontology terms');
$go->idspaces($id);

my $g60  = OBO::Core::Term->new();
my $g59  = OBO::Core::Term->new();
my $g242 = OBO::Core::Term->new();
my $g29  = OBO::Core::Term->new();
my $g265 = OBO::Core::Term->new();
my $g56  = OBO::Core::Term->new();
my $g2   = OBO::Core::Term->new();
my $g0   = OBO::Core::Term->new();
my $g118 = OBO::Core::Term->new();
my $g117 = OBO::Core::Term->new();
my $g103 = OBO::Core::Term->new();
my $g271 = OBO::Core::Term->new();
my $g38  = OBO::Core::Term->new();

$g60->id('60');
$g59->id('59');
$g242->id('242');
$g29->id('29');
$g265->id('265');
$g56->id('56');
$g2->id('2');
$g0->id('10');
$g118->id('118');
$g117->id('117');
$g103->id('103');
$g271->id('271');
$g38->id('38');

$g60->name('60');
$g59->name('59');
$g242->name('242');
$g29->name('29');
$g265->name('265');
$g56->name('56');
$g2->name('2');
$g0->name('10');
$g118->name('118');
$g117->name('117');
$g103->name('103');
$g271->name('271');
$g38->name('38');

$go->add_relationship_type_as_string($r, $r);
$go->add_relationship_type_as_string($s, $s);

$go->create_rel($g60,  $r, $g59);
$go->create_rel($g59,  $r, $g242);
$go->create_rel($g242, $r, $g29);
$go->create_rel($g29,  $s, $g265);
$go->create_rel($g265, $r, $g56);
$go->create_rel($g56,  $r, $g2);
$go->create_rel($g2,   $r, $g0);
$go->create_rel($g59,  $s, $g117);
$go->create_rel($g60,  $s, $g118);
$go->create_rel($g118, $s, $g117);
$go->create_rel($g117, $r, $g103);
$go->create_rel($g103, $s, $g271);
$go->create_rel($g271, $r, $g38);
$go->create_rel($g271, $s, $g265);
$go->create_rel($g38,  $s, $g56);

ok($go->get_number_of_relationships() == 15);

my $go_go = $ome1->intersection($go, $go);
ok($go_go->get_number_of_terms() == 13);
ok($go_go->get_number_of_relationships() >= 16);

#
# transitive closure test
#
open (FH, ">./t/data/test_go.obo") || die "Run as root the tests: ", $!;
$go->export('obo', \*FH);
close FH;

#
# get_paths_term_terms
#
my $stop_set = OBO::Util::Set->new();
$stop_set->add($g29->id());
$stop_set->add($g271->id());
$stop_set->add($g117->id());

my @p1 = ('60_is_a_59', '59_is_a_242', '242_is_a_29');

my @ref_paths1 = $go->get_paths_term_terms_same_rel($g60->id(), $stop_set, $r); # along is_a
foreach my $ref_path (@ref_paths1) {
	foreach my $tt (@$ref_path) {
		ok ($tt->id() eq shift @p1);
	}
}

ok($#ref_paths1 ==  0);

$cc = 0;
map {map {$cc++} @$_} @ref_paths1;
ok ($cc ==  3);

my @p2 = ('60_part_of_118', '118_part_of_117');

my @ref_paths2 = $go->get_paths_term_terms_same_rel($g60->id(), $stop_set, $s); # along part_of
foreach my $ref_path (@ref_paths2) {
	foreach my $tt (@$ref_path) {
		ok ($tt->id() eq shift @p2);
	}
}

ok($#ref_paths2 ==  0);

$cc = 0;
map {map {$cc++} @$_} @ref_paths2;
ok ($cc ==  2);

#
# get the transitive closure
#
my $go_transitive_closure = $ome1->transitive_closure($go);

# original relationships: 15
ok($go_transitive_closure->has_relationship_id('60_is_a_59'));      # N
ok($go_transitive_closure->has_relationship_id('59_is_a_242'));     # L
ok($go_transitive_closure->has_relationship_id('242_is_a_29'));     # D
ok($go_transitive_closure->has_relationship_id('29_part_of_265'));  # H
ok($go_transitive_closure->has_relationship_id('265_is_a_56'));     # E
ok($go_transitive_closure->has_relationship_id('56_is_a_2'));       # K
ok($go_transitive_closure->has_relationship_id('2_is_a_10'));       # I
ok($go_transitive_closure->has_relationship_id('59_part_of_117'));  # M
ok($go_transitive_closure->has_relationship_id('60_part_of_118'));  # O
ok($go_transitive_closure->has_relationship_id('118_part_of_117')); # C
ok($go_transitive_closure->has_relationship_id('117_is_a_103'));    # B
ok($go_transitive_closure->has_relationship_id('103_part_of_271')); # A
ok($go_transitive_closure->has_relationship_id('271_is_a_38'));     # F
ok($go_transitive_closure->has_relationship_id('271_part_of_265')); # G
ok($go_transitive_closure->has_relationship_id('38_part_of_56'));   # J

# original rel's + new transitive closure rel's: 15 + 8 = 23
ok($go_transitive_closure->has_relationship_id('103_part_of_265'));  # 1
ok($go_transitive_closure->has_relationship_id('103_part_of_271'));  # A

ok($go_transitive_closure->has_relationship_id('117_is_a_103'));     # B

ok($go_transitive_closure->has_relationship_id('118_part_of_117'));  # C

ok($go_transitive_closure->has_relationship_id('242_is_a_29'));      # D

ok($go_transitive_closure->has_relationship_id('265_is_a_10'));      # 2
ok($go_transitive_closure->has_relationship_id('265_is_a_2'));       # 3
ok($go_transitive_closure->has_relationship_id('265_is_a_56'));      # E

ok($go_transitive_closure->has_relationship_id('271_is_a_38'));      # F
ok($go_transitive_closure->has_relationship_id('271_part_of_265'));  # G

ok($go_transitive_closure->has_relationship_id('29_part_of_265'));   # H

ok($go_transitive_closure->has_relationship_id('2_is_a_10'));        # I

ok($go_transitive_closure->has_relationship_id('38_part_of_56'));    # J

ok($go_transitive_closure->has_relationship_id('56_is_a_10'));       # 4
ok($go_transitive_closure->has_relationship_id('56_is_a_2'));        # K

ok($go_transitive_closure->has_relationship_id('59_is_a_242'));      # L
ok($go_transitive_closure->has_relationship_id('59_is_a_29'));       # 5
ok($go_transitive_closure->has_relationship_id('59_part_of_117'));   # M

ok($go_transitive_closure->has_relationship_id('60_is_a_242'));      # 6
ok($go_transitive_closure->has_relationship_id('60_is_a_29'));       # 7
ok($go_transitive_closure->has_relationship_id('60_is_a_59'));       # N
ok($go_transitive_closure->has_relationship_id('60_part_of_117'));   # 8
ok($go_transitive_closure->has_relationship_id('60_part_of_118'));   # O

# new composititionally created relationships: 26 [partof*isa=>partof and isa*partof=>partof]
ok($go_transitive_closure->has_relationship_id('103_part_of_38'));

ok($go_transitive_closure->has_relationship_id('117_part_of_271'));
ok($go_transitive_closure->has_relationship_id('117_part_of_38'));

#ok($go_transitive_closure->has_relationship_id('118_part_of_103')); # manu

ok($go_transitive_closure->has_relationship_id('242_part_of_10'));
ok($go_transitive_closure->has_relationship_id('242_part_of_2'));
ok($go_transitive_closure->has_relationship_id('242_part_of_265'));
ok($go_transitive_closure->has_relationship_id('242_part_of_56'));

ok($go_transitive_closure->has_relationship_id('271_part_of_10'));
ok($go_transitive_closure->has_relationship_id('271_part_of_2'));
ok($go_transitive_closure->has_relationship_id('271_part_of_56'));

ok($go_transitive_closure->has_relationship_id('29_part_of_10'));
ok($go_transitive_closure->has_relationship_id('29_part_of_2'));
ok($go_transitive_closure->has_relationship_id('29_part_of_56'));

ok($go_transitive_closure->has_relationship_id('38_part_of_10'));
ok($go_transitive_closure->has_relationship_id('38_part_of_2'));

ok($go_transitive_closure->has_relationship_id('59_part_of_10'));
#ok($go_transitive_closure->has_relationship_id('59_part_of_103')); # manu
ok($go_transitive_closure->has_relationship_id('59_part_of_2'));
ok($go_transitive_closure->has_relationship_id('59_part_of_265'));
ok($go_transitive_closure->has_relationship_id('59_part_of_56'));

ok($go_transitive_closure->has_relationship_id('60_part_of_10'));
#ok($go_transitive_closure->has_relationship_id('60_part_of_103')); # manu
ok($go_transitive_closure->has_relationship_id('60_part_of_2'));
ok($go_transitive_closure->has_relationship_id('60_part_of_265'));
ok($go_transitive_closure->has_relationship_id('60_part_of_56'));

# after the composition, we get more posibilities to get transitivity over is_a and part_of: 17 new rel's
ok($go_transitive_closure->has_relationship_id('103_part_of_10'));
ok($go_transitive_closure->has_relationship_id('103_part_of_2'));
ok($go_transitive_closure->has_relationship_id('103_part_of_56'));

ok($go_transitive_closure->has_relationship_id('117_part_of_10'));
ok($go_transitive_closure->has_relationship_id('117_part_of_2'));
ok($go_transitive_closure->has_relationship_id('117_part_of_265'));
ok($go_transitive_closure->has_relationship_id('117_part_of_56'));

ok($go_transitive_closure->has_relationship_id('118_part_of_10'));
ok($go_transitive_closure->has_relationship_id('118_part_of_2'));
ok($go_transitive_closure->has_relationship_id('118_part_of_265'));
ok($go_transitive_closure->has_relationship_id('118_part_of_271'));
ok($go_transitive_closure->has_relationship_id('118_part_of_38'));
ok($go_transitive_closure->has_relationship_id('118_part_of_56'));

ok($go_transitive_closure->has_relationship_id('59_part_of_271'));
ok($go_transitive_closure->has_relationship_id('59_part_of_38'));

ok($go_transitive_closure->has_relationship_id('60_part_of_271'));
ok($go_transitive_closure->has_relationship_id('60_part_of_38'));

ok($go->get_number_of_relationships() == 15);
ok($go_transitive_closure->get_number_of_relationships() == 23 + 26 + 17 - 3); # many new rels: isa*partof=>partof and partof*isa=>partof

#print STDERR "\nNUMBER OF RELS: ", $go_transitive_closure->get_number_of_relationships(), "\n";

open (TC, ">./t/data/test_go_transitive_closure.obo") || die "Run as root the tests: ", $!;
$go_transitive_closure->export('obo', \*TC);
close TC;

#
# get the transitive reduction
#
my $go_transitive_reduction = $ome1->transitive_reduction($go);

ok(!$go_transitive_reduction->has_relationship_id('59_is_a_29'));
ok(!$go_transitive_reduction->has_relationship_id('103_part_of_265'));
ok(!$go_transitive_reduction->has_relationship_id('60_is_a_242'));
ok(!$go_transitive_reduction->has_relationship_id('60_is_a_29'));
ok(!$go_transitive_reduction->has_relationship_id('60_part_of_117'));
ok(!$go_transitive_reduction->has_relationship_id('265_is_a_2'));
ok(!$go_transitive_reduction->has_relationship_id('265_is_a_10'));
ok(!$go_transitive_reduction->has_relationship_id('56_is_a_10'));

ok($go_transitive_reduction->has_relationship_id('60_is_a_59'));
ok($go_transitive_reduction->has_relationship_id('59_is_a_242'));
ok($go_transitive_reduction->has_relationship_id('242_is_a_29'));
ok($go_transitive_reduction->has_relationship_id('29_part_of_265'));
ok($go_transitive_reduction->has_relationship_id('265_is_a_56'));
ok($go_transitive_reduction->has_relationship_id('56_is_a_2'));
ok($go_transitive_reduction->has_relationship_id('2_is_a_10'));
ok($go_transitive_reduction->has_relationship_id('59_part_of_117'));
ok($go_transitive_reduction->has_relationship_id('60_part_of_118'));
ok($go_transitive_reduction->has_relationship_id('118_part_of_117'));
ok($go_transitive_reduction->has_relationship_id('117_is_a_103'));
ok($go_transitive_reduction->has_relationship_id('103_part_of_271'));
ok($go_transitive_reduction->has_relationship_id('271_is_a_38'));
ok($go_transitive_reduction->has_relationship_id('271_part_of_265'));
ok($go_transitive_reduction->has_relationship_id('38_part_of_56'));

ok($go_transitive_reduction->get_number_of_relationships() == 15);

ok($go_transitive_closure->has_relationship_id('59_is_a_29'));
ok($go_transitive_closure->has_relationship_id('103_part_of_265'));
ok($go_transitive_closure->has_relationship_id('60_is_a_242'));
ok($go_transitive_closure->has_relationship_id('60_is_a_29'));
ok($go_transitive_closure->has_relationship_id('60_part_of_117'));
ok($go_transitive_closure->has_relationship_id('265_is_a_2'));
ok($go_transitive_closure->has_relationship_id('265_is_a_10'));
ok($go_transitive_closure->has_relationship_id('56_is_a_10'));

$go_transitive_reduction = $ome1->transitive_reduction($go_transitive_closure);
ok(!$go_transitive_reduction->has_relationship_id('59_is_a_29'));
ok(!$go_transitive_reduction->has_relationship_id('103_part_of_265'));
ok(!$go_transitive_reduction->has_relationship_id('60_is_a_242'));
ok(!$go_transitive_reduction->has_relationship_id('60_is_a_29'));
ok(!$go_transitive_reduction->has_relationship_id('60_part_of_117'));
ok(!$go_transitive_reduction->has_relationship_id('265_is_a_2'));
ok(!$go_transitive_reduction->has_relationship_id('265_is_a_10'));
ok(!$go_transitive_reduction->has_relationship_id('56_is_a_10'));

ok($go_transitive_reduction->get_number_of_relationships() == 15);

open (TR, ">./t/data/test_go_transitive_reduction.obo") || die "Run as root the tests: ", $!;
$go_transitive_reduction->export('obo', \*TR);
close TR;

ok(1);