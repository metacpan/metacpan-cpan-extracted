#! perl
use strict;
use warnings;

use Test::MockTime qw//;
use Test::More;
use Test::Mojo;

use Mojolicious::Lite;

# The memory based storages to test
use Mojolicious::Sessions::ThreeS::Storage::Memory;
use Mojolicious::Sessions::ThreeS::Storage::CHI;

use CHI;

use Mojolicious::Sessions::ThreeS::State::Cookie;

my @storages = (
    Mojolicious::Sessions::ThreeS::Storage::Memory->new(),
    Mojolicious::Sessions::ThreeS::Storage::CHI->new({ chi => CHI->new( driver => 'Memory' , global => 0 ) })
  );

foreach my $storage ( @storages ){

    plugin Sessions3S => { storage => $storage,
                           state => Mojolicious::Sessions::ThreeS::State::Cookie->new(),
                       };

    app->sessions()->cookie_name( 'saussage' );
    app->sessions()->cookie_path('/cook');

    get '/cook/hello' => sub {
        my ($self) = @_;
        $self->session( said_hello => 'yup' );
        $self->flash( 'flashy' => 'flashy' );
        $self->res->headers()->add( 'X-MySid' , $self->session_id() );
        $self->render( text => 'saying hello' );
    };

    get '/cook/expire' => sub{
        my ($self) = @_;
        $self->session( expires => 1 );
        $self->render( text => 'expiring session' );
    };

    get '/cook/haveISaidHello' => sub{
        my ($self) = @_;
        $self->render( text =>  ( $self->session('said_hello') ? 'yes' : 'nope' ).( $self->flash( 'flashy' ) || '' ));
    };

    get '/stateless' => sub{
        my ($self) = @_;
        $self->render( text => $self->session('said_hello') ? 'yes' : 'nope' );
    };

    my $t = Test::Mojo->new();

    {
        # No cookie state first
        $t->get_ok('/cook/haveISaidHello')->content_like( qr/nope/ );
        ok( ! $t->tx->res->every_cookie('saussage')->[0] , "Ok no cookie yet");
    }

    my $session_cookie;
    {
        # This will actually set the cookie
        $t->get_ok('/cook/hello');

        ok( my $sid = $t->tx->res->headers()->header('X-MySid') , "Ok got my session ID in header");
        ok( $session_cookie = $t->tx->res->every_cookie('saussage')->[0] , "Ok can find the session cookie");
        is( $session_cookie->name() , 'saussage' , "Cookie is set with the right name" );
        is( $session_cookie->path() , '/cook');
        # The cookie value and the My-Sid are actually the same
        like( $session_cookie->value() , qr/^$sid/ );
        cmp_ok( $session_cookie->expires() , '>', time() );
        cmp_ok( $session_cookie->expires() , '<=', time() + app->sessions()->default_expiration()  );
    }

    {
        # The cookie state is preseved
        $t->get_ok('/cook/haveISaidHello')->content_like( qr/yesflashy$/ );
        # The second time, it is not flashy.
        $t->get_ok('/cook/haveISaidHello')->content_like( qr/yes$/ );
    }
    {
        # But not accessible to whatever is not under the right path
        $t->get_ok('/stateless')->content_like( qr/nope/ );
    }

    {
        # Accessible again
        $t->get_ok('/cook/haveISaidHello')->content_like( qr/yes/ );
        # But we will expire the session
        $t->get_ok('/cook/expire')->content_like( qr/expiring/ );
    }

    {
        # The session has now expired and this says no
        $t->get_ok('/cook/haveISaidHello')->content_like( qr/nope/ );
        # This is NOT true, because the cookie was not even send.
        # ok( ! @{app->sessions()->storage()->list_sessions()} , "Ok no sessions left in storage");
        # And no cookie was set in the response.
        ok( ! $t->tx->res->every_cookie('saussage')->[0] , "Ok no cookie yet");
    }

    {
        # Now say hello again
        $t->get_ok('/cook/hello');
        ok( $session_cookie = $t->tx->res->every_cookie('saussage')->[0] , "Ok can find the session cookie");
        my $first_time = $session_cookie->expires();
        # Jump two seconds in the future
        Test::MockTime::set_relative_time( 2 );
        # And the state is back!
        $t->get_ok('/cook/haveISaidHello')->content_like( qr/yes/ );
        $session_cookie = $t->tx->res->every_cookie('saussage')->[0];
        cmp_ok( $session_cookie->expires() , '>', $first_time , "The cookie expiration times has been bumped up");
        Test::MockTime::restore_time();
    }

    {
        # Jump to a time later than the session expire and check its no longer there.
        Test::MockTime::set_absolute_time( $session_cookie->expires() + 1 );
        $t->get_ok('/cook/haveISaidHello')->content_like( qr/nope/ );
        Test::MockTime::restore_time();
    }
} # End of memory storage loop.

done_testing();
