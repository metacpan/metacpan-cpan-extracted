use strict;
use warnings;
use Test::More qw( no_plan );
use URI;
use XML::Simple;

use_ok( 'SRU::Request::Explain' );

my $url = 'http://myserver.com/myurl?operation=explain&version=1.0&recordPacking=xml&stylesheet=http://www.example.com/style.xsl&extraRequestData=123';

CONSTRUCTOR: {
    my $request = SRU::Request::Explain->new(
        version         => '1.0',
        recordPacking   => 'xml',
        stylesheet      => 'http://www.example.com/style.xsl' );
    is( $request->version(), '1.0', 'version()' );
    is( $request->recordPacking(), 'xml', 'recordPacking()' );
    is( $request->stylesheet(), 'http://www.example.com/style.xsl',
        'stylesheet()');
    is( $request->type(), 'explain', 'type()' );
}

FROM_URI: {
    my $uri = URI->new( $url );
    my $request = SRU::Request->newFromURI( $uri );
    is( $request->version(), '1.0', 'version()' );
    is( $request->recordPacking(), 'xml', 'recordPacking()' );
    is( $request->stylesheet(), 'http://www.example.com/style.xsl',
        'stylesheet()');
}

DEFAULT_RESPONSE: {
    my $request = SRU::Request->newFromURI( 'http://myserver.com/myurl' );
    isa_ok( $request, 'SRU::Request::Explain' );
}

FROM_STRING: {
    my $request = SRU::Request->newFromURI( $url );
    is( $request->version(), '1.0', 'version()' );
    is( $request->recordPacking(), 'xml', 'recordPacking()' );
    is( $request->stylesheet(), 'http://www.example.com/style.xsl',
        'stylesheet()');
}

XML: {
    my $request = SRU::Request->newFromURI( $url );
    my $xml = XMLin( $request->asXML(), KeepRoot => 1 );
    is( $xml->{echoedExplainRequest}{version}, '1.0', 
        'got version in XML' );
    is( $xml->{echoedExplainRequest}{recordPacking}, 'xml', 
        'got recordPacking in XML' );
    is( $xml->{echoedExplainRequest}{stylesheet},
        'http://www.example.com/style.xsl', 'got stylesheet in XML' );
}



