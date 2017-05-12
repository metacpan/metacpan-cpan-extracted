use Test::More;
use strict;
use warnings;

#use SOAP::Lite  +trace => 'all';
use SOAP::Lite;

use SOAP::Data::Builder::Simple qw/ header data /;

my $soap = SOAP::Lite->autotype(0)->readable(0);

subtest empty => sub {
    my @empty = data();
    is_deeply \@empty, [], "data() - get back empty list";

    @empty = header();
    is_deeply \@empty, [], "header() - get back empty list";
};

subtest arryref => sub {

    ok my @data = data( foo => [ a => 1, b => 2 ] ), "arrayref";

    my $soap_data
        = SOAP::Data->name( 'SOAP:ENV' => \SOAP::Data->value( \@data ) );

    ok my $xml = $soap->serializer->serialize($soap_data), "serialize";

    like $xml,
        qr{^<\?xml version="1.0" encoding="UTF-8"\?><SOAP:ENV .*><soapenc:Array><foo><a>1</a><b>2</b></foo></soapenc:Array></SOAP:ENV>$},
        "xml ok";

};

done_testing();

