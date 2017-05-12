#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib 'lib';
use MzML::Parser;

plan tests => 3;

my $p = MzML::Parser->new();
my $res = $p->parse("t/sample.mzML");

cmp_ok( $res->fileDescription->fileContent->cvParam->accession, 'eq', "MS:1000580", "cvparam accession" );

cmp_ok( $res->fileDescription->fileContent->cvParam->cvRef, 'eq', "MS", "cvparam cvref" );

cmp_ok( $res->fileDescription->fileContent->cvParam->name, 'eq', "MSn spectrum", "cvparam name" );
