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

cmp_ok( $res->sampleList->sample->[0]->id , 'eq', "sample1", "sample id" );

cmp_ok( $res->sampleList->sample->[0]->name , 'eq', "Sample 1", "sample name" );
