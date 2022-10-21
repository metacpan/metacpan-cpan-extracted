use strict;
use warnings;
use FindBin;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;

# Some exception classes to play with
package Base::X;
sub message     { shift->{message} }
sub http_status { shift->{status} }

package My::X;
use base qw(Base::X);

sub new {
    my ( $class, $args ) = @_;
    $args->{status} ||= 500;
    bless $args, $class;
}

sub throw {
    my $class = shift;
    die $class->new(@_);
}

package My::X::418;
use base qw(My::X);

sub new {
    my ( $class, $args ) = @_;
    $args->{status}  ||= 418;
    $args->{message} ||= 'teapot';
    bless $args, $class;
}

package My::X::307;
use base qw(My::X);
sub location { shift->{location} }

sub new {
    my ( $class, $args ) = @_;
    $args->{status} ||= 307;
    bless $args, $class;
}

package Your::X;
use base qw(Base::X);

sub does    { return 1 }
sub payload { return { fake => 'payload' } }
sub ident   {'fake-exception'}

package Your::X::Array;
use base qw(Your::X);

sub payload { my $s = shift; return { array => $s->{array} } }

# The fake we use for testing
package main;
use HTTP::Throwable::Factory qw(http_throw);

my $app = sub {
    my $env = shift;

    my $path = $env->{PATH_INFO};
    if ( $path eq '/ok' ) {
        return [ 200, [ 'Content-Type' => 'text/plain' ], ['all ok'] ];
    }
    elsif ( $path eq '/error' ) {
        return [
            400, [ 'Content-Type' => 'text/plain' ],
            ['there was an error']
        ];
    }
    elsif ( $path eq '/jsonerror' ) {
        return [
            400,
            [ 'Content-Type' => 'application/json' ],
            ['{"status":"jsonerror"}']
        ];
    }
    elsif ( $path eq '/die' ) {
        die 'argh!';
    }
    elsif ( $path eq '/exception/default' ) {
        My::X->throw( { message => 'default X' } );
    }
    elsif ( $path eq '/exception/418' ) {
        My::X::418->throw;
    }
    elsif ( $path eq '/exception/not-a-teapot' ) {
        My::X::418->throw( { status => 406 } );
    }
    elsif ( $path eq '/exception/strange-x' ) {
        my $x = bless {}, 'Your::X';
        die $x;
    }
    elsif ( $path eq '/exception/http-throwable' ) {
        http_throw(
            NotAcceptable => { message => 'You have to be kidding me!' } );
    }
    elsif ( $path eq '/throw/307' ) {
        My::X::307->throw( { location => '/ok' } );
    }
    elsif ( $path eq '/redirect/307' ) {
        return [ 307, [ 'Location' => '/ok' ], ['red'] ];
    }
    elsif ( $path eq '/with_array' ) {
        my $x = bless { array => [qw(apple banana cherry)]}, 'Your::X::Array';
        die $x;
    }

};

my $handler = builder {
    enable "Plack::Middleware::PrettyException";
    $app
};

# and finally the tests!

test_psgi
    app    => $handler,
    client => sub {
    my $cb = shift;
    {
        subtest 'all ok' => sub {
            my $res = $cb->( GET "http://localhost/ok" );
            is( $res->code,    200,      'status' );
            is( $res->content, 'all ok', 'content' );
        };

        subtest 'app returned error' => sub {
            my $res = $cb->( GET "http://localhost/error" );
            is( $res->code, 400, 'status' );
            is( $res->header('Content-Type'),
                'text/html;charset=utf-8', 'content-type' );
            like( $res->content, qr{<h1>Error 400</h1>}, 'heading' );
            like(
                $res->content,
                qr{<p>there was an error</p>},
                'error message'
            );
        };

        subtest 'app returned error, client requested json' => sub {
            my $res = $cb->(
                GET "http://localhost/error",
                'Accept' => 'application/json'
            );
            is( $res->code, 400, 'status' );
            is( $res->header('Content-Type'),
                'application/json', 'content-type' );
            like( $res->content, qr/"message":"there was an error"/, 'json' );
        };

        subtest 'app returned jsonerror' => sub {
            my $res = $cb->( GET "http://localhost/jsonerror" );
            is( $res->code, 400, 'status' );
            is( $res->header('Content-Type'),
                'application/json', 'content-type' );
            is( $res->content, '{"status":"jsonerror"}', 'json payload' );
        };

        subtest 'app returned jsonerror, client requested json' => sub {
            my $res = $cb->(
                GET "http://localhost/jsonerror",
                'Accept' => 'application/json'
            );
            is( $res->code, 400, 'status' );
            is( $res->header('Content-Type'),
                'application/json', 'content-type' );
            is( $res->content, '{"status":"jsonerror"}', 'json payload' );
        };

        subtest 'app died' => sub {
            my $res = $cb->( GET "http://localhost/die" );
            is( $res->code, 500, 'status' );
            like( $res->content, qr{<h1>Error 500</h1>}, 'heading' );
            like( $res->content, qr{<p>argh! at },       'error message' );
        };

        subtest 'app died, client requested json' => sub {
            my $res = $cb->(
                GET "http://localhost/die",
                'Accept' => 'application/json'
            );
            is( $res->code, 500, 'status' );
            like( $res->content, qr/"message":"argh! at/, 'json payload' );
        };

        subtest 'app threw exception' => sub {
            my $res = $cb->( GET "http://localhost/exception/default" );
            is( $res->code, 500, 'status' );
            like( $res->content, qr{<h1>Error 500</h1>}, 'heading' );
            like( $res->content, qr{<p>default X</p>},   'error message' );
        };

        subtest 'app threw exception, client requested json' => sub {
            my $res = $cb->(
                GET "http://localhost/exception/default",
                'Accept' => 'application/json'
            );
            is( $res->code, 500, 'status' );
            like( $res->content, qr/"message":"default X"/, 'json payload' );
        };

        subtest 'app threw exception 418' => sub {
            my $res = $cb->( GET "http://localhost/exception/418" );
            is( $res->code, 418, 'status' );
            like( $res->content, qr{<h1>Error 418</h1>}, 'heading' );
            like( $res->content, qr{<p>teapot</p>},      'error message' );
        };

        subtest 'app threw exception not-a-teapot' => sub {
            my $res = $cb->( GET "http://localhost/exception/not-a-teapot" );
            is( $res->code, 406, 'status' );
            like( $res->content, qr{<h1>Error 406</h1>}, 'heading' );
            like( $res->content, qr{<p>teapot</p>},      'error message' );
        };

        subtest 'app threw exception strange-x' => sub {
            my $res = $cb->( GET "http://localhost/exception/strange-x" );
            is( $res->code, 500, 'status' );
            like( $res->content, qr{<h1>Error 500</h1>}, 'heading' );
            like(
                $res->content,
                qr{<p>error not found in body</p>},
                'error message'
            );
            like( $res->content, qr{fake-exception},
                'fake ident found in body' );
            like(
                $res->content,
                qr{fake: payload},
                'fake payload found in body'
            );
        };

        subtest 'app threw exception http-throwable' => sub {
            my $res =
                $cb->( GET "http://localhost/exception/http-throwable" );
            is( $res->code, 406, 'status' );
            like( $res->content, qr{<h1>Error 406</h1>}, 'heading' );
            like(
                $res->content,
                qr{<p>You have to be kidding me!</p>},
                'error message'
            );
        };

        subtest 'app threw redirect 307' => sub {
            my $res = $cb->( GET "http://localhost/throw/307" );
            is( $res->code,               307,   'status' );
            is( $res->header('Location'), '/ok', 'Location header' );
            is( $res->content,            '/ok', 'default content' );
        };
        subtest 'app return redirect 307' => sub {
            my $res = $cb->( GET "http://localhost/redirect/307" );
            is( $res->code,               307,   'status' );
            is( $res->header('Location'), '/ok', 'Location header' );
            is( $res->content,            'red', 'some http content' );

        };

        subtest 'app return array' => sub {
            my $res = $cb->( GET "http://localhost/with_array" );
            like( $res->content, qr{<li>array:<ul>}, 'list header' );
            like( $res->content, qr{<li>apple</li>}, 'list item' );
            like( $res->content, qr{<li>banana</li>}, 'list item' );
            like( $res->content, qr{<li>cherry</li>}, 'list item' );
            like( $res->content, qr{</ul></li>}, 'close list' );
        };
    }
    };

# force_json
my $handler2 = builder {
    enable "Plack::Middleware::PrettyException" => ( force_json => 1 );
    $app
};
test_psgi
    app    => $handler2,
    client => sub {
    my $cb = shift;

    {
        subtest 'force_json' => sub {
            my $res = $cb->( GET "http://localhost/error" );
            is( $res->code, 400, 'status' );
            is( $res->header('Content-Type'),
                'application/json', 'content-type' );
            like( $res->content, qr/"message":"there was an error"/, 'json' );
        };
    };
    };

done_testing;
