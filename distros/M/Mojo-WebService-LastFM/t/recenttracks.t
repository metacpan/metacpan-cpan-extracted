use Mojo::Base -strict;

use Test::More;
use Test::Fatal qw(dies_ok);
use Mojolicious::Lite;
use Mojo::Promise;
use Data::Dumper;

get '/app/' => sub {
    my $c = shift;

    $c->render(json => '{success: true}');
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
    my $json;

    my $expected = '{success: true}';

    # It doesn't really matter what the username is, we'll get a response back.
    $lastfm->recenttracks_p({ 'username' => 'testuser' })->then(sub{ is(shift, $expected, "Happy Path") })->wait();

    # Undefined username should croak
    dies_ok( sub { $lastfm->recenttracks_p({ 'username' => undef }) }, 'Undefined Username Croaks' );

    # No callback should perform a blocking call
    is( $lastfm->recenttracks({ 'username' => 'testuser' }), $expected, 'Undefined Callback - Blocking Call' );
}

main();

done_testing();
