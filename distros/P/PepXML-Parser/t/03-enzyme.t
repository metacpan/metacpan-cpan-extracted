#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use lib "lib";
use PepXML::Parser;

plan tests => 4;

my $p = PepXML::Parser->new();
 
my $pepxmlfile = $p->parse("t/small.sample.pep.xml");

my @enzymes = $pepxmlfile ->get_enzymes;

cmp_ok( $enzymes[0]->name, 'eq', "Trypsin" );
cmp_ok( $enzymes[0]->cut, 'eq', "KR" );
cmp_ok( $enzymes[0]->no_cut, 'eq', "P" );
cmp_ok( $enzymes[0]->sense, 'eq', "C" );
