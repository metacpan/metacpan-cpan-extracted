use 5.014;

package Application;
use Mojolicious::Lite;
use Mojolicious::Plugin::BasicAuthPlus;

# Don't store passwords in cleartext, kids
my %PASSWD = ( 'joeblow' => { uid => 1138, password => 'foobar' }, );

plugin 'BasicAuthPlus';

group {
    under sub {
        my $c = shift;

        my $auth = sub {
            my ( $username, $password ) = @_;
            no warnings qw/uninitialized/;
            if ( $PASSWD{$username}{'password'} eq $password ) {
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

        $c->session(expiration => 60);
        
        my $num = $c->req->param('num') || 5;
        my $min = $c->req->param('min') || 0;
        my $max = $c->req->param('max') || 1e9;

        my @numbers = map { int rand( $max - $min ) + $min } ( 1 .. $num );
        $c->session->{history} ||= [];
        push @{$c->session->{history}}, \@numbers;

        $c->render( json => \@numbers );
    };

    get '/history' => sub {
        my $c = shift;
        $c->render( json => $c->session->{history} );
    };
};

get '/' => sub {
    my $self = shift;
    $self->render( text => 'index page' );
};

app->log->level('fatal');

package main;

use Array::Compare;
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
my $output_file = qq{$dir/session_test.json};

my $number_count = 5;
my $txn_count = 10;

my (@history, @urls);
{
    my $mock = Mojo::UserAgent::Mockable->new(ioloop => Mojo::IOLoop->singleton, mode => 'record', file => $output_file);

    for ( 1 .. $txn_count ) {
        my $url = $url->clone->path('/random')->query(num => $number_count, txn_num => $_ ); 
        my $numbers = $mock->get($url)->res->json;
        BAIL_OUT('Numbers came back wrong!') unless ref $numbers eq 'ARRAY' && scalar @{$numbers} eq $number_count;
        push @history, $numbers;
        push @urls, $url;
    }

    BAIL_OUT('Transaction count does not match number of transactions in history') unless scalar @history eq $txn_count;

    my $history_from_session = $mock->get($url->clone->path('/history'))->res->json;
    BAIL_OUT('History from session is not correct') unless Array::Compare->new->full_compare($history_from_session, \@history);

    $mock->save;
    BAIL_OUT('Output file does not exist') unless -e $output_file;
};

my $mock = Mojo::UserAgent::Mockable->new(ioloop => Mojo::IOLoop->singleton, mode => 'playback', file => $output_file);

for ( 0 .. $#urls) {
    my $url = $urls[$_];
    is_deeply($mock->get($url)->res->json, $history[$_], 'Numbers from playback match');
}

my $history_from_session = $mock->get($url->clone->path('/history'))->res->json;
is_deeply($history_from_session, \@history, 'History from playback matches');

done_testing;
