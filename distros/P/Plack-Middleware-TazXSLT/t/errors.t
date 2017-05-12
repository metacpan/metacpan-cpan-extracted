use strict;
use warnings;
use Plack::Middleware::TazXSLT;
use HTTP::Response;
use HTTP::Request::Common;
use Plack::Test;
use Test::More;
use Plack::Builder;

use FindBin qw($Bin);
use lib "$Bin/lib";
use MockUserAgent;


my $backend = sub {
    my $env     = shift;
    my $request = Plack::Request->new($env);
    my $uri     = $request->uri;

    if ( $uri eq 'http://example.com/read_error' ) {
        return [ 500, [ 'Client-Warning' => 'Internal response' ], [] ];
    }
    elsif ( $uri eq 'http://example.com/file_not_found' ) {
        return [ 404, [ Foo => 'Bar' ], [] ];
    }
    elsif ( $uri eq 'http://example.com/redirection' ) {
        return [ 301, [ Location => 'nothere',  ], [] ];
    }
    elsif ( $uri eq 'http://example.com/empty' ) {
        return [ 200, [ 'Content-Length' => 0], [] ];
    }
    elsif ( $uri eq 'http://example.com/head' ) {
        return [ 200, [ 'Content-Length' => 0, 'X-Test' => 'head'], [] ];
    }
    elsif ( $uri eq 'http://example.com/not_xml' ) {
        return [ 200, [ 'Content-Type' => 'text/html'], ['<xsl:include href="/does-not-exist"/>foo'] ];
    }
    elsif ( $uri eq 'http://example.com/xml_without_stylesheet' ) {
        return [ 200, [ 'Content-Type' => 'text/xml'], ['<xsl:include href="/file-not-found"/>foo'] ];
    }
    elsif ( $uri eq 'http://example.com/no_pi' ) {
        return [ 200, [ 'Content-Type' => 'text/xml'], ['<test>foo</test>'] ];
    }
    else {
        return [ 404, [], [] ];
    }
};

my $app = builder {
    enable "NullLogger";
    enable sub {
        my $app = shift;
        sub {
            my $env = shift;
            if ( open(my $null,'>', \my $str) ) {
                $env->{'psgi.errors'} = $null;
            }
            return $app->($env);
        };  
    }; 
    enable "TazXSLT", user_agent => MockUserAgent->new($backend);
    $backend;
};

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->( GET 'http://example.com/read_error');
    is( $res->code, 500 );
};

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->( GET 'http://example.com/xml_without_stylesheet');
    is( $res->code, 500 );
};

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->( GET 'http://example.com/file_not_found');
    is( $res->code(),        404,   'Mirroring errors from backend: code' );
    is( $res->header('foo'), 'Bar', 'Mirroring errors from backend: headers' );
};

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->( GET 'http://example.com/redirection');
    is( $res->code(),        301,   'Mirroring redirections from backend: code' );
    is( $res->header('Location'), 'nothere', 'Mirroring redirections from backend: headers' );
};

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->( HEAD 'http://example.com/head');
    is( $res->code(),        200,   'Mirroring HEAD requests from backend: code' );
};

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->( GET 'http://example.com/empty');
    is( $res->code(), 200, 'Mirroring empty requests from backend: code' );
    is( $res->content(), '', 'Mirroring empty requests from backend: code' );
};

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->( GET 'http://example.com/no_pi' );
    is( $res->code(), 200, 'Mirroring response without pi from backend: code' );
    is( $res->content(), '<test>foo</test>', 'Mirroring response without pi from backend: content'  );
};

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->( GET 'http://example.com/not_xml');
    is( $res->code(), 200, 'Received non xml: mirroring to frontend' );
    is( $res->header('content-type'),
        'text/html', 'Received non xml: mirroring to frontend');
    is(
        $res->decoded_content(),
        '<xsl:include href="/does-not-exist"/>foo',
	'Received non xml: mirroring to frontend'
    );
};

done_testing();
