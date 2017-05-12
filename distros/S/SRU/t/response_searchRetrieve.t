use strict;
use warnings;
use Test::More qw( no_plan );
use URI;
use SRU::Utils::XMLTest qw( wellFormedXML ); 

use_ok( 'SRU::Request::SearchRetrieve' );
use_ok( 'SRU::Response' );

OK: {
    my $url = "http://myserver.com/myurl/?operation=searchRetrieve&version=1.1&query=dc.identifier+%3d%220-8212-1623-6%22&recordSchema=dc&recordPacking=XML&stylesheet=http://myserver.com/myStyle";

    my $request = SRU::Request->newFromURI( $url );
    isa_ok( $request, 'SRU::Request::SearchRetrieve' );

    my $response = SRU::Response->newFromRequest( $request );
    isa_ok( $response, 'SRU::Response::SearchRetrieve' );
    is( $response->type(), 'searchRetrieve', 'type()' );

    my $xml = $response->asXML();
    ok( wellFormedXML($xml), "asXML()" );

    is( $response->numberOfRecords(), 0, 'numberOfRecords is 0' );

    ## add record #1
    $response->addRecord( 
        SRU::Response::Record->new(
            recordSchema => 'info:srw/schema/1/dc-v1.1',
            recordData => '<title>Huckleberry Finn</title>'
        )
    );
    is( $response->numberOfRecords(), 1, 'numberOfRecords is 1' );

    ## add record #2
    $response->addRecord( 
        SRU::Response::Record->new(
            recordSchema => 'info:srw/schema/1/dc-v1.1&',
            recordData => '<title>Huckle &amp; berry &amp; Finn</title>'
        )
    );
    is( $response->numberOfRecords(), 2, 'numberOfRecords is 2' );

    $xml = $response->asXML();
    like( $xml, qr{<numberOfRecords>2</numberOfRecords}, 
        'numberOfRecords in XML' );
    like( $xml, qr{Huckle &amp; berry &amp; Finn},
        'not double escaping recordData' );

    ## make sure recordPositions are being populated
    like( $xml, qr{<recordPosition>1</recordPosition>}, 'recordPosition() 1' );
    like( $xml, qr{<recordPosition>2</recordPosition>}, 'recordPosition() 2' );

    ok( wellFormedXML($xml), 'asXML() w/ records well formed' );
    like( $xml, qr{\Q<?xml-stylesheet type='text/xsl' href="http://myserver.com/myStyle" ?>\E}, 'found stylsheet in XML' );

    ## look for xCQL
    like( $xml, qr/<xQuery>/, 'found xQuery tag' );
}

SET_NUMBER_OF_RECORDS: {

    my $url = "http://myserver.com/myurl/?operation=searchRetrieve&version=1.1&query=dc.identifier+%3d%220-8212-1623-6%22&recordSchema=dc&recordPacking=XML&stylesheet=http://myserver.com/myStyle";

    my $request = SRU::Request->newFromURI( $url );
    isa_ok( $request, 'SRU::Request::SearchRetrieve' );

    my $response = SRU::Response->newFromRequest( $request );
    isa_ok( $response, 'SRU::Response::SearchRetrieve' );
    is( $response->type(), 'searchRetrieve', 'type()' );

    is( $response->numberOfRecords(), 0, 'numberOfRecords is 0' );

    ## add record #1
    $response->addRecord( 
        SRU::Response::Record->new(
            recordSchema => 'info:srw/schema/1/dc-v1.1',
            recordData => '<title>Huckleberry Finn</title>'
        )
    );
    is( $response->numberOfRecords(), 1, 'numberOfRecords is 1' );

    ## add record #2
    $response->addRecord( 
        SRU::Response::Record->new(
            recordSchema => 'info:srw/schema/1/dc-v1.1&',
            recordData => '<title>Huckle &amp; berry &amp; Finn</title>'
        )
    );
    is( $response->numberOfRecords(), 2, 'numberOfRecords is 2' );

    ## explicitly set number of records
    $response->numberOfRecords( 500 );
    is( $response->numberOfRecords(), 500, 'explicit set of numberOfRecords' );

}


