use Test::More;
use strict;
use warnings;

#use SOAP::Lite  +trace => 'all';
use SOAP::Lite;

use SOAP::Data::Builder::Simple qw/ header data /;

# check that we can handle SOAP::Data objects as values

my $soap = SOAP::Lite->autotype(0)->readable(0);

my @tests = (
    {   name => "SOAP::Data, with no reference",
        test => sub {
            data(
                'SOAP:ENV' => [
                    'SOAP:BODY' =>
                        [ 'foo' => SOAP::Data->name( 'abc' => '123' ) ]
                ]
            );
        },
        expected =>
            qr{^<\?xml version="1.0" encoding="UTF-8"\?><SOAP:ENV .*><SOAP:BODY><foo><abc>123</abc></foo></SOAP:BODY></SOAP:ENV>$},
    },

    {   name => "SOAP::Data, with reference",
        test => sub {
            data(
                'SOAP:ENV' => [
                    'SOAP:BODY' =>
                        [ 'foo' => \SOAP::Data->name( 'abc' => '123' ) ]
                ]
            );
        },
        expected =>
            qr{^<\?xml version="1.0" encoding="UTF-8"\?><SOAP:ENV .*"><SOAP:BODY><foo><abc>123</abc></foo></SOAP:BODY></SOAP:ENV>$},
    },

    {   name => "SOAP::DATA list, no reference",
        test => sub {
            data(
                'SOAP:ENV' => [
                    foo => [
                        _value => SOAP::Data->value(
                            SOAP::Data->name( 'abc' => '123' ),
                            SOAP::Data->name( 'def' => '456' ),
                        )
                    ]
                ]
            );
        },
        expected =>
            qr{^<\?xml version="1.0" encoding="UTF-8"\?><SOAP:ENV .*"><foo><abc>123</abc><def>456</def></foo></SOAP:ENV>$},
    },

    {   name => "SOAP::DATA list, with reference",
        test => sub {
            data(
                'SOAP:ENV' => [
                    foo => [
                        _value => \SOAP::Data->value(
                            SOAP::Data->name( 'abc' => '123' ),
                            SOAP::Data->name( 'def' => '456' ),
                        )
                    ]
                ]
            );
        },
        expected =>
            qr{^<\?xml version="1.0" encoding="UTF-8"\?><SOAP:ENV .*"><foo><abc>123</abc><def>456</def></foo></SOAP:ENV>$},
    },

);

foreach my $test (@tests) {

    subtest $test->{name} => sub {

        ok my ($data) = $test->{test}->(), "data()";

        ok my $xml = $soap->serializer->serialize($data), "serialize";

        like $xml, $test->{expected}, "XML matches";
    };

}

done_testing();

