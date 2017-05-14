#!/usr/bin/perl
# $Id$
package t::Test;
use NexposeSimpleXML::Parser;
use NexposeSimpleXML::Parser::Session;
use NexposeSimpleXML::Parser::Host;
use NexposeSimpleXML::Parser::Host::Service;
use NexposeSimpleXML::Parser::Fingerprint;
use NexposeSimpleXML::Parser::Vulnerability;
use NexposeSimpleXML::Parser::Reference;

use base 'Test::Class';
use Test::More;

sub setup : Test(setup => no_plan) {
    my ($self) = @_;

    if ( -r 't/test1.xml') {
        $self->{parser1} =  NexposeSimpleXML::Parser->parse_file('t/test1.xml');
    }
}
1;
