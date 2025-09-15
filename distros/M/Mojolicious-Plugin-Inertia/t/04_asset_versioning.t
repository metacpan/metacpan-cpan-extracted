use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use lib 'lib';

plugin 'Inertia' => {
    version => 'v1.2.3',
    layout  => '<div id="app" data-page="<%= $data_page %>"></div>'
};

get '/page' => sub {
    my $c = shift;
    $c->inertia('Page', { title => 'Test Page' });
};

my $t = Test::Mojo->new;

# Test version mismatch - should return 409 with location header
$t->get_ok('/page' => {'X-Inertia-Version' => 'v1.0.0'})
  ->status_is(409)
  ->header_like('X-Inertia-Location' => qr{/page$});

# Test matching version - should return normal response
$t->get_ok('/page' => {
    'X-Inertia' => 'true',
    'X-Inertia-Version' => 'v1.2.3'
  })
  ->status_is(200)
  ->json_is('/component' => 'Page')
  ->json_is('/version' => 'v1.2.3');

# Test POST request with version mismatch - should not trigger 409
$t->post_ok('/page' => {'X-Inertia-Version' => 'v1.0.0'} => json => {data => 'test'})
  ->status_isnt(409);

# Test without version header - should work normally
$t->get_ok('/page' => {'X-Inertia' => 'true'})
  ->status_is(200)
  ->json_is('/component' => 'Page')
  ->json_is('/version' => 'v1.2.3');

done_testing();