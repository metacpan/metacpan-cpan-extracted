#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib 'lib';
use MzML::Parser;

plan tests => 2;

my $p = MzML::Parser->new();
my $res = $p->parse("t/miape_sample.mzML");

cmp_ok( $res->dataProcessingList->count, '==', "2", "dataprocessing count" );

cmp_ok( $res->dataProcessingList->dataProcessing->[0]->id, 'eq', "MIAPE_example", "dataprocessing method id");

