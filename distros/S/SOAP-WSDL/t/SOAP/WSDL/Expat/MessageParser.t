#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 6;
use lib '../../../../lib';
use lib '../../../../t/lib';
use lib 't/lib';
use lib '../lib';
use lib 'lib';

use_ok(qw/SOAP::WSDL::Expat::MessageParser/);

use MyComplexType;
use MyElement;
use MySimpleType;

my $xml = q{<SOAP-ENV:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" >
    <SOAP-ENV:Body><MyAtomicComplexTypeElement xmlns="urn:Test" >
    <test>Test</test>
    <test2 >Test2</test2>
    <foo><bar></bar><baz></baz></foo>
    </MyAtomicComplexTypeElement></SOAP-ENV:Body></SOAP-ENV:Envelope>};

my $parser = SOAP::WSDL::Expat::MessageParser->new({
    class_resolver => 'FakeResolver'
});

test_nil($parser);

test_simple_element($parser);

$parser->parse( $xml );



is $parser->get_data(), q{<MyAtomicComplexTypeElement xmlns="urn:Test">}
    . q{<test>Test</test><test2>Test2</test2></MyAtomicComplexTypeElement>}
    , 'Content comparison';

my $xml_attr = q{<SOAP-ENV:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" >
    <SOAP-ENV:Body><MyElementAttrs xmlns="urn:Test" test="Test" test2="Test2">
    <test>Test</test>
    <test2></test2>
    </MyElementAttrs></SOAP-ENV:Body></SOAP-ENV:Envelope>};

$parser->parse($xml_attr);

is $parser->get_data(),
    q{<MyElementAttrs xmlns="urn:Test" test="Test" test2="Test2"><test>Test</test><test2></test2></MyElementAttrs>},
    'Content with attributes';

my $xml_error = q{<SOAP-ENV:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" >
    <SOAP-ENV:Body><MyElementAttrs xmlns="urn:Test" test="Test" test2="Test2">
    <test>Test</test>
    <test2 ></test2>
    <foo>Bar</foo>
    </MyElementAttrs></SOAP-ENV:Body></SOAP-ENV:Envelope>};

eval { $parser->parse($xml_error) };
like $@, qr{\A Cannot \s resolve \s class \s for \s MyElementAttrs/foo }x, 'XML error';

# data classes reside in t/lib/Typelib/
BEGIN {
    package FakeResolver;
    {
        my %class_list = (
            'MyAtomicComplexTypeElement' => 'MyAtomicComplexTypeElement',
            'MyAtomicComplexTypeElement/test' => 'MyTestElement',
            'MyAtomicComplexTypeElement/test2' => 'MyTestElement2',
            'MyAtomicComplexTypeElement/foo' => '__SKIP__',
            'MyElementAttrs' => 'MyElementAttrs',
            'MyElementAttrs/test' => 'MyTestElement',
            'MyElementAttrs/test2' => 'MyTestElement2',
            'MySimpleElement' => 'MySimpleElement',
        );

        sub new { return bless {}, 'FakeResolver' };

        sub get_typemap { return \%class_list };

        sub get_class {
            my $name = join('/', @{ $_[1] });
            return ($class_list{ $name }) ? $class_list{ $name }
                : undef;
        };
    };
};

sub test_nil {
    my $parser = shift();
    my $xml_nil_attr = q{<SOAP-ENV:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" >
    <SOAP-ENV:Body><MyElementAttrs xmlns="urn:Test">
    <test>Test</test>
    <test2 xsi:nil="1"/>
    </MyElementAttrs></SOAP-ENV:Body></SOAP-ENV:Envelope>};

    my $result = $parser->parse($xml_nil_attr);
    is $result->get_test2->serialize({ name => 'test2'}), '<test2 xsi:nil="true"/>';
}


sub test_simple_element {
    my $parser = shift;

    my $body = $parser->parse(
        q{<SOAP-ENV:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" >
        <SOAP-ENV:Body><MySimpleElement xmlns="urn:Test">3</MySimpleElement></SOAP-ENV:Body></SOAP-ENV:Envelope>});
    is $body->get_value(), 3;
}