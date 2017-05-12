# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Ontology.t'

#########################

BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 427;
}

#########################

use OBO::Core::Ontology;
use OBO::Core::Term;
use OBO::Core::Instance;
use OBO::Core::Relationship;
use OBO::Core::RelationshipType;
use OBO::Core::SynonymTypeDef;
use OBO::Parser::OBOParser;
use OBO::Util::TermSet;

# three new terms
my $n1 = OBO::Core::Term->new();
my $n2 = OBO::Core::Term->new();
my $n3 = OBO::Core::Term->new();

# three new terms
my $in1 = OBO::Core::Instance->new();
my $in2 = OBO::Core::Instance->new();
my $in3 = OBO::Core::Instance->new();

# new ontology
my $onto = OBO::Core::Ontology->new();
ok($onto->get_number_of_terms() == 0);
ok($onto->get_number_of_relationships() == 0);
ok($onto->get_terms_idspace() eq 'NN');
ok(1);

my $my_ssd = OBO::Core::SubsetDef->new();
$my_ssd->as_string('GO_SS', 'Term used for My GO');
$onto->subset_def_map()->put('GO_SS', $my_ssd);
ok($onto->subset_def_map()->contains_key('GO_SS'));

my @my_ssd = $onto->subset_def_map()->values();
ok($my_ssd[0]->name() eq 'GO_SS');
ok($my_ssd[0]->description() eq 'Term used for My GO');

$n1->id('APO:P0000001');
$n2->id('APO:P0000002');
$n3->id('APO:P0000003');

$in1->id('APO:K0000001');
$in2->id('APO:K0000002');
$in3->id('APO:K0000003');

$n1->name('One');
$n2->name('Two');
$n3->name('Three');

$in1->name('instance of One');
$in2->name('instance of Two');
$in3->name('instance of Three');

my $def1 = OBO::Core::Def->new();
$def1->text('Definition of One');
my $def2 = OBO::Core::Def->new();
$def2->text('Definition of Two');
my $def3 = OBO::Core::Def->new();
$def3->text('Definition of Tres');
$n1->def($def1);
$n2->def($def2);
$n3->def($def3);

$n1->xref_set_as_string('[GO:0000001]');
$n2->xref_set_as_string('[GO:0000002]');
$n3->xref_set_as_string('[GO:0000003]');

$in1->xref_set_as_string('[GO:0000001]');
$in2->xref_set_as_string('[GO:0000002]');
$in3->xref_set_as_string('[GO:0000003]');

# add terms
$onto->delete_term($n1);
ok($onto->has_term($n1) == 0);
$onto->add_term($n1);
$onto->delete_term($n1);
ok($onto->has_term($n1) == 0);
$onto->add_term($n1);
ok($onto->has_term($n1) == 1);

ok($onto->has_term($n2) == 0);
$onto->add_term($n2);
ok($onto->has_term($n2) == 1);

ok($onto->has_term($n3) == 0);
$onto->add_term($n3);
ok($onto->has_term($n3) == 1);

my $udef = undef;
ok($onto->has_term($udef) == 0);

# add instances
$onto->add_instance($in1);
ok($onto->has_instance($in1) == 1);
$onto->add_instance($in2);
ok($onto->has_instance($in2) == 1);
$onto->add_instance($in3);
ok($onto->has_instance($in3) == 1);

my $ts = OBO::Util::TermSet->new();
$ts->add_all($n1, $n2, $n3);

$in1->instance_of($n1);
$in2->instance_of($n2);
$in3->instance_of($n3);

my $j = 1;
foreach my $term (sort {$a->id() cmp $b->id()} $ts->get_set()) {
	ok($term->id eq 'APO:P000000'.$j);
	foreach my $ti ($term->class_of()->get_set()) {
		ok($ti->id eq 'APO:K000000'.$j++);
	}
}

# modifying a term name directly
$n3->name('Trej');
ok($onto->get_term_by_id('APO:P0000003')->name() eq 'Trej');

# modifying a instance name directly
$in3->name('instance of Trej');
ok($onto->get_instance_by_id('APO:K0000003')->name() eq 'instance of Trej');

# modifying a term name via the ontology
$onto->get_term_by_id('APO:P0000003')->name('Three');
ok($onto->get_term_by_id('APO:P0000003')->name() eq 'Three');

# modifying a instance name via the ontology
$onto->get_instance_by_id('APO:K0000003')->name('instance of Three');
ok($onto->get_instance_by_id('APO:K0000003')->name() eq 'instance of Three');

# check terms (+ rels)
ok($onto->get_number_of_terms() == 3);
ok($onto->get_number_of_relationships() == 0);

$onto->delete_term($n1);
ok($onto->has_term($n1) == 0);
ok($onto->get_number_of_terms() == 2);
ok($onto->get_number_of_relationships() == 0);

$onto->add_term($n1);
ok($onto->has_term($n1) == 1);
ok($onto->get_number_of_terms() == 3);
ok($onto->get_number_of_relationships() == 0);

# check instances
ok($onto->get_number_of_instances() == 3);

$onto->delete_instance($in1);
ok($onto->has_instance($in1) == 0);
ok($onto->get_number_of_instances() == 2);

$onto->add_instance($in1);
ok($onto->has_instance($in1) == 1);
ok($onto->get_number_of_instances() == 3);

# new term
my $n4 = OBO::Core::Term->new();
$n4->id('APO:P0000004');
$n4->name('Four');
my $def4 = OBO::Core::Def->new();
$def4->text('Definition of Four');
$n4->def($def4);
ok($onto->has_term($n4) == 0);
$onto->delete_term($n4);
ok($onto->has_term($n4) == 0);
$onto->add_term($n4);
ok($onto->has_term($n4) == 1);

# new instance
my $in4 = OBO::Core::Instance->new();
$in4->id('APO:K0000004');
$in4->name('instance of Four');
ok($onto->has_instance($in4) == 0);
$onto->delete_instance($in4);
ok($onto->has_instance($in4) == 0);
$onto->add_instance($in4);
ok($onto->has_instance($in4) == 1);

# add term as string
my $new_term = $onto->add_term_as_string('APO:P0000005', 'Five');
$new_term->def_as_string('This is a dummy definition', '[APO:vm, APO:ls, APO:ea "Erick Antezana"]');
ok($onto->has_term($new_term) == 1);
ok($onto->get_term_by_id('APO:P0000005')->equals($new_term));
ok($onto->get_number_of_terms() == 5);
my $n5 = $new_term;

# add instance as string
my $new_instance = $onto->add_instance_as_string('APO:K0000005', 'instance of Five');
ok($onto->has_instance($new_instance) == 1);
ok($onto->get_instance_by_id('APO:K0000005')->equals($new_instance));
ok($onto->get_number_of_instances() == 5);
my $in5 = $new_instance;

# five new relationships
my $r12 = OBO::Core::Relationship->new();
my $r23 = OBO::Core::Relationship->new();
my $r13 = OBO::Core::Relationship->new();
my $r14 = OBO::Core::Relationship->new();
my $r35 = OBO::Core::Relationship->new();
my $r15 = OBO::Core::Relationship->new();

$r12->id('APO:P0000001_is_a_APO:P0000002');
$r23->id('APO:P0000002_part_of_APO:P0000003');
$r13->id('APO:P0000001_participates_in_APO:P0000003');
$r14->id('APO:P0000001_participates_in_APO:P0000004');
$r35->id('APO:P0000003_part_of_APO:P0000005');
$r15->id('APO:P0000001_RO:0000001_APO:P0000005');

$r12->type('is_a');
$r23->type('part_of');
$r13->type('participates_in');
$r14->type('participates_in');
$r35->type('part_of');
$r15->type('RO:0000001');

$r12->link($n1, $n2); 
$r23->link($n2, $n3);
$r13->link($n1, $n3);
$r14->link($n1, $n4);
$r35->link($n3, $n5);
$r15->link($n1, $n5);

# get all terms
my $c = 0;
my %h;
ok($onto->has_term_id('APO:P0000003'));
ok(!$onto->has_term_id('APO:P0000033'));
foreach my $t (@{$onto->get_terms()}) {
	if ($t->id() eq 'APO:P0000003'){
		ok($onto->has_term($t));
		$onto->set_term_id($t, 'APO:P0000033');
		ok($onto->has_term($t));
		$t = $onto->get_term_by_id('APO:P0000033');
	}
	
	$t->name('Uj') if ($t->id() eq 'APO:P0000001');

	$h{$t->id()} = $t;
	$c++;	
}
ok(!$onto->has_term_id('APO:P0000003'));
ok($onto->has_term_id('APO:P0000033'));

ok($onto->get_number_of_terms() == 5);
ok($c == 5);
ok($h{'APO:P0000001'}->name() eq 'Uj'); # The name has been changed above
ok($h{'APO:P0000002'}->name() eq 'Two');
ok($h{'APO:P0000033'}->name() eq 'Three'); # The ID has been changed above
ok($h{'APO:P0000004'}->name() eq 'Four');
ok($h{'APO:P0000005'}->name() eq 'Five');

# get all instances
my $ic = 0;
my %ih;
ok($onto->has_instance_id('APO:K0000003'));
ok(!$onto->has_instance_id('APO:K0000033'));
foreach my $t (@{$onto->get_instances()}) {
	if ($t->id() eq 'APO:K0000003'){
		ok($onto->has_instance($t));
		$onto->set_instance_id($t, 'APO:K0000033');
		ok($onto->has_instance($t));
		$t = $onto->get_instance_by_id('APO:K0000033');
	}
	
	$t->name('instance of Uj') if ($t->id() eq 'APO:K0000001');

	$ih{$t->id()} = $t;
	$ic++;	
}
ok(!$onto->has_instance_id('APO:K0000003'));
ok($onto->has_instance_id('APO:K0000033'));

ok($onto->get_number_of_instances() == 5);
ok($ic == 5);
ok($ih{'APO:K0000001'}->name() eq 'instance of Uj'); # The name has been changed above
ok($ih{'APO:K0000002'}->name() eq 'instance of Two');
ok($ih{'APO:K0000033'}->name() eq 'instance of Three'); # The ID has been changed above
ok($ih{'APO:K0000004'}->name() eq 'instance of Four');
ok($ih{'APO:K0000005'}->name() eq 'instance of Five');

# modifying a term id via the ontology
ok($onto->set_term_id($onto->get_term_by_id('APO:P0000033'), 'APO:P0000003')->id() eq 'APO:P0000003');
ok($onto->has_term_id('APO:P0000003'));
ok(!$onto->has_term_id('APO:P0000033'));
ok($onto->get_number_of_terms() == 5);

# modifying a instance id via the ontology
ok($onto->set_instance_id($onto->get_instance_by_id('APO:K0000033'), 'APO:K0000003')->id() eq 'APO:K0000003');
ok($onto->has_instance_id('APO:K0000003'));
ok(!$onto->has_instance_id('APO:K0000033'));
ok($onto->get_number_of_instances() == 5);

# get terms with argument
my @processes         = sort {$a->id() cmp $b->id()} @{$onto->get_terms("APO:P.*")};
my @sorted_processes  = @{$onto->get_terms_sorted_by_id("APO:P.*")};
my @sorted_processes2 = @{$onto->get_terms_sorted_by_id()};
ok($#processes == $#sorted_processes); # should be 5
for (my $i = 0; $i <= $#sorted_processes; $i++) {
	ok($processes[$i]->id() eq $sorted_processes[$i]->id());
	ok($processes[$i]->id() eq $sorted_processes2[$i]->id());
}
ok($#processes == 4);
ok($#sorted_processes2 == 4);

my @odd_processes        = sort {$a->id() cmp $b->id()} @{$onto->get_terms("APO:P000000[35]")};
my @sorted_odd_processes = @{$onto->get_terms_sorted_by_id("APO:P000000[35]")};
ok($#odd_processes == $#sorted_odd_processes); # should be 2
for (my $i = 0; $i <= $#sorted_odd_processes; $i++) {
	ok($odd_processes[$i]->id() eq $sorted_odd_processes[$i]->id());
}
ok($#odd_processes == 1);
ok($odd_processes[0]->id() eq 'APO:P0000003');
ok($odd_processes[1]->id() eq 'APO:P0000005');

# get instances with argument
my @iprocesses         = sort {$a->id() cmp $b->id()} @{$onto->get_instances("APO:K.*")};
my @isorted_processes  = @{$onto->get_instances_sorted_by_id("APO:K.*")};
my @isorted_processes2 = @{$onto->get_instances_sorted_by_id()};
ok($#iprocesses == $#isorted_processes); # should be 5
for (my $i = 0; $i <= $#isorted_processes; $i++) {
	ok($iprocesses[$i]->id() eq $isorted_processes[$i]->id());
	ok($iprocesses[$i]->id() eq $isorted_processes2[$i]->id());
}
ok($#iprocesses == 4);
ok($#isorted_processes2 == 4);

my @iodd_processes        = sort {$a->id() cmp $b->id()} @{$onto->get_instances("APO:K000000[35]")};
my @isorted_odd_processes = @{$onto->get_instances_sorted_by_id("APO:K000000[35]")};
ok($#iodd_processes == $#isorted_odd_processes); # should be 2
for (my $i = 0; $i <= $#isorted_odd_processes; $i++) {
	ok($iodd_processes[$i]->id() eq $isorted_odd_processes[$i]->id());
}
ok($#iodd_processes == 1);
ok($iodd_processes[0]->id() eq 'APO:K0000003');
ok($iodd_processes[1]->id() eq 'APO:K0000005');

# IDspace's
my $ids = $onto->idspaces();
ok($ids->is_empty() == 1);
my $id1 = OBO::Core::IDspace->new();
$id1->as_string('APO', 'http://www.cellcycle.org/ontology/APO', 'cell cycle ontology terms');
$onto->idspaces($id1);
ok(($onto->idspaces()->get_set())[0]->local_idspace() eq "APO");

my @same_processes = @{$onto->get_terms_by_subnamespace("P")};
ok(@same_processes == @processes);
my @no_processes = @{$onto->get_terms_by_subnamespace("p")};
ok($#no_processes == -1);

my @isame_processes = @{$onto->get_instances_by_subnamespace("K")};
ok(@same_processes == @iprocesses);
my @ino_processes = @{$onto->get_instances_by_subnamespace("k")};
ok($#no_processes == -1);

# get term and terms
ok($onto->get_term_by_id('APO:P0000001')->name() eq 'Uj');
ok($onto->get_term_by_name('Uj')->equals($n1));
$n1->synonym_as_string('Uno', '[APO:ls, APO:vm]', 'EXACT');
ok(($n1->synonym_as_string())[0] eq '"Uno" [APO:ls, APO:vm] EXACT');
$n1->synonym_as_string('One', '[APO:ls, APO:vm]', 'BROAD');
$n1->synonym_as_string('Een', '[APO:ab, APO:cd]', 'RELATED');

ok($onto->get_term_by_name_or_synonym('Uno')->equals($n1));            # needs to be EXACT
ok(!$onto->get_term_by_name_or_synonym('One'));                        # undef due to BROAD
ok($onto->get_term_by_name_or_synonym('One', 'ANY')->equals($n1));     # BROAD synonym
ok($onto->get_term_by_name_or_synonym('One', 'BROAD')->equals($n1));   # BROAD synonym
ok($onto->get_term_by_name_or_synonym('Een', 'RELATED')->equals($n1)); # RELATED synonym
ok(!$onto->get_term_by_name_or_synonym('Een', 'BROAD'));               # need to be RELATED
ok(!$onto->get_term_by_name_or_synonym('Een'));                        # need to be RELATED
ok($onto->get_term_by_name_or_synonym('Een', 'ANY')->equals($n1));     # RELATED synonym

ok($onto->get_term_by_name('Two')->equals($n2));
ok($onto->get_term_by_name('Three')->equals($n3));
ok($onto->get_term_by_name('Four')->equals($n4));

ok($onto->get_term_by_xref('GO', '0000001')->equals($n1));
ok($onto->get_term_by_xref('GO', '0000002')->equals($n2));
ok($onto->get_term_by_xref('GO', '0000003')->equals($n3));

ok($onto->get_terms_by_name('Uj')->contains($n1));
ok($onto->get_terms_by_name('Two')->contains($n2));
ok($onto->get_terms_by_name('Three')->contains($n3));
ok($onto->get_terms_by_name('Four')->contains($n4));
ok($onto->get_terms_by_name('T')->size() == 2); # 'Two' and 'Three'

# get instance and instances
ok($onto->get_instance_by_id('APO:K0000001')->name() eq 'instance of Uj');
ok($onto->get_instance_by_name('instance of Uj')->equals($in1));
$in1->synonym_as_string('instance of Uno', '[APO:ls, APO:vm]', 'EXACT');
ok(($in1->synonym_as_string())[0] eq '"instance of Uno" [APO:ls, APO:vm] EXACT');
$in1->synonym_as_string('instance of One', '[APO:ls, APO:vm]', 'BROAD');
$in1->synonym_as_string('instance of Een', '[APO:ab, APO:cd]', 'RELATED');

ok($onto->get_instance_by_name_or_synonym('instance of Uno')->equals($in1));            # needs to be EXACT
ok(!$onto->get_instance_by_name_or_synonym('instance of One'));                         # undef due to BROAD
ok($onto->get_instance_by_name_or_synonym('instance of One', 'ANY')->equals($in1));     # BROAD synonym
ok($onto->get_instance_by_name_or_synonym('instance of One', 'BROAD')->equals($in1));   # BROAD synonym
ok($onto->get_instance_by_name_or_synonym('instance of Een', 'RELATED')->equals($in1)); # RELATED synonym
ok(!$onto->get_instance_by_name_or_synonym('instance of Een', 'BROAD'));                # need to be RELATED
ok(!$onto->get_instance_by_name_or_synonym('instance of Een'));                         # need to be RELATED
ok($onto->get_instance_by_name_or_synonym('instance of Een', 'ANY')->equals($in1));     # RELATED synonym

ok($onto->get_instance_by_name('instance of Two')->equals($in2));
ok($onto->get_instance_by_name('instance of Three')->equals($in3));
ok($onto->get_instance_by_name('instance of Four')->equals($in4));

ok($onto->get_instance_by_xref('GO', '0000001')->equals($in1));
ok($onto->get_instance_by_xref('GO', '0000002')->equals($in2));
ok($onto->get_instance_by_xref('GO', '0000003')->equals($in3));

ok($onto->get_instances_by_name('instance of Uj')->contains($in1));
ok($onto->get_instances_by_name('instance of Two')->contains($in2));
ok($onto->get_instances_by_name('instance of Three')->contains($in3));
ok($onto->get_instances_by_name('instance of Four')->contains($in4));
ok($onto->get_instances_by_name('instance of T')->size() == 2); # 'Two' and 'Three'

# add relationships
$onto->add_relationship($r12);
ok($onto->get_relationship_by_id('APO:P0000001_is_a_APO:P0000002')->head()->id() eq 'APO:P0000002');
ok($onto->has_relationship_id('APO:P0000001_is_a_APO:P0000002'));

# delete a relationship
$onto->delete_relationship($r12);
ok(!$onto->has_relationship_id('APO:P0000001_is_a_APO:P0000002'));

# add back the just deleted relationship
$onto->add_relationship($r12);
ok($onto->get_relationship_by_id('APO:P0000001_is_a_APO:P0000002')->head()->id() eq 'APO:P0000002');
ok($onto->has_relationship_id('APO:P0000001_is_a_APO:P0000002'));

my @relas = @{$onto->get_relationships_by_target_term($onto->get_term_by_id('APO:P0000002'))};
ok($relas[0]->id()         eq 'APO:P0000001_is_a_APO:P0000002');
ok($relas[0]->tail()->id() eq 'APO:P0000001');
ok($relas[0]->head()->id() eq 'APO:P0000002');

$onto->add_relationship($r23);
$onto->add_relationship($r13);
$onto->add_relationship($r14);
$onto->add_relationship($r35);
$onto->add_relationship($r15);

ok($onto->has_relationship_id('APO:P0000001_RO:0000001_APO:P0000005'));

ok($onto->get_number_of_terms() == 5);
ok($onto->get_number_of_instances() == 5);
ok($onto->get_number_of_relationships() == 6);

# add relationships and terms linked by this relationship
my $n11 = OBO::Core::Term->new();
my $n21 = OBO::Core::Term->new();
$n11->id('APO:P0000011'); $n11->name('One one'); $n11->def_as_string('Definition One one', '');
$n21->id('APO:P0000021'); $n21->name('Two one'); $n21->def_as_string('Definition Two one', '');
my $r11_21 = OBO::Core::Relationship->new();
$r11_21->id('APO:L0001121'); $r11_21->type('r11-21');
$r11_21->link($n11, $n21);
$onto->add_relationship($r11_21); # adds to the ontology the terms linked by this relationship
$onto->get_relationship_type_by_id('r11-21')->name('r11-21');
ok($onto->get_number_of_terms() == 7);
ok($onto->get_number_of_relationships() == 7);

# add some instances
my $in11 = OBO::Core::Instance->new();
my $in21 = OBO::Core::Instance->new();
$in11->id('APO:K0000011'); $in11->name('instance of One one');
$in21->id('APO:K0000021'); $in21->name('instance of Two one');
$in11->instance_of($n11);
ok($in11->is_instance_of($n11));
ok($n11->is_class_of($in11));
$onto->add_instance($in11);
ok($onto->has_instance($in11) == 1);

$in21->instance_of($n21);
ok($in21->is_instance_of($n21));
ok($n21->is_class_of($in21));
$onto->add_instance($in21);
ok($onto->has_instance($in21) == 1);
ok($onto->get_number_of_instances() == 7);

# get all relationships
my %hr;
foreach my $r (@{$onto->get_relationships()}) {
	$hr{$r->id()} = $r;
}
ok($hr{'APO:P0000001_is_a_APO:P0000002'}->head()->equals($n2));
ok($hr{'APO:P0000002_part_of_APO:P0000003'}->head()->equals($n3));
ok($hr{'APO:P0000001_participates_in_APO:P0000003'}->head()->equals($n3));
ok($hr{'APO:P0000001_participates_in_APO:P0000004'}->head()->equals($n4));

# recover a previously stored relationship
ok($onto->get_relationship_by_id('APO:P0000001_participates_in_APO:P0000003')->equals($r13));
ok($onto->has_relationship_id('APO:P0000001_participates_in_APO:P0000003'));

# delete a relationship
$onto->delete_relationship($r13);
ok(!$onto->has_relationship_id('APO:P0000001_participates_in_APO:P0000003'));

# add back the just deleted relationship
$onto->add_relationship($r13);
ok($onto->get_relationship_by_id('APO:P0000001_participates_in_APO:P0000003')->head()->id() eq 'APO:P0000003');
ok($onto->has_relationship_id('APO:P0000001_participates_in_APO:P0000003'));

# get children
my @children = @{$onto->get_child_terms($n1)}; 
ok(scalar(@children) == 0);

@children = @{$onto->get_child_terms($n3)}; 
ok($#children == 1);
my %ct;
foreach my $child (@children) {
	$ct{$child->id()} = $child;
} 
ok($ct{'APO:P0000002'}->equals($n2));
ok($ct{'APO:P0000001'}->equals($n1));

@children = @{$onto->get_child_terms($n2)};
ok(scalar(@children) == 1);
ok($children[0]->id eq 'APO:P0000001');

# get parents
my @parents = @{$onto->get_parent_terms($n3)};
ok(scalar(@parents) == 1);
@parents = @{$onto->get_parent_terms($n1)};
ok(scalar(@parents) == 4);
@parents = @{$onto->get_parent_terms($n2)};
ok(scalar(@parents) == 1);
ok($parents[0]->id eq 'APO:P0000003');

# get all descendents
my @descendents1 = @{$onto->get_descendent_terms($n1)};
ok(scalar(@descendents1) == 0);
my @descendents2 = @{$onto->get_descendent_terms($n2)};
ok(scalar(@descendents2) == 1);
ok($descendents2[0]->id eq 'APO:P0000001');
my @descendents3 = @{$onto->get_descendent_terms($n3)};
ok(scalar(@descendents3) == 2);
my @descendents5 = @{$onto->get_descendent_terms($n5)};
ok(scalar(@descendents5) == 3);

# get descendents of a term (using its unique ID)
@descendents1 = @{$onto->get_descendent_terms('APO:P0000001')};
ok(scalar(@descendents1) == 0);
@descendents2 = @{$onto->get_descendent_terms('APO:P0000002')};
ok(scalar(@descendents2) == 1);
ok($descendents2[0]->id eq 'APO:P0000001');
@descendents3 = @{$onto->get_descendent_terms('APO:P0000003')};
ok(scalar(@descendents3) == 2);
@descendents5 = @{$onto->get_descendent_terms('APO:P0000005')};
ok(scalar(@descendents5) == 3);

# get all ancestors
my @ancestors1 = @{$onto->get_ancestor_terms($n1)};
ok(scalar(@ancestors1) == 4);
my @ancestors2 = @{$onto->get_ancestor_terms($n2)};
ok(scalar(@ancestors2) == 2);
ok($ancestors2[0]->id() eq 'APO:P0000003' || $ancestors2[0]->id() eq 'APO:P0000005');
ok($ancestors2[1]->id() eq 'APO:P0000003' || $ancestors2[1]->id() eq 'APO:P0000005');
my @ancestors3 = @{$onto->get_ancestor_terms($n3)};
ok(scalar(@ancestors3) == 1);

# get descendents by term subnamespace
@descendents1 = @{$onto->get_descendent_terms_by_subnamespace($n1, 'P')};
ok(scalar(@descendents1) == 0);
@descendents2 = @{$onto->get_descendent_terms_by_subnamespace($n2, 'P')}; 
ok(scalar(@descendents2) == 1);
ok($descendents2[0]->id eq 'APO:P0000001');
@descendents3 = @{$onto->get_descendent_terms_by_subnamespace($n3, 'P')};
ok(scalar(@descendents3) == 2);
@descendents3 = @{$onto->get_descendent_terms_by_subnamespace($n3, 'R')};
ok(scalar(@descendents3) == 0);

# get ancestors by term subnamespace
@ancestors1 = @{$onto->get_ancestor_terms_by_subnamespace($n1, 'P')};
ok(scalar(@ancestors1) == 4);
@ancestors2 = @{$onto->get_ancestor_terms_by_subnamespace($n2, 'P')}; 
ok(scalar(@ancestors2) == 2);
ok($ancestors2[0]->id() eq 'APO:P0000003' || $ancestors2[0]->id() eq 'APO:P0000005');
ok($ancestors2[1]->id() eq 'APO:P0000003' || $ancestors2[1]->id() eq 'APO:P0000005');
@ancestors3 = @{$onto->get_ancestor_terms_by_subnamespace($n3, 'P')};
ok(scalar(@ancestors3) == 1);
@ancestors3 = @{$onto->get_ancestor_terms_by_subnamespace($n3, 'R')};
ok(scalar(@ancestors3) == 0);


# three new relationships types
my $r1 = OBO::Core::RelationshipType->new();
my $r2 = OBO::Core::RelationshipType->new();
my $r3 = OBO::Core::RelationshipType->new();
my $r4 = OBO::Core::RelationshipType->new();

$r1->id('is_a');
$r2->id('part_of');
$r3->id('participates_in');
$r4->id('RO:0000001');

$r1->name('is a');
$r2->name('part_of');
$r3->name('participates_in');
$r4->name('prevents');

# the rel types were already added while adding the relationships (but they have no names, only ID's)
ok($onto->has_relationship_type_id('is_a'));
ok($onto->has_relationship_type_id('part_of'));
ok($onto->has_relationship_type_id('participates_in'));
ok($onto->has_relationship_type_id('RO:0000001'));

my @rts = @{$onto->get_relationship_types_sorted_by_id()};
my @r = ('RO:0000001', 'is_a', 'part_of', 'participates_in', 'r11-21');
foreach my $rt (@rts) {
	ok($rt->id() eq shift @r);
}

# add relationship types and test if they were added
ok($onto->get_number_of_relationship_types() == 5);
$onto->add_relationship_type($r1);
ok($onto->get_number_of_relationship_types() == 5);
ok($onto->has_relationship_type($r1));
ok($onto->has_relationship_type($onto->get_relationship_type_by_id('is_a')));
ok($onto->has_relationship_type($onto->get_relationship_type_by_name('is a')));
ok($onto->has_relationship_type_id('is_a'));
$onto->add_relationship_type($r2);
ok($onto->get_number_of_relationship_types() == 5);
ok($onto->has_relationship_type($r2));
ok($onto->has_relationship_type_id('part_of'));
$onto->add_relationship_type($r3);
ok($onto->get_number_of_relationship_types() == 5);
ok($onto->has_relationship_type($r3));
ok($onto->has_relationship_type_id('participates_in'));
ok($onto->get_number_of_relationship_types() == 5);
$onto->add_relationship_type($r4);
ok($onto->get_number_of_relationship_types() == 5);
ok($onto->has_relationship_type($r4));
ok($onto->has_relationship_type_id('RO:0000001'));
ok($onto->get_number_of_relationship_types() == 5);

ok($onto->get_relationship_types_by_name('participates_in')->contains($r3));
ok($onto->get_relationship_types_by_name('is a')->contains($r1));
ok(!$onto->get_relationship_types_by_name('is_a')->contains($r2));
ok($onto->get_relationship_types_by_name('part')->size() == 2);
ok($onto->get_relationship_types_by_name('part_')->size() == 1);
ok($onto->get_relationship_types_by_name('part')->contains($r2));
ok($onto->get_relationship_types_by_name('part')->contains($r3));
ok($onto->get_relationship_types_by_name('a')->size() == 3);

# get descendents or ancestors linked by a particular relationship type 
my $rel_type1 = $onto->get_relationship_type_by_name('is a');
my $rel_type2 = $onto->get_relationship_type_by_name('part_of');
my $rel_type3 = $onto->get_relationship_type_by_name('participates_in');

my @descendents7 = @{$onto->get_descendent_terms_by_relationship_type($n5, $rel_type1)};
ok(scalar(@descendents7) == 0); 
@descendents7 = @{$onto->get_descendent_terms_by_relationship_type($n5, $rel_type2)};
ok(scalar(@descendents7) == 2);
@descendents7 = @{$onto->get_descendent_terms_by_relationship_type($n2, $rel_type1)};
ok(scalar(@descendents7) == 1);
@descendents7 = @{$onto->get_descendent_terms_by_relationship_type($n3, $rel_type3)};
ok(scalar(@descendents7) == 1); 

my @ancestors7 = @{$onto->get_ancestor_terms_by_relationship_type($n1, $rel_type1)};
ok(scalar(@ancestors7) == 1); 
@ancestors7 = @{$onto->get_ancestor_terms_by_relationship_type($n1, $rel_type2)};
ok(scalar(@ancestors7) == 0);
@ancestors7 = @{$onto->get_ancestor_terms_by_relationship_type($n1, $rel_type3)};
ok(scalar(@ancestors7) == 2);
@ancestors7 = @{$onto->get_ancestor_terms_by_relationship_type($n2, $rel_type2)};
ok(scalar(@ancestors7) == 2); 

# add relationship type as string
my $relationship_type = $onto->add_relationship_type_as_string('has_participant', 'has_participant');
ok($onto->has_relationship_type($relationship_type) == 1);
ok($onto->get_relationship_type_by_id('has_participant')->equals($relationship_type));
ok($onto->get_number_of_relationship_types() == 6);

# get relationship types
my @rt  = @{$onto->get_relationship_types()};
my @srt = @{$onto->get_relationship_types_sorted_by_id()};
ok(scalar @rt == 6);
ok($#rt == $#srt);
my @RT = sort { $a->id() cmp $b->id() } @rt;
for (my $i = 0; $i<=$#srt; $i++) {
	ok($srt[$i]->name() eq $RT[$i]->name());
}

my %rrt;
foreach my $relt (@rt) {
	$rrt{$relt->name()} = $relt;
}
ok($rrt{'is a'}->name() eq 'is a');
ok($rrt{'part_of'}->name() eq 'part_of');
ok($rrt{'participates_in'}->name() eq 'participates_in');

ok($onto->get_relationship_type_by_id('is_a')->name() eq 'is a');
ok($onto->get_relationship_type_by_name('is a')->id() eq 'is_a');
ok($onto->get_relationship_type_by_name('part_of')->id() eq 'part_of');
ok($onto->get_relationship_type_by_name('participates_in')->id() eq 'participates_in');

# get_local_term_neighbourhood

my @nei = @{$onto->get_term_local_neighbourhood($n1)};
my %rtbsh;
foreach my $rel (@nei) {
	$rtbsh{$rel->type()} = $rel->type();
}
ok($rtbsh{'participates_in'} eq 'participates_in');
ok($rtbsh{'is_a'} eq 'is_a');

# get_relationships_by_(source|target)_term
my @rtbs = @{$onto->get_relationships_by_source_term($n1)};

%rtbsh = ();
foreach my $rel (@rtbs) {
	$rtbsh{$rel->type()} = $rel->type();
}
ok($rtbsh{'participates_in'} eq 'participates_in');
ok($rtbsh{'is_a'} eq 'is_a');

@rtbs = @{$onto->get_relationships_by_source_term($n1, 'is_a')};
%rtbsh = ();
foreach my $rel (@rtbs) {
	$rtbsh{$rel->type()} = $rel->type();
}
ok(!defined $rtbsh{'participates_in'});
ok($rtbsh{'is_a'} eq 'is_a');

my @rtbt = @{$onto->get_relationships_by_target_term($n3)};

my %rtbth;
foreach my $rel (@rtbt) {
	$rtbth{$rel->type()} = $rel->type();
}
ok($rtbth{'participates_in'} eq 'participates_in');
ok($rtbth{'part_of'} eq 'part_of');

@rtbt = @{$onto->get_relationships_by_target_term($n3, 'participates_in')};
foreach my $rel (@rtbt) {
	ok ($rel->id() eq 'APO:P0000001_participates_in_APO:P0000003');
}

# get_head_by_relationship_type
my @heads_n1 = @{$onto->get_head_by_relationship_type($n1, $onto->get_relationship_type_by_name("participates_in"))};
my %hbrt;
foreach my $head (@heads_n1) {
	$hbrt{$head->id()} = $head;
}
ok($hbrt{'APO:P0000003'}->equals($n3));
ok($hbrt{'APO:P0000004'}->equals($n4));
ok(@{$onto->get_head_by_relationship_type($n1, $onto->get_relationship_type_by_name('is a'))}[0]->equals($n2));

# get_tail_by_relationship_type
ok(@{$onto->get_tail_by_relationship_type($n3, $onto->get_relationship_type_by_name('participates_in'))}[0]->equals($n1));
ok(@{$onto->get_tail_by_relationship_type($n2, $onto->get_relationship_type_by_name('is a'))}[0]->equals($n1));

$onto->remarks('This is a test ontology');

# subontology_by_terms
my $terms = OBO::Util::TermSet->new();
$terms->add_all($n1, $n2, $n3);
my $so = $onto->subontology_by_terms($terms);
ok($so->get_number_of_terms() == 3);
ok($so->get_number_of_instances() == 3);
ok($so->has_term($n1));
ok($so->has_term($n2));
ok($so->has_term($n3));

ok($so->has_instance($in1));
ok($so->has_instance($in2));
ok($so->has_instance($in3));

$n1->name('mitotic cell cycle');
$n2->name('cell cycle process');
$n3->name('re-entry into mitotic cell cycle after pheromone arrest');

$in1->name('instance of mitotic cell cycle');
$in2->name('instance of cell cycle process');
$in3->name('instance of re-entry into mitotic cell cycle after pheromone arrest');

ok($onto->get_term_by_name('mitotic cell cycle')->equals($n1));
ok($onto->get_term_by_name('cell cycle process')->equals($n2));
ok($onto->get_term_by_name('re-entry into mitotic cell cycle after pheromone arrest')->equals($n3));

ok($onto->get_terms_by_name('mitotic cell cycle')->contains($n1));
ok($onto->get_terms_by_name('cell cycle process')->contains($n2));
ok($onto->get_terms_by_name('re-entry into mitotic cell cycle after pheromone arrest')->contains($n3));

ok($onto->get_terms_by_name('mitotic cell cycle')->size() == 2);
ok($onto->get_terms_by_name('mitotic cell cycle')->contains($n1));
ok($onto->get_terms_by_name('mitotic cell cycle')->contains($n3));

ok(($onto->get_terms_by_name('cell cycle process')->get_set())[0]->id() eq $n2->id());
ok(($onto->get_terms_by_name('re-entry into mitotic cell cycle after pheromone arrest')->get_set())[0]->id() eq $n3->id());

ok($onto->get_terms_by_name('cell cycle')->size() == 3);

$so->imports('o1', '02');
$so->date('11:03:2007 21:46');
$so->data_version('09:03:2007 19:30');

# More IDspace's tests
$ids = $onto->idspaces();
ok($ids->is_empty() == 0);
my $id2 = OBO::Core::IDspace->new();
my $id3 = OBO::Core::IDspace->new();

$id2->as_string('APO', 'http://www.cellcycle.org/ontology/APO', 'cell cycle ontology terms');
$id3->as_string('GO', 'urn:lsid:bioontology.org:GO:', 'gene ontology terms');
$so->idspaces($id2, $id3);

ok($onto->get_terms_idspace() eq 'APO');
ok($onto->get_terms_idspace() ne 'GO');
ok(!defined $onto->id());
$onto->id('APO');
ok($onto->get_terms_idspace() eq 'APO');
ok($onto->get_terms_idspace() ne 'GO');
ok($onto->id() eq 'APO');

my $idspaces = $so->idspaces();
ok($idspaces->size() == 2);

my @IDs = sort {$a->local_idspace() cmp $b->local_idspace()} ($so->idspaces()->get_set());
ok($IDs[0]->as_string() eq 'APO http://www.cellcycle.org/ontology/APO "cell cycle ontology terms"');
ok($IDs[1]->as_string() eq 'GO urn:lsid:bioontology.org:GO: "gene ontology terms"');

$so->remarks('1. This is a test ontology', '2. This is a second remark', '3. This is the last remark');
my @remarks = sort ($so->remarks()->get_set());
ok($remarks[0] eq '1. This is a test ontology');
ok($remarks[1] eq '2. This is a second remark');
ok($remarks[2] eq '3. This is the last remark');

my $ssd1 = OBO::Core::SubsetDef->new();
my $ssd2 = OBO::Core::SubsetDef->new();
$ssd1->as_string('Jukumari', 'Term used for jukumari');
$ssd2->as_string('Jukucha', 'Term used for jukucha');
$so->subset_def_map()->put('Jukumari', $ssd1);
$so->subset_def_map()->put('Jukucha', $ssd2);
ok($so->subset_def_map()->contains_key('Jukumari'));
ok($so->subset_def_map()->contains_key('Jukucha'));

my @ssd = sort {$a->name() cmp $b->name()} $so->subset_def_map()->values();
ok($ssd[0]->name() eq 'Jukucha');
ok($ssd[1]->name() eq 'Jukumari');
ok($ssd[0]->description() eq 'Term used for jukucha');
ok($ssd[1]->description() eq 'Term used for jukumari');

my $std1 = OBO::Core::SynonymTypeDef->new();
my $std2 = OBO::Core::SynonymTypeDef->new();
$std1->as_string('acronym', 'acronym', 'EXACT');
$std2->as_string('common_name', 'common name', 'EXACT');
$so->synonym_type_def_set($std1, $std2);

# subsets for a term
$n1->subset('Jukumari');
$n1->subset('Jukucha');

# subsets for an instance
$in1->subset('IJukumari');
$in1->subset('IJukucha');

# get_terms_by_subset
my @terms_by_ss = @{$so->get_terms_by_subset('Jukumari')};
ok($terms_by_ss[0]->name() eq 'mitotic cell cycle');
@terms_by_ss = @{$so->get_terms_by_subset('Jukucha')};
ok($terms_by_ss[0]->name() eq 'mitotic cell cycle');

my @instances_by_ss = @{$so->get_instances_by_subset('IJukumari')};
ok($instances_by_ss[0]->name() eq 'instance of mitotic cell cycle');
@instances_by_ss = @{$so->get_instances_by_subset('IJukucha')};
ok($instances_by_ss[0]->name() eq 'instance of mitotic cell cycle');

$n2->def_as_string('This is a dummy definition', '[APO:vm, APO:ls, APO:ea "Erick Antezana" {opt=first}]');
$n1->xref_set_as_string('APO:ea');
$n3->synonym_as_string('This is a dummy synonym definition', '[APO:vm, APO:ls, APO:ea "Erick Antezana" {opt=first}]', 'EXACT');
$n3->alt_id('APO:P0000033');
$n3->namespace('cellcycle');
$n3->is_obsolete('1');
$n3->union_of('GO:0001');
$n3->union_of('GO:0002');
$n2->intersection_of('GO:0003');
$n2->intersection_of('part_of GO:0004');
ok($onto->get_number_of_relationships() == 7);
$onto->create_rel($n4, 'part_of', $n5);
ok($onto->get_number_of_relationships() == 8);
ok(1);

# subontology tests and get_root tests
my $my_parser = OBO::Parser::OBOParser->new();
my $alpha_onto = $my_parser->work('./t/data/alpha.obo');

my $root  = $alpha_onto->get_term_by_id('MYO:0000000');
my @roots = @{$alpha_onto->get_root_terms()};
my %raices;
foreach my $r (@roots) {
	$raices{$r->id()} = $r;
}
my @raicillas = ('MYO:33820', 'MYO:0000000', 'MYO:0000050', 'MYO:0000557');
foreach my $rc (@raicillas) {
	ok ($alpha_onto->get_term_by_id($rc)->equals($raices{$rc}));
}

my $sub_o = $alpha_onto->get_subontology_from($root);
ok ($sub_o->get_number_of_terms() == 16);
@roots = @{$sub_o->get_root_terms()};
ok ($root->equals($roots[0])); # MYO:0000000

$root = $alpha_onto->get_term_by_id('MYO:0000002');
$sub_o = $alpha_onto->get_subontology_from($root);
ok ($sub_o->get_number_of_terms() == 9);
@roots = @{$sub_o->get_root_terms()};
ok ($root->equals($roots[0])); # MYO:0000002

$root = $alpha_onto->get_term_by_id('MYO:0000014');
$sub_o = $alpha_onto->get_subontology_from($root);
ok ($sub_o->get_number_of_terms() == 2);
@roots = @{$sub_o->get_root_terms()};
ok ($root->equals($roots[0])); # MYO:0000014

my $ole = $alpha_onto->get_term_by_id('MYO:1000008');
ok ($ole->def_as_string() eq '"" [src_code:NR]');

# get paths from term1 to term2
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
my $p = 'part_of';

my $o1  = OBO::Core::Ontology->new();
$o1->add_relationship_type_as_string($r, $r);
$o1->add_relationship_type_as_string($p, $p);

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

$o1->create_rel($d1,$p,$d20);
$o1->create_rel($d20,$p,$d25);
$o1->create_rel($d1,$p,$d25);

my @ref_paths = $o1->get_paths_term1_term2($d5->id(), $d26->id());
ok ($#ref_paths == 7);

my $concat_paths = '5_is_a_2->2_is_a_7->7_is_a_8->8_is_a_27->27_is_a_26->'.
					'5_is_a_2->2_is_a_6->6_is_a_20->20_part_of_25->25_is_a_26->'.
					'5_is_a_2->2_is_a_6->6_is_a_20->20_is_a_21->21_is_a_25->25_is_a_26->'.
					'5_is_a_2->2_is_a_1->1_is_a_8->8_is_a_27->27_is_a_26->'.
					'5_is_a_2->2_is_a_1->1_part_of_25->25_is_a_26->'.
					'5_is_a_2->2_is_a_1->1_part_of_20->20_part_of_25->25_is_a_26->'.
					'5_is_a_2->2_is_a_1->1_part_of_20->20_is_a_21->21_is_a_25->25_is_a_26->'.
					'5_is_a_2->2_is_a_1->1_is_a_10->10_is_a_24->24_is_a_25->25_is_a_26->';

foreach my $ref_path (@ref_paths) {
	
	my $pattern = '';
	foreach my $rp (@$ref_path) {
	
		my $entry_tail = $rp->tail();
		my $entry_type = $rp->type();
		my $entry_head = $rp->head();
	
		$pattern .= $entry_tail->id().'_'.$entry_type.'_'.$entry_head->id().'->';
		
	}
	ok (index($concat_paths, $pattern) != -1); # 8 tests to match paths from '5' to '26'
}

@ref_paths = $o1->get_paths_term1_term2($d5->id(), $d29->id());
ok ($#ref_paths == 0);

my @p = ('5_is_a_2', '2_is_a_7', '7_is_a_11', '11_is_a_28', '28_is_a_29');

foreach my $ref_path (@ref_paths) {
	foreach my $tt (@$ref_path) {
		ok ($tt->id() eq shift @p);
	}
}

my $empty_stop = OBO::Util::Set->new();
my $stop = OBO::Util::Set->new();
map {$stop->add($_->id())} @{$o1->get_terms()};

my @pref1a = $o1->get_paths_term_terms(undef, $stop);
ok ($#pref1a == -1);

my @pref1b = $o1->get_paths_term_terms($d5->id(), undef);
ok ($#pref1b == -1);

my @pref1c = $o1->get_paths_term_terms($d5->id(), $empty_stop);
ok ($#pref1c == -1);

my @pref1d = $o1->get_paths_term_terms(55555, $stop);
ok ($#pref1d == -1);

my @pref1e = $o1->get_paths_term_terms($d5->id(), $stop);
ok ($#pref1e == 33);

my @pref2 = $o1->get_paths_term_terms_same_rel($d5->id(), $stop, $r);
ok ($#pref2 == 22);

my @prefa = $o1->get_paths_term_terms_same_rel('', $stop, $r);
ok ($#prefa == -1);

my @prefb = $o1->get_paths_term_terms_same_rel(undef, $stop, $r);
ok ($#prefb == -1);

my @prefc = $o1->get_paths_term_terms_same_rel(55555, $stop, $r);
ok ($#prefc == -1);

my @prefd = $o1->get_paths_term_terms_same_rel($d5->id(), undef, $r);
ok ($#prefd == -1);

my @prefe = $o1->get_paths_term_terms_same_rel($d5->id(), $empty_stop, $r);
ok ($#prefe == -1);

my @preff = $o1->get_paths_term_terms_same_rel($d5->id(), $stop, undef);
ok ($#preff == -1);

my @prefg = $o1->get_paths_term_terms_same_rel($d5->id(), $stop, 'codes_for');
ok ($#prefg == -1);

my @pref3 = $o1->get_paths_term_terms_same_rel($d1->id(), $stop, $p);
ok ($#pref3 == 2); # 1_part_of_25; 1_part_of_20; 1_part_of_20 --> 20_part_of_25

# modifying a term id via the ontology
ok($o1->has_relationship_id('2_is_a_7'));
ok($o1->has_relationship_id('7_is_a_8'));
ok($o1->has_relationship_id('7_is_a_11'));
ok($o1->get_number_of_relationships() == 23);

ok(!$o1->has_relationship_id('2_is_a_77'));
ok(!$o1->has_relationship_id('77_is_a_8'));
ok(!$o1->has_relationship_id('77_is_a_11'));

$d7 = $o1->set_term_id($o1->get_term_by_id('7'), '77');
ok($d7->id() eq '77');

ok($o1->has_relationship_id('2_is_a_77'));
ok($o1->has_relationship_id('77_is_a_8'));
ok($o1->has_relationship_id('77_is_a_11'));
ok($o1->get_number_of_relationships() == 23);

ok(!$o1->has_relationship_id('2_is_a_7'));
ok(!$o1->has_relationship_id('7_is_a_8'));
ok(!$o1->has_relationship_id('7_is_a_11'));

# delete a term: 7
ok($o1->has_term($d7));
ok($o1->has_relationship_id('2_is_a_77'));
ok($o1->has_relationship_id('77_is_a_8'));
ok($o1->has_relationship_id('77_is_a_11'));
ok($o1->get_number_of_relationships() == 23);

$o1->delete_term($d7);

ok(!$o1->has_term($d7));
ok(!$o1->has_relationship_id('2_is_a_77'));
ok(!$o1->has_relationship_id('77_is_a_8'));
ok(!$o1->has_relationship_id('77_is_a_11'));
ok($o1->get_number_of_relationships() == 20);

ok (1);