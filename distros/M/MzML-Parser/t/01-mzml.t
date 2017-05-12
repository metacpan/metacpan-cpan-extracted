#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib 'lib';
use MzML::Parser;

plan tests => 2;

my $p = MzML::Parser->new();

my $res = $p->parse("t/mzml.xml");

cmp_ok( $res->mzML->version, 'eq', "1.0", "mzml version" );
cmp_ok( $res->mzML->id, 'eq', "urn:lsid:psidev.info:mzML.instanceDocuments.tiny.pwiz", "mzml id" );
