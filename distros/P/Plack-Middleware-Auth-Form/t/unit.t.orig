use strict;
use warnings;

use Test::More;
use Data::Dumper;

use Plack::Middleware::Auth::Form;


my $get_req = { 
    PATH_INFO => '/login', 
    REQUEST_METHOD => 'GET',
    HTTP_REFERER => '/from_page',
};

my $input = 'username=joe&password=pass1';
open( my $input_fh, '<', \$input ) or die $!; 
my $post_req = { 
    PATH_INFO => '/login', 
    REQUEST_METHOD => 'POST', 
    CONTENT_TYPE => 'application/x-www-form-urlencoded',
    CONTENT_LENGTH => length( $input ),
    'psgi.input' => $input_fh,
    'psgix.session' => { redir_to => '/landing_page' },
};

my $middleware = Plack::Middleware::Auth::Form->new( authenticator => sub { 1 } );
my $res = $middleware->call( $get_req );
like( join( '', @{ $res->[2] } ), qr/form id="login_form"/, '/login with login form' );
is( $get_req->{'psgix.session'}{redir_to}, '/from_page' );
{
    local $get_req->{'psgix.session'}{user_id} = 1;
    my $res = $middleware->call( $get_req );
    like( join( '', @{ $res->[2] } ), qr/Already logged in/, 'no login form for logged in users' );
}

$res = $middleware->call( $post_req );
is( $res->[1][0], 'Location', 'Redirection after login' ) or warn Dumper($res);
is( $res->[1][1], '/landing_page', 'Redirection after login' ) or warn Dumper($res);
is( $post_req->{'psgix.session'}{user_id}, 'joe', 'Username saved in the session' );
is( $post_req->{'psgix.session'}{redir_to}, undef, 'redir_to removed after usage' );
ok( !exists $post_req->{'psgix.session'}{remember} );

{
    my $middleware = Plack::Middleware::Auth::Form->new( authenticator => sub { { redir_to => '/user_page' } } );
    $res = $middleware->call( $post_req );
    is( $res->[1][0], 'Location', 'Redirection after login' ) or warn Dumper($res);
    is( $res->[1][1], '/user_page', 'Redirection after login (user page)' ) or warn Dumper($res);
}

$post_req->{'psgix.session'}{redir_to} = '/new_landing_page';
$middleware = Plack::Middleware::Auth::Form->new( authenticator => sub { { user_id => 1 } } );
$res = $middleware->call( $post_req );
is( $post_req->{'psgix.session'}{user_id}, '1', 'User id saved in the session' );

$middleware = Plack::Middleware::Auth::Form->new( authenticator => sub { 0 } );
$res = $middleware->call( $post_req );
like( join( '', @{ $res->[2] } ), qr/error.*form id="login_form"/, 'login form for login error' );
ok( !exists( $post_req->{'psgix.session'}{user_id} ), 'User logged out after failed login' );


$post_req->{'psgix.session'}{user_id} = '1';
$post_req->{PATH_INFO} = '/logout';
$middleware = Plack::Middleware::Auth::Form->new( after_logout => '/after_logout' );
$res = $middleware->call( $post_req );
ok( !exists( $post_req->{'psgix.session'}{user_id} ), 'User logged out' );
is( $res->[1][0], 'Location', 'Redirection after logout' );
is( $res->[1][1], '/after_logout', 'Redirection after logout' );

$middleware = Plack::Middleware::Auth::Form->new( 
    app => sub { [ 200, {}, [ 'aaa' . $_[0]->{'Plack::Middleware::Auth::Form.LoginForm'} ] ] },
    no_login_page => 1,
);
$res = $middleware->call( $get_req );
like( join( '', @{ $res->[2] } ), qr/form id="login_form"/, 'login form passed' );
like( join( '', @{ $res->[2] } ), qr/^aaa/, 'app login page used' );

$input = 'username=joe&password=pass1&remember=1';
open( $input_fh, '<', \$input ) or die $!; 
$post_req = { 
    PATH_INFO => '/login', 
    REQUEST_METHOD => 'POST', 
    CONTENT_TYPE => 'application/x-www-form-urlencoded',
    CONTENT_LENGTH => length( $input ),
    'psgi.input' => $input_fh,
    'psgix.session' => { redir_to => '/landing_page' },
};
$middleware = Plack::Middleware::Auth::Form->new( authenticator => sub { 1 }, app => sub {} );
$res = $middleware->call( $post_req );
ok( $post_req->{'psgix.session'}{remember}, 'Remeber saved on session' );
is( $post_req->{'psgix.session'}{user_id}, 'joe', 'Username saved in the session' );
$get_req->{PATH_INFO} = '/some_page';
$get_req->{'psgix.session'}{remember} = 1;
$res = $middleware->call( $get_req );
ok( $get_req->{'psgix.session.options'}{expires} > 10000, 'Long session' );

$middleware = Plack::Middleware::Auth::Form->new( 
    secure => 1,
    authenticator => sub { 1 },
    ssl_port => 5555,
);

$res = $middleware->call( { 
        PATH_INFO => '/login', 
        'psgi.url_scheme' => 'http',
        REQUEST_METHOD => 'GET',
        SERVER_NAME => 'myserver',
    }
);
is( $res->[1][0], 'Location', 'Redirection to secure login' ) or warn Dumper($res);
is( $res->[1][1], 'https://myserver:5555/login', 'Redirection to secure login' ) or warn Dumper($res);

done_testing;

