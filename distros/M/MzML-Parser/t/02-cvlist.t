#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib 'lib';
use MzML::Parser;

plan tests => 3;

my $p = MzML::Parser->new();

my $res = $p->parse("t/mzml.xml");

cmp_ok( $res->cvlist->count, '==', '2', "cvlist count" );
cmp_ok( $res->cvlist->cv->[0]->id, 'eq', "MS", "cv id");
cmp_ok( $res->cvlist->cv->[0]->fullName, 'eq', "Proteomics Standards Initiative Mass Spectrometry Ontology", "cv fullName");
