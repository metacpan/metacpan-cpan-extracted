#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib 'lib';
use MzML::Parser;

plan tests => 3;

my $p = MzML::Parser->new();
my $res = $p->parse("t/miape_sample.mzML");

cmp_ok( $res->instrumentConfigurationList->instrumentConfiguration->[0]->id , 'eq', "IC1", "instrument config." );

cmp_ok( $res->instrumentConfigurationList->instrumentConfiguration->[0]->softwareRef->ref , 'eq', "Xcalibur", "software reference" );

cmp_ok( $res->instrumentConfigurationList->instrumentConfiguration->[0]->componentList->source->order, '==', '1', "componentlist order");

