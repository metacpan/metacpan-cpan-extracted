use strict;
use warnings;
use Test::More tests => 18;

use HTTP::Request::Common;
use Plack::Test;
use Plack::Middleware::Scope::Session;
use Scope::Session;
use Scope::Session::Singleton;
{
    package Test::Ob;
    sub new{ bless {},shift};
    sub DESTROY{
        ::pass('call-destroy');
    }
}


test_psgi 
    app => Plack::Middleware::Scope::Session->wrap(sub {
        my $env = shift;
        ::ok( Scope::Session->is_started );
        ::is( Scope::Session->notes('hello'), undef );
        ::ok( Scope::Session->notes( hello => q|world| ) );
        ::is( Scope::Session->notes('hello'), q|world| );
        Scope::Session->notes( 'just destroy' => Test::Ob->new );
        ::is_deeply( $env , Scope::Session->get_option( 'psgi.env' ));
        return [ 200, [ 'Content-Type' => 'text/plain' ], ["Hello World"] ];
    }),
    client => sub {
        my $cb = shift;
        for(1..3){
            my $req = HTTP::Request->new( GET => "http://localhost/hello" );
            my $res = $cb->($req);
        }

    };
