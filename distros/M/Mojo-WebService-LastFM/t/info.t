use Mojo::Base -strict;

use Test::More;
use Test::Fatal qw(dies_ok);
use Mojolicious::Lite;
use Mojo::Promise;

get '/app/' => sub {
    my $c = shift;

    my $json = { 'success' => 'true' }; 
    $c->render(json => $json);
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
    my $expected = { 'success' => 'true' };

    # It doesn't really matter what the username is, we'll get a response back.
    $lastfm->info_p('testuser')->then(sub{ is_deeply(shift, $expected, "Happy Path") })->wait();

    # Undefined username should croak
    dies_ok( sub { $lastfm->info_p(undef) }, 'Undefined Username Croaks' );

    # No callback should be a blocking call
    is_deeply( $lastfm->info('testuser'), $expected, 'Undefined Callback - Blocking Call' );
}

main();

done_testing();
