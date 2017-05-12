use strict;
use warnings;
use Test::More qw( no_plan );
use URI;
use XML::Simple;

use_ok( 'SRU::Request::SearchRetrieve' );

my $url = 'http://myserver.com/myurl?operation=searchRetrieve&version=1.1&query=dc.identifier+%3d%220-8212-1623-6%22&recordSchema=dc&recordPacking=XML&stylesheet=http://myserver.com/myStyle';

CONSTRUCTOR: {
    my $request = SRU::Request::SearchRetrieve->new(
        version         => '1.1',
        query           => 'dc.identifier ="0-8212-1623-6"',
        recordSchema    => 'dc',
        recordPacking   => 'XML',
        stylesheet      => 'http://myserver.com/myStyle' );
    is( $request->version(), '1.1', 'version()' );
    is( $request->query(), 'dc.identifier ="0-8212-1623-6"', 'query()' );
    is( $request->recordSchema(), 'dc', 'recordSchema()' );
    is( $request->recordPacking(), 'XML', 'recordPacking()' );
    is( $request->stylesheet(), 'http://myserver.com/myStyle', 'stylesheet()' );
    is( $request->type(), 'searchRetrieve', 'type()' );
}

CQL: {
    my $request = SRU::Request::SearchRetrieve->newFromURI( $url );
    my $node = $request->cql();
    isa_ok( $node, 'CQL::TermNode', 'got CQL node' );
    is( $node->toCQL(), 'dc.identifier = 0-8212-1623-6', 'correct CQL' );
}

FROM_URI: {
    my $uri = URI->new( $url );
    my $request = SRU::Request->newFromURI( $uri );
    isa_ok( $request, 'SRU::Request::SearchRetrieve' );
    is( $request->version(), '1.1', 'version()' );
    is( $request->query(), 'dc.identifier ="0-8212-1623-6"', 'query()' );
    is( $request->recordSchema(), 'dc', 'recordSchema()' );
    is( $request->recordPacking(), 'XML', 'recordPacking()' );
    is( $request->stylesheet(), 'http://myserver.com/myStyle', 'stylesheet()' );
}

FROM_STRING: {
    my $request = SRU::Request->newFromURI( $url );
    isa_ok( $request, 'SRU::Request::SearchRetrieve' );
    is( $request->version(), '1.1', 'version()' );
    is( $request->query(), 'dc.identifier ="0-8212-1623-6"', 'query()' );
    is( $request->recordSchema(), 'dc', 'recordSchema()' );
    is( $request->recordPacking(), 'XML', 'recordPacking()' );
    is( $request->stylesheet(), 'http://myserver.com/myStyle', 'stylesheet()' );
}

AS_XML: {
    my $request = SRU::Request->newFromURI( $url );
    my $xml = XMLin( $request->asXML(), KeepRoot => 1 );
    is( $xml->{echoedSearchRetrieveRequest}{version}, '1.1',
        'found version in XML' );
    is( $xml->{echoedSearchRetrieveRequest}{query},  
        'dc.identifier ="0-8212-1623-6"', 'found query in XML' );
    is( $xml->{echoedSearchRetrieveRequest}{recordPacking}, 'XML', 
        'found recordPacking in XML' );
    is( $xml->{echoedSearchRetrieveRequest}{stylesheet}, 
        'http://myserver.com/myStyle', 'found stylesheet in XML' );
}

