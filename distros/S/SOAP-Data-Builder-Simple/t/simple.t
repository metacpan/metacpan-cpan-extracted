use Test::More;
use strict;
use warnings;

#use SOAP::Lite  +trace => 'all';
use SOAP::Lite;

use SOAP::Data::Builder;
use SOAP::Data::Builder::Simple qw/ header data /;

# check SOAP::Data::Builder::Simple produces same output as SOAP::Data::Builder

sub compare {
    my ( $sdb, $sdb_simple, $name ) = @_;

    note $name if $name;

    is $sdb_simple->(), $sdb->(), "output matched ok";
}

compare(
    sub {
        my $soap_data_builder = SOAP::Data::Builder->new();
        $soap_data_builder->add_elem(
            name   => 'eb:MessageHeader',
            header => 1,
            attributes =>
                { "eb:version" => "2.0", "SOAP::mustUnderstand" => "1" }
        );
        my $from = $soap_data_builder->add_elem(
            name   => 'eb:From',
            parent => $soap_data_builder->get_elem('eb:MessageHeader')
        );

        $soap_data_builder->add_elem(
            name   => 'eb:PartyId',
            parent => $from,
            value  => 'uri:example.com'
        );

        $from->add_elem(
            name  => 'eb:Role',
            value => 'http://rosettanet.org/roles/Buyer',
        );

        $soap_data_builder->add_elem(
            name   => 'eb:DuplicateElimination',
            parent => $soap_data_builder->get_elem('eb:MessageHeader')
        );

        $soap_data_builder->add_elem(
            name  => 'foo',
            value => 'bar',
        );

        return $soap_data_builder->serialise();
    },

    sub {

        my @headers = header(
            'eb:MessageHeader' => [
                _attr => {
                    'eb:version'           => "2.0",
                    'SOAP::mustUnderstand' => "1"
                },
                'eb:From' => [
                    'eb:PartyId' => 'uri:example.com',
                    'eb:Role'    => 'http://rosettanet.org/roles/Buyer',
                ],
                'eb:DuplicateElimination' => undef,
            ]
        );
        my @data = data( foo => 'bar' );

        my $soap_data = SOAP::Data->name(
            'SOAP:ENV' => \SOAP::Data->value( @headers, @data ) );

        return SOAP::Serializer->autotype(0)->readable(0)
            ->serialize($soap_data);
    }
);

done_testing();

