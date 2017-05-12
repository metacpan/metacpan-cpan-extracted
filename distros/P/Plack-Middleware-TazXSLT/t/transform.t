use strict;
use warnings;
use Test::More;
use Plack::Builder;
use FindBin qw($Bin);
use HTTP::Request::Common;
use Plack::Test;

use lib "$Bin/lib";
use MockUserAgent;

sub read_file {
	my $file = shift;
	return do { local(@ARGV,$/) = $file;<> }
}

my $backend = sub {
    my $env     = shift;
    my $request = Plack::Request->new($env);
    my $path     = $request->uri->path;
    if ( -e  "$Bin/documents/$path" ) {
        return [
            200,
            [ 'Content-Type', 'text/xml' ],
            [ read_file("$Bin/documents/$path") ]
        ];
    }
    else {
        return [ 404, [], [] ];
    }
};

my $app = builder {
    enable "NullLogger";
    enable "SimpleLogger";
    enable "TazXSLT", user_agent => MockUserAgent->new( $backend );
    $backend;
};

test_psgi $app,  sub { 
	my $cb  = shift;
        my $res = $cb->( GET 'http://example.com/01.xml', [ Host => 'www.example.com' ] );
    	is( $res->code, 200 );
    	is( $res->content, qq{<?xml version="1.0"?>\nbar\n} );
    	is( $res->content_length, 26 );
};

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->( GET 'http://example.com/01_no_pi.xml', host => 'example.com', 'X-Taz-XSLT-Stylesheet' => 'http://example.com/01.xsl'  );
    is( $res->code, 200 );
    is( $res->content, qq{<?xml version="1.0"?>\nbar\n} );
    is( $res->content_length, 26);
};

test_psgi $app,  sub { 
	my $cb  = shift;
        my $res = $cb->( GET 'http://example.com/change_http_status.xml', [ Host => 'www.example.com' ] );
    	is( $res->code, 204 );
    	is( $res->content, qq{<?xml version="1.0"?>\nbar\n} );
    	is( $res->content_length, 26 );
};

done_testing();
