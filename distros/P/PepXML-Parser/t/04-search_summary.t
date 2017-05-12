#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use lib "lib";
use PepXML::Parser;

plan tests => 4;

my $p = PepXML::Parser->new();
 
my $pepxml	 = $p->parse("t/small.sample.pep.xml");

my $s = $pepxml->get_search_summary();

my @mods = $pepxml->get_modifications();

my @params = $pepxml->get_parameters();

my $size = scalar(@params);

cmp_ok( $s->search_engine, 'eq', "Comet" );
cmp_ok( $mods[0]->aminoacid, 'eq', "M" );
cmp_ok( $mods[0]->mass, 'eq', "147.035385" );
cmp_ok( $size, '==', "94" );
