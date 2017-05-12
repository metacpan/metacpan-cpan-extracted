use strict;
use warnings;

use Test::More; 
use CGI;
use lib qw( t/lib );

eval "use CGI::Application;";

plan skip_all => "install CGI::Application if you want to use SRU::Server" if $@;

## flag to CGI::Application so that run() returns output
## rather than printing it.
$ENV{ CGI_APP_RETURN_ONLY } = 1;

plan tests => 10;

INHERITANCE: {
    require MyApp;
    my $app = MyApp->new();
    isa_ok( $app, 'MyApp' );
    isa_ok( $app, 'CGI::Application' );
}

DEFAULT_RESPONSE: {
    my $app = MyApp->new();
    $app->query( CGI->new() );
    my $content = $app->run();
    like( $content, qr|^Content-Type: text/xml|, 'content-type' );
    like( $content, qr|<foo>bar</foo>|, 'contains record' );
    like( $app->run(), qr/<explainResponse/, 'got default explain response' );
}

EXPLAIN: {
    my $app = MyApp->new();
    $app->query( CGI->new( 'operation=explain' ) );
    like( $app->run(), qr/<explainResponse/, 'got explain response' );
}

SCAN: {
    my $app = MyApp->new();
    $app->query( CGI->new( 'operation=scan&version=1' ) );
    like( $app->run(), qr/<scanResponse/, 'got scan response' );
}

SEARCH_RETRIEVE: {
    my $app = MyApp->new();
    $app->query( CGI->new( 'operation=searchRetrieve&version=1' ) );
    like( $app->run(), qr/<searchRetrieveResponse/,    
        'got searchRetrieve response' );
}

CQL_Error: {
    my $app = MyApp->new();
    $app->query( CGI->new( 'operation=searchRetrieve&version=1&query=dc.title > ""' ) );
    my $content = $app->run();
    like( $content, qr/<searchRetrieveResponse/,    
        'got searchRetrieve response' );
    like( $content, qr|<uri>info:srw/diagnostic/1/27</uri>|, 'contains proper cql error' );
}

