# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Map.t'

#########################

BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 47;
}

#########################

use OBO::Util::Map;
use strict;

my $my_map = OBO::Util::Map->new();
ok(1);

ok(!$my_map->contains_key('GO'));
ok(!$my_map->contains_value('Gene Ontology'));
ok($my_map->size() == 0);
ok($my_map->is_empty());

$my_map->put('GO', 'Gene Ontology');
ok($my_map->contains_key('GO'));
ok($my_map->contains_value('Gene Ontology'));
ok($my_map->size() == 1);
ok(!$my_map->is_empty());

$my_map->put('APO', 'Application Ontology');
$my_map->put('PO', 'Plant Ontology');
$my_map->put('SO', 'Sequence Ontology');
ok($my_map->size() == 4);

ok($my_map->equals($my_map));

my $my_map2 = OBO::Util::Map->new();
ok(!$my_map->equals($my_map2));
ok(!$my_map2->equals($my_map));
$my_map2->put('APO', 'Application Ontology');
$my_map2->put('PO', 'Plant Ontology');
$my_map2->put('SO', 'Sequence Ontology');
ok(!$my_map2->equals($my_map));
ok(!$my_map->equals($my_map2));

$my_map2->put('GO', 'Gene Ontology');
ok($my_map2->equals($my_map));
ok($my_map->equals($my_map2));

ok($my_map2->get('GO') eq 'Gene Ontology');
ok($my_map2->get('APO') eq 'Application Ontology');
ok($my_map2->get('PO') eq 'Plant Ontology');
ok($my_map2->get('SO') eq 'Sequence Ontology');

my @values = sort {lc($a) cmp lc($b)} $my_map2->values();
ok($values[0] eq 'Application Ontology');
ok($values[1] eq 'Gene Ontology');
ok($values[2] eq 'Plant Ontology');
ok($values[3] eq 'Sequence Ontology');

$my_map2->put('TO', 'Trait Ontology');
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
ok($my_map->contains_key('GO'));
ok($my_map->contains_value('Gene Ontology'));
my $GO = $my_map->remove('GO');
ok(!$my_map->contains_key('GO'));
ok(!$my_map->contains_value('Gene Ontology'));
ok($GO eq 'Gene Ontology');
ok($my_map->size() == 4);
my $APO = $my_map->remove('APO');
ok(!$my_map->contains_key('APO'));
ok(!$my_map->contains_value('Application Ontology'));
ok($APO eq 'Application Ontology');
ok($my_map->size() == 3);
$my_map->remove('PO');
ok($my_map->size() == 2);
$my_map->remove('SO');
ok($my_map->size() == 1);
$my_map->remove('TO');
ok($my_map->size() == 0);

ok(1);
