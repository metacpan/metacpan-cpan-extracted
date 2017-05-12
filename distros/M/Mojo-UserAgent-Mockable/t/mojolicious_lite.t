use 5.014;

package Application;
use Mojolicious::Lite;
use Mojolicious::Plugin::BasicAuthPlus;

# Don't store passwords in cleartext, kids
my %PASSWD = ( 'joeblow' => { uid => 1138, password => 'foobar' }, );

my %USERINFO = ( 1138 => { name => 'Joe Blow' }, );

plugin 'BasicAuthPlus';

group {
    under sub {
        my $c = shift;

        my $auth = sub {
            my ( $username, $password ) = @_;
            no warnings qw/uninitialized/;
            if ( $PASSWD{$username}{'password'} eq $password ) {
                my $uid = $PASSWD{$username}{'uid'};
                $c->stash( current_user_info => { %{ $USERINFO{$uid} }, key => int rand 1e9 } );
                return 1;
            }
            use warnings qw/uninitialized/;
        };

        if ( !$c->basic_auth( realm => $auth ) ) {
            $c->render( status => 401, text => 'Stranger danger!' );
            return undef;
        }
        return 1;
    };

    get '/random' => sub {
        my $c = shift;

        my $num = $c->req->param('num') || 5;
        my $min = $c->req->param('min') || 0;
        my $max = $c->req->param('max') || 1e9;

        my @numbers = map { int rand( $max - $min ) + $min } ( 0 .. $num );

        $c->render( json => \@numbers );
    };

    get '/userinfo' => sub {
        my $c    = shift;
        my $info = $c->stash('current_user_info');
        $c->render( json => $info );
    };
};

get '/' => sub {
    my $self = shift;
    $self->render( text => 'index page' );
};


package main;

use File::Temp;
use Mojo::UserAgent::Mockable;
use Mojo::Server::Daemon;
use Mojo::IOLoop;

use Test::Most;
use Test::Mojo;
use Test::Exception;

my $daemon = Mojo::Server::Daemon->new(
    app => Application::app, 
    ioloop => Mojo::IOLoop->singleton,
    silent => 1,
);

my $listen = q{http://127.0.0.1};
$daemon->listen( [$listen] )->start;
my $port = Mojo::IOLoop->acceptor( $daemon->acceptors->[0] )->port;
my $url  = Mojo::URL->new(qq{$listen:$port})->userinfo('joeblow:foobar');

my $dir = File::Temp->newdir;
my $output_file = qq{$dir/basic_authorization_test.json};

my ($key, $numbers);

subtest recording => sub {
    my $mock = Mojo::UserAgent::Mockable->new(ioloop => Mojo::IOLoop->singleton, mode => 'record', file => $output_file);
    my $t    = Test::Mojo->new;
    $t->ua($mock);

    # Have to do absolute URLs here because otherwise playback breaks. :(
    $t->get_ok( $url->clone->path('/') )->status_is(200)->content_is('index page');
    $t->get_ok( $url->clone->path('/userinfo') )->status_is(200)->json_is( '/name' => 'Joe Blow' )->json_like( '/key' => qr/^\d+$/ );
    $key = $t->tx->res->json('/key');
    $t->get_ok( $url->clone->path('/random') )->status_is(200); 
    $numbers = $t->tx->res->json();
    $mock->save;
    BAIL_OUT('Output file does not exist') unless ok -e $output_file;
};

subtest 'internal Mojolicious app' => sub {
    my $mock =
        Mojo::UserAgent::Mockable->new( ioloop => Mojo::IOLoop->singleton, mode => 'playback', file => $output_file );
    ok $mock->server->app ne Application::app, q{Internal app and local Mojlicious::Lite app differ};
};


subtest 'playback in order' => sub { 
    my $mock = Mojo::UserAgent::Mockable->new(ioloop => Mojo::IOLoop->singleton, mode => 'playback', file => $output_file);
    
    my $t    = Test::Mojo->new;
    $t->ua($mock);
    
    $t->get_ok( $url->clone->path('/') )->status_is(200)->content_is('index page');
    $t->get_ok( $url->clone->path('/userinfo') )->status_is(200)->json_is( { 'name' => 'Joe Blow', key => $key } );
    $t->get_ok( $url->clone->path('/random') )->status_is(200)->json_is( $numbers ); 
};

subtest 'playback out of order' => sub { 
    my $mock = Mojo::UserAgent::Mockable->new(ioloop => Mojo::IOLoop->singleton, mode => 'playback', file => $output_file);
   
    throws_ok { $mock->get( $url->clone->path('/random') ) } qr/^Unrecognized request/;
    throws_ok { $mock->get( $url->clone->path('/userinfo') ) } qr/^Unrecognized request/;
};

subtest 'playback in order, bad credentials' => sub {
    my $mock = Mojo::UserAgent::Mockable->new(ioloop => Mojo::IOLoop->singleton, mode => 'playback', file => $output_file);
    my $url = $url->clone->userinfo('bad:wolf');

    throws_ok { $mock->get( $url->clone->path('/') ) } qr{^Unrecognized request};
    throws_ok { $mock->get( $url->clone->path('/userinfo') ) } qr{^Unrecognized request};
    throws_ok { $mock->get( $url->clone->path('/random') ) } qr{^Unrecognized request};
};

done_testing;
