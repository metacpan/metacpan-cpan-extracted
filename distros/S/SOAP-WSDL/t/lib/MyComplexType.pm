#!/usr/bin/perl
package MyComplexType;
use strict;
use Class::Std::Fast::Storable constructor => 'none';
use lib '../../lib';
use base ('SOAP::WSDL::XSD::Typelib::ComplexType');

Class::Std::initialize();

my %MyTestName_of :ATTR(:get<MyTestName>);

__PACKAGE__->_factory(
    [ qw(MyTestName) ],                # order
    { MyTestName => \%MyTestName_of },  # attribute lookup map
    { MyTestName => 'SOAP::WSDL::XSD::Typelib::Builtin::string' }       # class name lookup map
);

sub get_xmlns { 'urn:Test' };

1;
