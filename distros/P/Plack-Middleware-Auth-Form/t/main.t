use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::PSGI;
use File::Spec;

my $psgi_file = File::Spec->catfile( 't', 'app.psgi' );
my $app = do $psgi_file;
if( !$app ){
    my $message = "Cannot load '$psgi_file': ";
    if( $! && $@ ){
        $message .= "$! or $@";
    }
    elsif( $! ){
        $message .= $!;
    }
    elsif( $@ ){
        $message .= $@;
    }
    else{
        $message .= 'what?!';
    }
    die $message;
}

my $mech = Test::WWW::Mechanize::PSGI->new( app => $app );
$mech->get( '/some_page' );
$mech->follow_link_ok( { text => 'login' } );
$mech->submit_form_ok( {
        with_fields => {
            username => 'aaa',
            password => 'bbb',
        }
    }
);
$mech->content_contains( 'Wrong username or password', 'Wrong username or password' );
$mech->submit_form_ok( {
        with_fields => {
            username => 'aaa',
            password => 'aaa',
            remember => 1,
        }
    }
);
$mech->content_contains( 'Hi aaa', 'login passed, user_id filled in' );
is( $mech->uri->path, '/some_page', 'Redirect after login' );
my $expires;
$mech->cookie_jar->scan( sub{ $expires = $_[8] } );
ok( $expires > 1000, 'Expires set' );
$mech->get( '/' );
$mech->cookie_jar->clear_temporary_cookies;
$mech->get( '/' );
$mech->content_contains( 'Hi aaa', 'Session stays logged in after clearing temporary cookies' );

$mech->get( '/' );
$mech->submit_form_ok( { form_name => 'logout_form' } );
$mech->content_contains( '<a href="/login">login</a>', 'user logged out' );

done_testing;
