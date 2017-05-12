#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use lib "lib";
use PepXML::Parser;

plan tests => 5;

my $p = PepXML::Parser->new();
 
my $pepxmlfile = $p->parse("t/small.sample.pep.xml");

my $obj = $pepxmlfile->get_run_summary;

cmp_ok( $obj->base_name, 'eq', "Sample" );
cmp_ok( $obj->msManufacturer, 'eq', "Thermo Scientific" );
cmp_ok( $obj->msModel, 'eq', "LTQ Orbitrap Elite" );
cmp_ok( $obj->raw_data_type, 'eq', "raw" );
cmp_ok( $obj->raw_data, 'eq', ".mzXML" );