use strict;
#use lib '../blib/lib';
#use lib '../blib/arch';

package Typelib::Test2;
use Class::Std::Fast constructor => 'none', cache => 1;
use base qw(SOAP::WSDL::XSD::Typelib::Builtin::string);

package Typelib::My;
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);
use Class::Std::Fast constructor => 'none', cache => 1;
my %test_of :ATTR(:name<test> :default<()>);

__PACKAGE__->_factory([ 'test' ],
    { test => \%test_of },
    { 'test' => 'Typelib::Test' }
);


package Typelib::Test;
use Class::Std::Fast constructor => 'none', cache => 1;
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);
my %test2_of :ATTR(:get<test2> :default<()>);

our $XML_ATTRIBUTE_CLASS='Typelib::Test::_ATTR';
sub __get_attr_class { $XML_ATTRIBUTE_CLASS };

__PACKAGE__->_factory([ 'test2' ],
    { test2 => \%test2_of },
    { test2 => 'Typelib::Test2' }
);

package Typelib::Test::_ATTR;
use Class::Std::Fast constructor => 'none', cache => 1;
use SOAP::WSDL::XSD::Typelib::AttributeSet;
@Typelib::Test::_ATTR::ISA = qw(SOAP::WSDL::XSD::Typelib::AttributeSet);

{
    my %name_of :ATTR(:get<name> :default<()>);

    __PACKAGE__->_factory([ 'name' ],
        { name => \%name_of },
        { name => 'SOAP::WSDL::XSD::Typelib::Builtin::string' }
    );

};

package main;
use strict;
use Test::More tests => 4;
use SOAP::WSDL::XSD::Typelib::Builtin::string;
use SOAP::WSDL::Expat::MessageParser_XS;

my $xml = q{<SOAP-ENV:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" >
    <SOAP-ENV:Body>
    <MyAtomicComplexTypeElement xmlns="urn:Test" >
    <test name="foo">
        <test2 >Test2</test2>
        <test2 >Test2</test2>
        <test2 >Test2</test2>
        <test2 >Test2</test2>
        <test2 >Test2</test2>
        <test2 >Test2</test2>
        <test2 >Test2</test2>
        <test2 >Test2</test2>
        <test2 >Test2</test2>
        <test2 >Test2</test2>
        <test2 >Test2</test2>
        <test2 >Test2</test2>
        <test2 >Test55</test2>
    </test>
    <test>
        <test2 >Test2</test2>
        <test2 >Test2</test2>
        <test2 >Test2</test2>
        <test2 >Test2</test2>
        <test2 >Test2</test2>
        <test2 >Test2</test2>
        <test2 >Test2</test2>
        <test2 >Test2</test2>
        <test2 >Test2</test2>
        <test2 >Test2</test2>
        <test2 >Test2</test2>
        <test2 >Test2</test2>
        <test2>Test55</test2>
    </test>
    </MyAtomicComplexTypeElement>
</SOAP-ENV:Body></SOAP-ENV:Envelope>};

# short version for debugging
#$xml = q{<SOAP-ENV:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" >
#    <SOAP-ENV:Body>
#    <MyAtomicComplexTypeElement xmlns="urn:Test" >
#    <test name="foo">
#        <test2 >Test2</test2>
#    </test>
#    <test>
#        <test2>Test55</test2>
#    </test>
#    </MyAtomicComplexTypeElement>
#</SOAP-ENV:Body></SOAP-ENV:Envelope>};

my $map = {
    'MyAtomicComplexTypeElement' => 'Typelib::My',
    'MyAtomicComplexTypeElement/test' => 'Typelib::Test',
    'MyAtomicComplexTypeElement/test/test2' => 'SOAP::WSDL::XSD::Typelib::Builtin::string'

};

sub get_class {
    my $name = join('/', @{ $_[1] });
    return ($map->{ $name }) ? $map->{ $name }
        : warn "no class found for $name";
};

sub get_typemap {
    return $map;
}

use SOAP::WSDL::Expat::MessageParser;
use Data::Dumper;
# die Dumper $SOAP::WSDL::XSD::Typelib::ComplexType::___attributes_of_ref;

my $wsdl_parser = SOAP::WSDL::Expat::MessageParser->new({
    class_resolver => 'main'
});

my $xs = SOAP::WSDL::Expat::MessageParser_XS->new({
    class_resolver => 'main'
});
is $xs->parse($xml), $wsdl_parser->parse($xml);

my $result = $xs->parse($xml);

is $result->get_test()->[0]->get_test2()->[0], 'Test2';
is $result->get_test()->[1]->get_test2()->[-1], 'Test55';
is scalar @{ $result->get_test()->[1]->get_test2() }, 13;

# print $result->get_test()->[0]->_DUMP;
print $result;
