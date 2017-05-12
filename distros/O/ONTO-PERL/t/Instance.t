# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Instance.t'

#########################

BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 84;
}

#########################

use OBO::Core::Instance;
use OBO::Core::Def;
use OBO::Core::Dbxref;
use OBO::Core::Relationship;
use OBO::Core::Synonym;
use OBO::Core::Term;
use OBO::Util::DbxrefSet;

use strict;

# three new instances
my $n1 = OBO::Core::Instance->new();
my $n2 = OBO::Core::Instance->new();
my $n3 = OBO::Core::Instance->new();
my $n4 = OBO::Core::Instance->new();

# name, subnamespace, code
ok($n1->idspace() eq 'NN');
ok($n1->subnamespace() eq 'X');
ok($n1->code() eq '0000000');

# id's
$n1->id('APO:Pa0000001');
ok($n1->id() eq 'APO:Pa0000001');
$n2->id('APO:P0000002');
ok($n2->id() eq 'APO:P0000002');
$n3->id('APO:P0000003');
ok($n3->id() eq 'APO:P0000003');

# name, subnamespace, code
ok($n1->idspace() eq 'APO');
ok($n1->subnamespace() eq 'Pa');
ok($n1->code() eq '0000001');

# instance creator + date
$n1->created_by('erick_antezana');
ok($n1->created_by() eq 'erick_antezana');
$n1->creation_date('2009-04-13T01:32:36Z ');
ok($n1->creation_date() eq '2009-04-13T01:32:36Z ');

# instance modificator + date
$n1->modified_by('erick_antezana');
ok($n1->modified_by() eq 'erick_antezana');
$n1->modification_date('2010-04-13T01:32:36Z');
ok($n1->modification_date() eq '2010-04-13T01:32:36Z');

# alt_id
$n1->alt_id('APO:P0000001_alt_id');
ok(($n1->alt_id()->get_set())[0] eq 'APO:P0000001_alt_id');
$n2->alt_id('APO:P0000002_alt_id1', 'APO:P0000002_alt_id2', 'APO:P0000002_alt_id3', 'APO:P0000002_alt_id4');
ok(($n2->alt_id()->get_set())[0] eq 'APO:P0000002_alt_id1');
ok(($n2->alt_id()->get_set())[1] eq 'APO:P0000002_alt_id2');
ok(($n2->alt_id()->get_set())[2] eq 'APO:P0000002_alt_id3');
ok(($n2->alt_id()->get_set())[3] eq 'APO:P0000002_alt_id4');
ok(!defined (($n3->alt_id()->get_set())[0]));
ok(!$n3->alt_id()->get_set());

# subset
$n1->subset('APO:P0000001_subset');
ok(($n1->subset())[0] eq 'APO:P0000001_subset');
$n2->subset('APO:P0000002_subset1', 'APO:P0000002_subset2', 'APO:P0000002_subset3', 'APO:P0000002_subset4');
ok(($n2->subset())[0] eq 'APO:P0000002_subset1');
ok(($n2->subset())[1] eq 'APO:P0000002_subset2');
ok(($n2->subset())[2] eq 'APO:P0000002_subset3');
ok(($n2->subset())[3] eq 'APO:P0000002_subset4');
ok(!defined (($n3->subset())[0]));
ok(!$n3->subset());

# name
$n1->name('One');
ok($n1->name() eq 'One');
$n2->name('Two');
ok($n2->name() eq 'Two');
$n3->name('Three');
ok($n3->name() eq 'Three');

ok($n1->is_obsolete() == 0); # not defined value.
$n1->is_obsolete(1);
ok($n1->is_obsolete() != 0);
ok($n1->is_obsolete() == 1);
$n1->is_obsolete(0);
ok($n1->is_obsolete() == 0);
ok($n1->is_obsolete() != 1);

ok($n1->is_anonymous() == 0); # not defined value.
$n1->is_anonymous(1);
ok($n1->is_anonymous() != 0);
ok($n1->is_anonymous() == 1);
$n1->is_anonymous(0);
ok($n1->is_anonymous() == 0);
ok($n1->is_anonymous() != 1);

# synonyms
my $syn1 = OBO::Core::Synonym->new();
$syn1->scope('EXACT');
my $def1 = OBO::Core::Def->new();
$def1->text('Hola mundo1');
my $sref1 = OBO::Core::Dbxref->new();
$sref1->name('APO:vm');
my $srefs_set1 = OBO::Util::DbxrefSet->new();
$srefs_set1->add($sref1);
$def1->dbxref_set($srefs_set1);
$syn1->def($def1);
$n1->synonym_set($syn1);

my $syn2 = OBO::Core::Synonym->new();
$syn2->scope('BROAD');
my $def2 = OBO::Core::Def->new();
$def2->text('Hola mundo2');
my $sref2 = OBO::Core::Dbxref->new();
$sref2->name('APO:ls');
$srefs_set1->add_all($sref1);
my $srefs_set2 = OBO::Util::DbxrefSet->new();
$srefs_set2->add_all($sref1, $sref2);
$def2->dbxref_set($srefs_set2);
$syn2->def($def2);
$n2->synonym_set($syn2);

ok(!defined (($n3->synonym_set())[0]));
ok(!$n3->synonym_set());

my $syn3 = OBO::Core::Synonym->new();
$syn3->scope('BROAD');
my $def3 = OBO::Core::Def->new();
$def3->text('Hola mundo2');
my $sref3 = OBO::Core::Dbxref->new();
$sref3->name('APO:ls');
my $srefs_set3 = OBO::Util::DbxrefSet->new();
$srefs_set3->add_all($sref1, $sref2);
$def3->dbxref_set($srefs_set3);
$syn3->def($def3);
$n3->synonym_set($syn3);

ok(($n1->synonym_set())[0]->equals($syn1));
ok(($n2->synonym_set())[0]->equals($syn2));
ok(($n3->synonym_set())[0]->equals($syn3));
ok(($n2->synonym_set())[0]->scope() eq 'BROAD');
ok(($n2->synonym_set())[0]->def()->equals(($n3->synonym_set())[0]->def()));
ok(($n2->synonym_set())[0]->equals(($n3->synonym_set())[0]));

# synonym as string
ok(($n2->synonym_as_string())[0] eq '"Hola mundo2" [APO:ls, APO:vm] BROAD');
$n2->synonym_as_string('Hello world2', '[APO:vm2, APO:ls2]', 'EXACT');
ok(($n2->synonym_as_string())[0] eq '"Hello world2" [APO:ls2, APO:vm2] EXACT');
ok(($n2->synonym_as_string())[1] eq '"Hola mundo2" [APO:ls, APO:vm] BROAD');
ok(scalar $n2->synonym_set() == 2);

# updating the scope ans synonym type name of a synonym
$n2->synonym_as_string('Hello world2', '[APO:vm2, APO:ls2]', 'RELATED');
ok(scalar $n2->synonym_set() == 2);
ok(($n2->synonym_as_string())[0] eq '"Hello world2" [APO:ls2, APO:vm2] RELATED');
$n2->synonym_as_string('Hello world2', '[APO:vm2, APO:ls2]', 'BROAD');
ok(scalar $n2->synonym_set() == 2);
ok(($n2->synonym_as_string())[0] eq '"Hello world2" [APO:ls2, APO:vm2] BROAD');
$n2->synonym_as_string('Hello world2', '[APO:vm2, APO:ls2]', 'NARROW', 'UK_SPELLING');
ok(scalar $n2->synonym_set() == 2);
ok(($n2->synonym_as_string())[0] eq '"Hello world2" [APO:ls2, APO:vm2] NARROW UK_SPELLING');
ok(($n2->synonym_as_string())[1] eq '"Hola mundo2" [APO:ls, APO:vm] BROAD');

# xref
my $xref1 = OBO::Core::Dbxref->new();
my $xref2 = OBO::Core::Dbxref->new();
my $xref3 = OBO::Core::Dbxref->new();
my $xref4 = OBO::Core::Dbxref->new();
my $xref5 = OBO::Core::Dbxref->new();

$xref1->name('XAPO:vm');
$xref2->name('XAPO:ls');
$xref3->name('XAPO:ea');
$xref4->name('XAPO:vm');
$xref5->name('XAPO:ls');

my $xrefs_set = OBO::Util::DbxrefSet->new();
$xrefs_set->add_all($xref1, $xref2, $xref3, $xref4, $xref5);
$n1->xref_set($xrefs_set);
ok($n1->xref_set()->contains($xref3));
my $xref_length = $n1->xref_set()->size();
ok($xref_length == 3);

# xref_set_as_string
my @empty_refs = $n2->xref_set_as_string();
ok($#empty_refs == -1);
$n2->xref_set_as_string('[YAPO:vm, YAPO:ls, YAPO:ea "Erick Antezana" {opt=first}]');
my @xrefs_n2 = $n2->xref_set()->get_set();
my %xr_n2;
foreach my $xref_n2 (@xrefs_n2) {
	$xr_n2{$xref_n2->name()} = $xref_n2->name();
}
ok($xr_n2{'YAPO:vm'} eq 'YAPO:vm');
ok($xr_n2{'YAPO:ls'} eq 'YAPO:ls');
ok($xr_n2{'YAPO:ea'} eq 'YAPO:ea');

# property_value
my $rel = OBO::Core::Relationship->new();
$rel->id('APO:10000000');
$rel->type('acts_on');
$n1->property_value($rel);
ok(($n1->property_value()->get_set())[0]->id() eq 'APO:10000000');

# disjoint_from
$n2->disjoint_from($n1->id(), $n3->id());
my @dis = sort {$a cmp $b} $n2->disjoint_from();
ok($#dis == 1);
ok($dis[0] eq $n3->id());
ok($dis[1] eq $n1->id());

# instance_of
my $C1 = OBO::Core::Term->new();
my $C2 = OBO::Core::Term->new();
my $C3 = OBO::Core::Term->new();
$C1->id('MYO:0000001'); $C1->name('class1');
$C2->id('MYO:0000002'); $C2->name('class2');
$C3->id('MYO:0000003'); $C3->name('class3');

my $i1 = OBO::Core::Instance->new();
my $i2 = OBO::Core::Instance->new();
my $i3 = OBO::Core::Instance->new();
my $i4 = OBO::Core::Instance->new();

$i1->id('MYO:K0000001');
$i2->id('MYO:K0000002');
$i3->id('MYO:K0000003');
$i4->id('MYO:K0000004');

# is_instance_of
ok(!$i1->is_instance_of($C1));
ok(!$i2->is_instance_of($C2));
ok(!$i3->is_instance_of($C3));
ok(!$i4->is_instance_of($C3));

$i1->instance_of($C1);
$i2->instance_of($C2);
$i3->instance_of($C3);
$i4->instance_of($C3);

# is_instance_of
ok($i1->is_instance_of($C1));
ok($i2->is_instance_of($C2));
ok($i3->is_instance_of($C3));
ok($i4->is_instance_of($C3));

ok($i1->instance_of()->id() eq $C1->id());
ok($i2->instance_of()->id() eq $C2->id());
ok($i3->instance_of()->id() eq $C3->id());
ok($i4->instance_of()->id() eq $C3->id());

# class_of (terms are aware of their instances!)
my @instances = sort {$a->id() cmp $b->id()} $C3->class_of()->get_set();
my $i = 3;
foreach my $in (@instances) {
	ok($in->id() eq 'MYO:K000000'.$i++);
}

ok(1);