use Mojo::Base -strict;

use Test::More;
use Test::Fatal qw(dies_ok);
use Mojolicious::Lite;
use Mojo::Promise;

get '/app/' => sub {
    my $c = shift;

    # Need a somewhat valid json structure for the sub to dissect.
    my $json = {
        'recenttracks' => {
            'track' => [
                {
                    'artist' => {
                        '#text' => 'Artist',
                    },
                    'name' => 'Title',
                    'album' => {
                        '#text' => 'Album',
                    },
                    'date' => 'today',
                    'image' => 'image.jpg',
                },
            ],
        },
    };

    my $invalid = {
        'error' => 'invalid user',
    };

    my $username = $c->param('user');
    $username eq 'testuser' ? $c->render(json => $json) : $c->render(json => $invalid);
};

app->log->level('fatal');
app->start();

##########################

require_ok( 'Mojo::WebService::LastFM' );


my $lastfm = Mojo::WebService::LastFM->new(
    'api_key' => 'abc123',
    'base_url' => '/app'
);
$lastfm->ua->server->app(app);

sub main
{
    my $expected = {
        'artist' => 'Artist',
        'album' => 'Album',
        'title' => 'Title',
        'date'  => 'today',
        'image' => 'image.jpg',
    };

    my $invalid = {
        'error' => 'invalid user',
    };

    # Happy path - Hashref
    $lastfm->nowplaying_p({ 'username' => 'testuser' })->then(sub
    { 
        my $got = shift;
        is_deeply($got, $expected, 'Valid User - Hashref');
    })->wait;

    # Happy path - Scalar
    $lastfm->nowplaying_p('testuser')->then(sub
    { 
        my $got = shift;
        is_deeply($got, $expected, 'Valid User - Scalar');
    })->wait;

    dies_ok( sub { $lastfm->nowplaying_p(()) }, 'Hash dies' );
    dies_ok( sub { $lastfm->nowplaying_p([]) }, 'Arrayref dies' );

    # While the username is valid, the response lacks the necessary fields and it will send an exception
    $lastfm->nowplaying_p({ 'username' => 'failuser' })->then(sub
    { 
        isa_ok(shift, 'Mojo::Exception');
    })->wait;

    # Undefined username should croak without calling anything
    dies_ok( sub { $lastfm->nowplaying_p({ 'username' => undef }) }, 'Undefined Username Croaks' );

    # No callback - Blocking call
    is_deeply( $lastfm->nowplaying('testuser'), $expected, 'Undefined Callback - Blocking Call' );
}

main();

done_testing();
