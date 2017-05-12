use strict;
use warnings;
use Test::More qw( no_plan );
use URI;
use XML::Simple;

use_ok( "SRU::Request" );
use_ok( "SRU::Request::Scan" );
my $url = 'http://myserver.com/myurl?operation=scan&version=1.1&scanClause=%2fdc.title%3d%22cat%22&responsePosition=3&maximumTerms=50&stylesheet=http://myserver.com/myStyle';

CONSTRUCTOR: {
    my $request = SRU::Request::Scan->new(
        version             => '1.1',
        scanClause          => '/dc.title="cat"',
        responsePosition    => 3,
        maximumTerms        => 50,
        stylesheet          => 'http://myserver.com/myStyle' );
    isa_ok( $request, 'SRU::Request::Scan' );
    is( $request->scanClause(), '/dc.title="cat"', 'scanClause()' );
    is( $request->responsePosition(), 3, 'responsePosition()' );
    is( $request->maximumTerms(), 50, 'maximumTerms()' );
    is( $request->stylesheet(), 'http://myserver.com/myStyle', 'stylesheet()' );
    is( $request->type(), 'scan', 'type()' );
}

FROM_URI: {
    my $uri = URI->new( $url );
    my $request = SRU::Request->newFromURI( $uri );
    isa_ok( $request, 'SRU::Request::Scan' );
    is( $request->scanClause(), '/dc.title="cat"', 'scanClause()' );
    is( $request->responsePosition(), 3, 'responsePosition()' );
    is( $request->maximumTerms(), 50, 'maximumTerms()' );
    is( $request->stylesheet(), 'http://myserver.com/myStyle', 'stylesheet()' );
}

FROM_STRING: {
    my $request = SRU::Request->newFromURI( $url );
    isa_ok( $request, 'SRU::Request::Scan' );
    is( $request->scanClause(), '/dc.title="cat"', 'scanClause()' );
    is( $request->responsePosition(), 3, 'responsePosition()' );
    is( $request->maximumTerms(), 50, 'maximumTerms()' );
    is( $request->stylesheet(), 'http://myserver.com/myStyle', 'stylesheet()' );
}

AS_XML: {
    my $request = SRU::Request::Scan->newFromURI( $url );
    my $xml = XMLin( $request->asXML(), KeepRoot => 1 );
    is( $xml->{echoedScanRequest}{version}, '1.1', 
            'found version in XML' );
    is( $xml->{echoedScanRequest}{scanClause}, '/dc.title="cat"', 
            'scanClause found in XML' );
    is( $xml->{echoedScanRequest}{responsePosition}, '3', 
            'responsePosition found in XML' );
    is( $xml->{echoedScanRequest}{maximumTerms}, '50', 
            'maximum terms found in XML' );
    is( $xml->{echoedScanRequest}{stylesheet}, 'http://myserver.com/myStyle', 
        'styleSheet found in XML' );
}
    

