#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib 'lib';
use MzML::Parser;

plan tests => 5;

my $p = MzML::Parser->new();
my $res = $p->parse("t/sample.mzML");

cmp_ok( $res->referenceableParamGroupList->referenceableParamGroup->[0]->id , 'eq', "CommonInstrumentParams", "refgrouplist group id" );

cmp_ok( $res->referenceableParamGroupList->referenceableParamGroup->[0]->cvParam->[0]->accession , 'eq', "MS:1000448", "refgrouplist cvparam accession" );

cmp_ok( $res->referenceableParamGroupList->referenceableParamGroup->[0]->cvParam->[0]->cvRef , 'eq', "MS", "refgrouplist cvparam cvref" );

cmp_ok( $res->referenceableParamGroupList->referenceableParamGroup->[0]->cvParam->[0]->name , 'eq', "LTQ FT", "refgrouplist cvparam name" );

cmp_ok( $res->referenceableParamGroupList->referenceableParamGroup->[0]->cvParam->[0]->value , 'eq', "", "refgrouplist cvparam value" );

