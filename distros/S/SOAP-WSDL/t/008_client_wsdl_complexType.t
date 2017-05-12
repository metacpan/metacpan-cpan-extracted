#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More qw/no_plan/; # TODO: change to tests => N;
use lib '../lib';
use File::Basename;
use File::Spec;

my $path = File::Spec->rel2abs( dirname __FILE__ );
my ($volume, $dir) = File::Spec->splitpath($path, 1);
my @dir_from = File::Spec->splitdir($dir);
unshift @dir_from, $volume if $volume;
my $url = join '/', @dir_from;

use_ok(qw/SOAP::WSDL/);

my $soap = SOAP::WSDL->new(
    wsdl => 'file://' . $url .'/acceptance/wsdl/008_complexType.wsdl'
)->wsdlinit();

my $wsdl = $soap->get_definitions;
my $schema = $wsdl->first_types();
my $type = $schema->find_type('Test' , 'testComplexTypeAll');
my $element = $type->get_element()->[0];

is $element->get_minOccurs() , 0, "minOccurs default for all";
is $element->get_maxOccurs() , 1, "maxOccurs default for all";

$type = $schema->find_type('Test' , 'testComplexTypeSequence');
$element = $type->get_element()->[0];

is $element->get_minOccurs() , 1, "minOccurs default for sequence";
is $element->get_maxOccurs() , 1, "maxOccurs default for sequence";
