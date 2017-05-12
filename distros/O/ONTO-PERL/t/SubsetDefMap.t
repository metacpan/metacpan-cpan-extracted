# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Map.t'

#########################

BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 63;
}

#########################

use OBO::Core::SubsetDef;
use OBO::Util::SubsetDefMap;
use strict;

my $my_map = OBO::Util::SubsetDefMap->new();
my $my_ssd = OBO::Core::SubsetDef->new();
ok(1);

$my_ssd->as_string('GO_SS', 'Term used for My GO');
ok(!$my_map->contains_key('GO_SS'));
ok(!$my_map->contains_value($my_ssd));
ok($my_map->size() == 0);
ok($my_map->is_empty());

# put: key=string, value=subset_def
$my_map->put('GO_SS', $my_ssd);

my @my_ssd = $my_map->values();
ok($my_ssd[0]->name() eq 'GO_SS');
ok($my_ssd[0]->description() eq 'Term used for My GO');

ok($my_map->contains_key('GO_SS'));
ok($my_map->contains_value($my_ssd));
ok($my_map->size() == 1);
ok(!$my_map->is_empty());

my $my_ssd1 = OBO::Core::SubsetDef->new();
my $my_ssd2 = OBO::Core::SubsetDef->new();
my $my_ssd3 = OBO::Core::SubsetDef->new();

$my_ssd1->as_string('APO', 'Application Ontology');
$my_ssd2->as_string('PO', 'Plant Ontology');
$my_ssd3->as_string('SO', 'Sequence Ontology');

my $another_map = OBO::Util::SubsetDefMap->new();
$another_map->put('APO', $my_ssd1);
$another_map->put('PO', $my_ssd2);
$another_map->put('SO', $my_ssd3);
ok($another_map->size() == 3);

$my_map->put_all($another_map);
ok($my_map->size() == 4);

ok($my_map->equals($my_map));
ok($another_map->equals($another_map));
ok(!$my_map->equals($another_map));
ok(!$another_map->equals($my_map));

$another_map->put('GO_SS', $my_ssd);
ok($another_map->size() == 4);

ok($another_map->equals($another_map));
ok($my_map->equals($another_map));
ok($another_map->equals($my_map));

my $my_map2 = OBO::Util::SubsetDefMap->new();

ok(!$my_map->equals($my_map2));
ok(!$my_map2->equals($my_map));

$my_map2->put('APO', $my_ssd1);
$my_map2->put('PO', $my_ssd2);
$my_map2->put('SO', $my_ssd3);

ok(!$my_map2->equals($my_map));
ok(!$my_map->equals($my_map2));

$my_map2->put('GO_SS', $my_ssd);
ok($my_map2->equals($my_map));
ok($my_map->equals($my_map2));

ok($my_map2->get('GO_SS')->equals($my_ssd));
ok($my_map2->get('APO')->equals($my_ssd1));
ok($my_map2->get('PO')->equals($my_ssd2));
ok($my_map2->get('SO')->equals($my_ssd3));

my $i = 0;
my @values = sort {lc($a->name()) cmp lc($b->name())} $my_map->values();
foreach my $subsetdef (sort {lc($a->name()) cmp lc($b->name())} $my_map2->values()) {
	ok($subsetdef->name() eq $values[$i]->name());
	ok($subsetdef->description() eq $values[$i++]->description());
}

my $my_ssd4 = OBO::Core::SubsetDef->new();
$my_ssd4->as_string('TO', 'Trait Ontology');
$my_map2->put('TO', $my_ssd4);

ok(!$my_map->equals($my_map2));
ok(!$my_map2->equals($my_map));
ok($my_map2->size() == 5);

$my_map->clear();
ok($my_map->size() == 0);

$my_map->put_all($my_map2);
ok($my_map->equals($my_map2));
ok($my_map2->equals($my_map));
ok($my_map->size() == 5);

my $UD = $my_map->remove('XO');
ok(!defined $UD);

ok($my_map->contains_key('GO_SS'));
ok($my_map->contains_value($my_ssd));

my $GO = $my_map->remove('GO');
ok(!defined $GO);

my $GO_SS = $my_map->remove('GO_SS');
ok(!$my_map->contains_key('GO_SS'));
ok(!$my_map->contains_value($my_ssd));
ok($GO_SS->equals($my_ssd));

ok($my_map->size() == 4);
ok($my_map->contains_value($my_ssd1));
my $APO = $my_map->remove('APO');
ok(!$my_map->contains_key('APO'));
ok(!$my_map->contains_value($my_ssd1));

ok($APO->equals($my_ssd1));
ok($my_map->size() == 3);
$my_map->remove('PO');
ok($my_map->size() == 2);
$my_map->remove('SO');
ok($my_map->size() == 1);
$my_map->remove('TO');
ok($my_map->size() == 0);

ok(1);
