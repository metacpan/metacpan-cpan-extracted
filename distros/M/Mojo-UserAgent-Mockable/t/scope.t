use 5.014;

package Application;
use Mojolicious::Lite;
use Mojolicious::Plugin::BasicAuthPlus;

# Don't store passwords in cleartext, kids
my %PASSWD = ( 'joeblow' => { uid => 1138, password => 'foobar' }, );

my %USERINFO = ( 1138 => { name => 'Joe Blow' }, );

plugin 'BasicAuthPlus';

app->log->level('fatal');

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
};

get '/' => sub {
    my $self = shift;
    $self->render( text => 'index page' );
};


package main;

use File::stat;
use File::Temp;
use Mojo::UserAgent::Mockable;
use Mojo::Server::Daemon;
use Mojo::IOLoop;

use Test::Most;

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
my $output_file = qq{$dir/scoping.json};

{
    my $mock =
        Mojo::UserAgent::Mockable->new( ioloop => Mojo::IOLoop->singleton, mode => 'record', file => $output_file );
    $mock->get( $url->clone->path('/random') );
}

BAIL_OUT q{Output file not written!} unless ok -e $output_file, q{Output file exists};
my $st = stat($output_file);
ok $st->size > 0, q{Output file has nonzero size};
done_testing;
