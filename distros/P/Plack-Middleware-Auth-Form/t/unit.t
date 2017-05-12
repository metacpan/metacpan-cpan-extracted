use strict;
use warnings;

use Test::More;

use Plack::Middleware::Auth::Form;
use Plack::Middleware::Lint;
use HTTP::Message::PSGI;
use HTTP::Request;
use Plack::Util;

my $get_req = HTTP::Request->new(
    'GET' => 'http://localhost/login', [
        Referer => '/from_page',
    ],
)->to_psgi();

my $input = 'username=joe&password=pass1';
open( my $input_fh, '<', \$input ) or die $!; 
my $post_req = +{
    %{ HTTP::Request->new(
            POST => 'http://localhost/login',
            [
                'Content-Type'   => 'application/x-www-form-urlencoded',
                'Content-Length' => length($input),
            ],
          )->to_psgi(),
      },
    'psgi.input' => $input_fh,
    'psgix.session' => { redir_to => '/landing_page' },
    'psgi.version' => [1,0],
};

my $middleware = Plack::Middleware::Auth::Form->new( authenticator => sub { 1 } );
$middleware = Plack::Middleware::Lint->wrap($middleware);
my $res = $middleware->( $get_req );
like( join( '', @{ $res->[2] } ), qr/form id="login_form"/, '/login with login form' );
is( $get_req->{'psgix.session'}{redir_to}, '/from_page' );
{
    local $get_req->{'psgix.session'}{user_id} = 1;
    my $res = $middleware->( $get_req );
    like( join( '', @{ $res->[2] } ), qr/Already logged in/, 'no login form for logged in users' );
}

$res = $middleware->( $post_req );
is( Plack::Util::header_get($res->[1], 'Location'), '/landing_page', 'Redirection after login' )
    or diag explain $res;
is( $post_req->{'psgix.session'}{user_id}, 'joe', 'Username saved in the session' );
is( $post_req->{'psgix.session'}{redir_to}, undef, 'redir_to removed after usage' );
ok( ! $post_req->{'psgix.session'}{remember}, 'remember not set' );

{
    my $middleware = Plack::Middleware::Auth::Form->new( authenticator => sub { { redir_to => '/user_page' } } );
    $middleware = Plack::Middleware::Lint->wrap($middleware);
    $res = $middleware->( $post_req );
    is( Plack::Util::header_get($res->[1], 'Location'), '/user_page', 'Redirection after login (user page)' )
        or diag explain $res;
}

$post_req->{'psgix.session'}{redir_to} = '/new_landing_page';
$middleware = Plack::Middleware::Auth::Form->new( authenticator => sub { { user_id => 1 } } );
$middleware = Plack::Middleware::Lint->wrap($middleware);
$res = $middleware->( $post_req );
is( $post_req->{'psgix.session'}{user_id}, '1', 'User id saved in the session' );

$middleware = Plack::Middleware::Auth::Form->new( authenticator => sub { 0 } );
$middleware = Plack::Middleware::Lint->wrap($middleware);
$res = $middleware->( $post_req );
like( join( '', @{ $res->[2] } ), qr/error.*form id="login_form"/, 'login form for login error' );
ok( !exists( $post_req->{'psgix.session'}{user_id} ), 'User logged out after failed login' );


$post_req->{'psgix.session'}{user_id} = '1';
$post_req->{PATH_INFO} = '/logout';
$middleware = Plack::Middleware::Auth::Form->new( after_logout => '/after_logout', authenticator => sub { 0 } );
$middleware = Plack::Middleware::Lint->wrap($middleware);
$res = $middleware->( $post_req );
ok( !exists( $post_req->{'psgix.session'}{user_id} ), 'User logged out' );
is( Plack::Util::header_get($res->[1], 'Location'), '/after_logout', 'Redirection after logout' )
    or diag explain $res;

$middleware = Plack::Middleware::Auth::Form->new( 
    app => sub { [ 200, [], [ 'aaa' . $_[0]->{'Plack::Middleware::Auth::Form.LoginForm'} ] ] },
    no_login_page => 1,
    authenticator => sub { 0 },
);
$middleware = Plack::Middleware::Lint->wrap($middleware);
$res = $middleware->( $get_req );
like( join( '', @{ $res->[2] } ), qr/form id="login_form"/, 'login form passed' );
like( join( '', @{ $res->[2] } ), qr/^aaa/, 'app login page used' );

$input = 'username=joe&password=pass1&remember=1';
open( $input_fh, '<', \$input ) or die $!; 
$post_req = +{
    %{
        HTTP::Request->new(
            POST => 'http://localhost/login' => [
                'Content-Type' => 'application/x-www-form-urlencoded',
                'Content-Length' => length( $input ),
            ]
        )->to_psgi()
    },
    'psgi.input' => $input_fh,
    'psgix.session' => { redir_to => '/landing_page' },
};
$middleware = Plack::Middleware::Auth::Form->new( authenticator => sub { 1 }, app => sub {
    +[
        200, [], []
    ]
} );
$middleware = Plack::Middleware::Lint->wrap($middleware);
$res = $middleware->( $post_req );
ok( $post_req->{'psgix.session'}{remember}, 'Remeber saved on session' );
is( $post_req->{'psgix.session'}{user_id}, 'joe', 'Username saved in the session' );
{
    local $get_req->{PATH_INFO} = '/some_page';
    local $get_req->{'psgix.session'}{remember} = 1;
    $res = $middleware->( $get_req );
    ok( $get_req->{'psgix.session.options'}{expires} > 10000, 'Long session' );
}

$middleware = Plack::Middleware::Auth::Form->new( 
    secure => 1,
    authenticator => sub { 1 },
    ssl_port => 5555,
);
$middleware = Plack::Middleware::Lint->wrap($middleware);
$res = $middleware->( $get_req );
is( Plack::Util::header_get($res->[1], 'Location'), 'https://localhost:5555/login',
    'Redirection to secure login' )
    or diag explain $res;

done_testing;

