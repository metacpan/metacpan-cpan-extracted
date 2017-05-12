use strict;
use warnings;
use Test::More qw( no_plan );
use SRU::Utils::XMLTest;

use_ok( 'SRU::Request' );
use_ok( 'SRU::Response' );
use_ok( 'SRU::Response::Term' );

MISSING_VERSION: {
    my $url = 'http://myserver.com/myurl?operation=scan&scanClause=%2fdc.title%3d%22cat%22&responsePosition=3&maximumTerms=50&stylesheet=http://myserver.com/myStyle';
    my $request = SRU::Request->newFromURI( $url );
    isa_ok( $request, 'SRU::Request::Scan' );

    my $response = SRU::Response->newFromRequest( $request );
    isa_ok( $response, 'SRU::Response::Scan' );
    is( $response->type(), 'scan', 'type()' );

    my $diags = $response->diagnostics();
    is( @$diags, 1, 'got one diagnostic' );

    is( $diags->[0]->details(), 'version', 'got expected error' );
}

OK: {
    my $url = 'http://myserver.com/myurl/?operation=scan&version=1.1&scanClause=%2fdc.title%3d%22cat%22&responsePosition=3&maximumTerms=50&stylesheet=http://myserver.com/myStyle';

    my $request = SRU::Request->newFromURI( $url );
    isa_ok( $request, 'SRU::Request::Scan' );

    my $response = SRU::Response->newFromRequest( $request );
    isa_ok( $response, 'SRU::Response::Scan' );

    my $diags = $response->diagnostics();
    is( @$diags, 0, 'no diagnostic messages' );

    ## add a few terms to the response
    $response->addTerm( SRU::Response::Term->new( value => 'Apollo Creed' ) );
    $response->addTerm( SRU::Response::Term->new( value => 'Rocky Balboa' ) );

    ## check the xml
    my $xml = $response->asXML();
    ok( wellFormedXML( $xml ), 'asXML() well formed XML' );

    ## rudimentary check for the terms
    like( $xml, qr{<value>Apollo Creed</value>}, 'found term 1' );
    like( $xml, qr{<value>Rocky Balboa</value>}, 'found term 2' );
    
    like( $xml, qr{\Q<?xml-stylesheet type='text/xsl' href="http://myserver.com/myStyle" ?>\E}, 'found stylsheet in XML' ); 
}
