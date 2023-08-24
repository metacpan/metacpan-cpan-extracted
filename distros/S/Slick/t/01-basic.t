## no critic
use Test::More;

BEGIN {
    use_ok 'Slick';
    use_ok 'Slick::Error';
    use_ok 'Slick::RouteMap';
    use_ok 'Slick::Cache';
    use_ok 'Slick::Database';
    use_ok 'Slick::Router';
    use_ok 'Slick::Annotation';
}

use Slick;

my $slick = Slick->new;

isa_ok $slick, 'Slick';

# Test defaults
ok $slick->handlers;
isa_ok $slick->handlers, 'Slick::RouteMap';
is $slick->addr,    '127.0.0.1';
is $slick->port,    8000;
is $slick->timeout, 120;
is $slick->env,     'dev';
ok $slick->dbs;
isa_ok $slick->dbs, 'HASH';
ok $slick->banner;

ok $slick->event_handlers;
isa_ok $slick->event_handlers, 'HASH';

my $t = {
    QUERY_STRING    => "",
    REMOTE_ADDR     => "127.0.0.1",
    REMOTE_PORT     => 46604,
    REQUEST_METHOD  => "GET",
    REQUEST_URI     => "/",
    SCRIPT_NAME     => "",
    SERVER_NAME     => "127.0.0.1",
    SERVER_PORT     => 8000,
    SERVER_PROTOCOL => "HTTP/1.1"
};

my $response = $slick->_dispatch($t);

is $response->[0],      '405';
is $response->[2]->[0], '405 Method Not Supported';

$slick->get(
    '/foo',
    sub {
        my ( $app, $context ) = @_;
        $context->status(201)->json( { foo => 'bar' } );
    }
);

$slick->post(
    '/foo',
    sub {
        my ( $app, $context ) = @_;
        $context->status(500);
    }
);

$slick->get(
    '/foobar',
    sub {
        # unreachable
    },
    {
        before_dispatch => [
            sub {
                my ( $app, $context ) = @_;
                $context->status(509);

                # Fail
                return undef;
            }
        ]
    }
);

$slick->get(
    '/foo/{bar}',
    sub {
        $_[1]->status(201)->body( $_[1]->param('bar') );
    }
);

$slick->get(
    '/foo/query',
    sub {
        $_[1]->body( $_[1]->query('foo') );
    }
);

$slick->get( '/redirect',       sub { $_[1]->redirect('/bob') } );
$slick->get( '/redirect_other', sub { $_[1]->redirect( '/bob', 301 ) } );

$slick->get(
    '/dies',
    sub {
        is rindex( $_[1]->stash->{'slick.errors'}->[0]->error, 'test die', 0 ),
          0;
    },
    { before_dispatch => [ sub { die 'test die' } ] }
);

$slick->get( '/goop/*', sub { $_[1]->text('123'); } );

my $router = Slick::Router->new( base => '/foo' );
$router->get( '/bob' => sub { return $_[1]->json( { foo => 'bar' } ); } );
$slick->register($router);

ok $slick->handlers->_map->{'/'}->{children}->{'foo'}->{children}->{'bob'}
  ->{methods}->{get};
ok $slick->handlers->_map->{'/'}->{children}->{'foo'}->{methods}->{post};
ok $slick->handlers->_map->{'/'}->{children}->{'foo'}->{methods}->{get};
ok $slick->handlers->_map->{'/'}->{children}->{'foobar'}->{methods}->{get};
ok $slick->handlers->_map->{'/'}->{children}->{goop}->{children}->{'*'}
  ->{methods}->{get};
my $f = $slick->handlers->_map->{'/'}->{children}->{'foo'}->{methods}->{get};
isa_ok $f, 'Slick::Route';
$f = $slick->handlers->_map->{'/'}->{children}->{'foo'}->{methods}->{post};
isa_ok $f, 'Slick::Route';
$f = $slick->handlers->_map->{'/'}->{children}->{'foobar'}->{methods}->{get};
isa_ok $f, 'Slick::Route';

$t = {
    QUERY_STRING    => "",
    REMOTE_ADDR     => "127.0.0.1",
    REMOTE_PORT     => 46604,
    REQUEST_METHOD  => "GET",
    REQUEST_URI     => "/foo",
    SCRIPT_NAME     => "",
    SERVER_NAME     => "127.0.0.1",
    SERVER_PORT     => 8000,
    SERVER_PROTOCOL => "HTTP/1.1"
};

$response = $slick->_dispatch($t);

is $response->[0],      '201';
is $response->[2]->[0], '{"foo":"bar"}';
is %{ { @{ $response->[1] } } }{'Content-Type'},
  'application/json; encoding=utf8';

$t = {
    QUERY_STRING    => "",
    REMOTE_ADDR     => "127.0.0.1",
    REMOTE_PORT     => 46604,
    REQUEST_METHOD  => "POST",
    REQUEST_URI     => "/foo",
    SCRIPT_NAME     => "",
    SERVER_NAME     => "127.0.0.1",
    SERVER_PORT     => 8000,
    SERVER_PROTOCOL => "HTTP/1.1"
};

$response = $slick->_dispatch($t);

is $response->[0],      '500';
is $response->[2]->[0], '';

$t = {
    QUERY_STRING    => "",
    REMOTE_ADDR     => "127.0.0.1",
    REMOTE_PORT     => 46604,
    REQUEST_METHOD  => "GET",
    REQUEST_URI     => "/foobar",
    SCRIPT_NAME     => "",
    SERVER_NAME     => "127.0.0.1",
    SERVER_PORT     => 8000,
    SERVER_PROTOCOL => "HTTP/1.1"
};

$response = $slick->_dispatch($t);

is $response->[0],      '509';
is $response->[2]->[0], '';

$t = {
    QUERY_STRING    => "",
    REMOTE_ADDR     => "127.0.0.1",
    REMOTE_PORT     => 46604,
    REQUEST_METHOD  => "GET",
    REQUEST_URI     => "/foo/boop",
    SCRIPT_NAME     => "",
    SERVER_NAME     => "127.0.0.1",
    SERVER_PORT     => 8000,
    SERVER_PROTOCOL => "HTTP/1.1"
};

$response = $slick->_dispatch($t);

is $response->[0],      '201';
is $response->[2]->[0], 'boop';

$t = {
    QUERY_STRING    => "foo=bar",
    REMOTE_ADDR     => "127.0.0.1",
    REMOTE_PORT     => 46604,
    REQUEST_METHOD  => "GET",
    REQUEST_URI     => "/foo/query",
    SCRIPT_NAME     => "",
    SERVER_NAME     => "127.0.0.1",
    SERVER_PORT     => 8000,
    SERVER_PROTOCOL => "HTTP/1.1"
};

$response = $slick->_dispatch($t);

is $response->[0],      '200';
is $response->[2]->[0], 'bar';

$t = {
    QUERY_STRING    => '',
    REMOTE_ADDR     => "127.0.0.1",
    REMOTE_PORT     => 46604,
    REQUEST_METHOD  => "GET",
    REQUEST_URI     => "/redirect",
    SCRIPT_NAME     => "",
    SERVER_NAME     => "127.0.0.1",
    SERVER_PORT     => 8000,
    SERVER_PROTOCOL => "HTTP/1.1"
};

$response = $slick->_dispatch($t);

is $response->[0], '303';
my %h = $response->[1]->@*;
ok $h{Location};
is $h{Location}, '/bob';

$t = {
    QUERY_STRING    => '',
    REMOTE_ADDR     => "127.0.0.1",
    REMOTE_PORT     => 46604,
    REQUEST_METHOD  => "GET",
    REQUEST_URI     => "/foo/bob",
    SCRIPT_NAME     => "",
    SERVER_NAME     => "127.0.0.1",
    SERVER_PORT     => 8000,
    SERVER_PROTOCOL => "HTTP/1.1"
};

$response = $slick->_dispatch($t);

is $response->[0],      '200';
is $response->[2]->[0], '{"foo":"bar"}';

$t = {
    QUERY_STRING    => '',
    REMOTE_ADDR     => "127.0.0.1",
    REMOTE_PORT     => 46604,
    REQUEST_METHOD  => "GET",
    REQUEST_URI     => "/foo/bob",
    SCRIPT_NAME     => "",
    SERVER_NAME     => "127.0.0.1",
    SERVER_PORT     => 8000,
    SERVER_PROTOCOL => "HTTP/1.1"
};

$response = $slick->_dispatch($t);

is $response->[0],      '200';
is $response->[2]->[0], '{"foo":"bar"}';

$t = {
    QUERY_STRING    => '',
    REMOTE_ADDR     => "127.0.0.1",
    REMOTE_PORT     => 46604,
    REQUEST_METHOD  => "GET",
    REQUEST_URI     => "/dies",
    SCRIPT_NAME     => "",
    SERVER_NAME     => "127.0.0.1",
    SERVER_PORT     => 8000,
    SERVER_PROTOCOL => "HTTP/1.1"
};

$response = $slick->_dispatch($t);

my $e = Slick::Error->new('foo');

is $e->error, 'foo';
isa_ok $e, 'Slick::Error';
is $e->error_type, 'SCALAR';

isa_ok( Slick::Error->new($e), 'Slick::Error' );
is( Slick::Error->new($e)->error,      'foo' );
is( Slick::Error->new($e)->error_type, 'SCALAR' );

$e = Slick::Error->new($slick);

isa_ok( $e, 'Slick::Error' );
is( Slick::Error->new($e)->error,      $slick );
is( Slick::Error->new($e)->error_type, 'Slick' );

$t = {
    QUERY_STRING    => '',
    REMOTE_ADDR     => "127.0.0.1",
    REMOTE_PORT     => 46604,
    REQUEST_METHOD  => "GET",
    REQUEST_URI     => "/goop/bob",
    SCRIPT_NAME     => "",
    SERVER_NAME     => "127.0.0.1",
    SERVER_PORT     => 8000,
    SERVER_PROTOCOL => "HTTP/1.1"
};

$response = $slick->_dispatch($t);
is( $response->[0],      '200' );
is( $response->[2]->[0], '123' );

$t = {
    QUERY_STRING    => '',
    REMOTE_ADDR     => "127.0.0.1",
    REMOTE_PORT     => 46604,
    REQUEST_METHOD  => "GET",
    REQUEST_URI     => "/goop/smob",
    SCRIPT_NAME     => "",
    SERVER_NAME     => "127.0.0.1",
    SERVER_PORT     => 8000,
    SERVER_PROTOCOL => "HTTP/1.1"
};

$response = $slick->_dispatch($t);
is( $response->[0],      '200' );
is( $response->[2]->[0], '123' );

done_testing;
