use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use lib 'lib';

# Test with history encryption enabled by default
plugin 'Inertia' => {
    version => '1.0.0',
    layout  => '<div id="app" data-page="<%= $data_page %>"></div>',
    encrypt_history => 1,
    clear_history => 0
};

get '/default' => sub {
    my $c = shift;
    $c->inertia('Page', { data => 'test' });
};

get '/override' => sub {
    my $c = shift;
    $c->inertia('Page', { data => 'test' }, {
        encrypt_history => 0,
        clear_history => 1
    });
};

my $t = Test::Mojo->new;

# Test default history encryption settings
$t->get_ok('/default' => {'X-Inertia' => 'true'})
  ->status_is(200)
  ->json_is('/encryptHistory' => 1)
  ->json_is('/clearHistory' => 0);

# Test overriding history settings per request
$t->get_ok('/override' => {'X-Inertia' => 'true'})
  ->status_is(200)
  ->json_is('/encryptHistory' => 0)
  ->json_is('/clearHistory' => 1);

# Test HTML response includes history settings
$t->get_ok('/default')
  ->status_is(200)
  ->content_like(qr/&quot;encryptHistory&quot;:1/)
  ->content_like(qr/&quot;clearHistory&quot;:0/);

done_testing();