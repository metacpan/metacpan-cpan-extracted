package Plack::Middleware::Auth::Form::Override;

use parent 'Plack::Middleware::Auth::Form';

sub _wrap_body
{
    my ($self, $content) = @_;
    return "<html><head><title>Wrapped!</title></head>"
         . "<body>$content</body></html>";
}

package main;

use strict;
use warnings;

use Test::More;
use Data::Dumper;

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

my $class = 'Plack::Middleware::Auth::Form::Override';

my $middleware = $class->new( authenticator => sub { 1 } );
my $res = $middleware->call( $get_req );
my $html = join '', @{ $res->[2] };
like( $html, qr/form id="login_form"/, '/login with login form' );
like( $html, qr[<title>Wrapped!</title>], '... with HTML wrapper' );
is( $get_req->{'psgix.session'}{redir_to}, '/from_page' );

$res = $middleware->call( $post_req );
is( $res->[1][0], 'Location', 'Redirection after login' ) or warn Dumper($res);
is( $res->[1][1], '/landing_page', 'Redirection after login' ) or warn Dumper($res);
is( $post_req->{'psgix.session'}{user_id}, 'joe', 'Username saved in the session' );
is( $post_req->{'psgix.session'}{redir_to}, undef, 'redir_to removed after usage' );
ok( !$post_req->{'psgix.session'}{remember}, 'remember not set' );


$middleware = $class->new( authenticator => sub { 0 } );
$res = $middleware->call( $post_req );
$html = join '', @{ $res->[2] };
like( $html, qr/error.*form id="login_form"/, 'login form for login error' );
like( $html, qr[<title>Wrapped!</title>], '... with HTML wrapper' );


$post_req->{'psgix.session'}{user_id} = '1';
$post_req->{PATH_INFO} = '/logout';
$middleware = $class->new( after_logout => '/after_logout' );
$res = $middleware->call( $post_req );
ok( !exists( $post_req->{'psgix.session'}{user_id} ), 'User logged out' );
is( $res->[1][0], 'Location', 'Redirection after logout' );
is( $res->[1][1], '/after_logout', 'Redirection after logout' );

$middleware = $class->new(
    app => sub { [ 200, [], [ 'aaa' . $_[0]->{'Plack::Middleware::Auth::Form.LoginForm'} ] ] },
    no_login_page => 1,
);
$res = $middleware->call( $get_req );
$html = join '', @{ $res->[2] };
like( $html, qr/form id="login_form"/, 'login form passed' );
like( $html, qr/^aaa/, 'app login page used' );
unlike( $html, qr[<title>Wrapped!</title>], '... without HTML wrapper' );

done_testing;
