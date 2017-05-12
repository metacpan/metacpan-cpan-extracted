use strict;
use warnings;
use Test::More tests => 9; 
use Test::Exception;

use SRU::Utils::XMLTest;

use_ok( 'SRU::Response::Record' );

BAD_CONSTRUCT: {

    ## missing recordSchema and recordData
    throws_ok
        { SRU::Response::Record->new() }
        qr/must supply recordSchema/,
        'must supply recordData and recordSchema';

    ## missing recordData
    throws_ok 
        { SRU::Response::Record->new( recordSchema => 'foo' ) }
        qr/must supply recordData/,
        'must supply recordData';

    ## missing recordSchema
    throws_ok
        { SRU::Response::Record->new( recordData => 'foo' ) }
        qr/must supply recordSchema/,
        'must supply recordSchema';
}

OK_CONSTRUCT: {
    my $xml = "<title>Huckleberry Finn</title>";
    my $r = SRU::Response::Record->new(
        recordSchema    => 'info:srw/schema/1/dc-v1.1',
        recordData      => $xml
    );

    isa_ok( $r, 'SRU::Response::Record' );
    is( $r->recordData(), $xml, 'recordData()' );
    is( $r->recordSchema(), 'info:srw/schema/1/dc-v1.1', 'recordSchema()' );
    is( $r->recordPacking(), 'xml', 'default recordPacking is xml' );
    
    $xml = $r->asXML();
    ok( wellFormedXML($xml), 'asXML() well formed' );
}

