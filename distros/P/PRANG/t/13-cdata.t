#!/usr/bin/perl

use Test::More no_plan;
use strict;
use warnings;
use XML::LibXML;

{

    package Sins;

    use Moose;
    use PRANG::Graph;    
    
    sub root_element {'Sins'};
    sub xmlns {};

    has_element "envy" =>
        is => "ro",
        isa => "Str",
        xml_nodeName => "Envy",
        ;
        
    with qw/PRANG::Graph/;
}

my @tests = (
    {
        desc => "XML with CDATA",
        xml => qq|
          <Sins>
            <Envy><![CDATA[envious]]></Envy>
          </Sins>
        |,
        emit_cdata => 1,
                
    },
    {
        desc => "XML without CDATA",
        xml => qq|
          <Sins>
            <Envy>envious</Envy>
          </Sins>
        |,
        emit_cdata => 0,
    },
);

foreach my $test (@tests) {
    
    my $parser = XML::LibXML->new;
    $parser->keep_blanks(0);
    
    $PRANG::EMIT_CDATA = $test->{emit_cdata};
    
    my $doc1 = $parser->parse_string($test->{xml});
    
    my $sins = Sins->from_dom($doc1);
    
    is($sins->envy, 'envious', $test->{desc} . " - Text node populated correctly");
    
    my $doc2 = $parser->parse_string($sins->to_xml);
    my $envy_element = $doc2->firstChild->firstChild;
    my $text_node = $envy_element->firstChild;
    
    my $expected_node_type = $test->{emit_cdata} ? XML_CDATA_SECTION_NODE : XML_TEXT_NODE;
    
    is($text_node->nodeType, $expected_node_type, $test->{desc} . "Text node is of correct type");
    is($text_node->data, 'envious', $test->{desc} . "Text node has correct value");
    
}

# Copyright (C) 2009, 2010  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Artistic License 2.0 for more details.
#
# You should have received a copy of the Artistic License the file
# COPYING.txt.  If not, see
# <http://www.perlfoundation.org/artistic_license_2_0>
