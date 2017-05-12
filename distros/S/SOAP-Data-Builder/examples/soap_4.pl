#!/usr/bin/perl -w

use strict;
use SOAP::Lite;
use SOAP::Data::Builder;
use Data::Dumper;

my $soap_data_builder = SOAP::Data::Builder->new();

$soap_data_builder->add_elem(name => 'first');

$soap_data_builder->add_elem(name=>'second',
    parent=>$soap_data_builder->get_elem('first'));

$soap_data_builder->add_elem(name=>'third',
    parent=>$soap_data_builder->get_elem('first/second'));

$soap_data_builder->add_elem(name=>'fourth',
    value=>"something",
    parent=>$soap_data_builder->get_elem('first/second/third'));

my $data =  SOAP::Data->name('soap:env' => \SOAP::Data->value(
$soap_data_builder->to_soap_data ));

my $serialized_xml = SOAP::Serializer->autotype(0)->serialize( $data );

print $serialized_xml;

