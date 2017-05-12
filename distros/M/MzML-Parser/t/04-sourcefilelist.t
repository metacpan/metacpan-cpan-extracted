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

cmp_ok( $res->fileDescription->sourceFileList->sourceFile->[0]->cvParam->[0]->accession , 'eq', "MS:1000768", "sourcefile cvparam accession" );

cmp_ok( $res->fileDescription->sourceFileList->sourceFile->[0]->cvParam->[0]->cvRef, 'eq', "MS", "sourcefile cvref accession" );

cmp_ok( $res->fileDescription->sourceFileList->sourceFile->[0]->cvParam->[0]->name, 'eq', "Thermo nativeID format", "sourcefile cvref name" );



