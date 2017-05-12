#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use lib "lib";
use PepXML::Parser;

plan tests => 3;

my $p = PepXML::Parser->new();

my $pepxml	 = $p->parse("t/sample.pep.xml");


cmp_ok( $pepxml->search_hit->[0]->assumed_charge, '==', "2" );
cmp_ok( $pepxml->search_hit->[0]->peptide, 'eq', "HGDSVR" );
cmp_ok( $pepxml->search_hit->[0]->search_score->{'deltacn'}, '==', "0.218" );
