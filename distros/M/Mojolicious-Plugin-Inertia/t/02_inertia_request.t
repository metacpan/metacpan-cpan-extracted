use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::JSON qw(decode_json);
use lib 'lib';

plugin 'Inertia' => {
    version => '1.0.0',
    layout  => '<div id="app" data-page="<%= $data_page %>"></div>'
};

get '/test' => sub {
    my $c = shift;
    $c->inertia('TestComponent', {
        user => { name => 'Alice', id => 123 },
        posts => [
            { id => 1, title => 'First Post' },
            { id => 2, title => 'Second Post' }
        ]
    });
};

my $t = Test::Mojo->new;

# Test Inertia XHR request
$t->get_ok('/test' => {'X-Inertia' => 'true'})
  ->status_is(200)
  ->header_is('X-Inertia' => 'true')
  ->header_is('Vary' => 'X-Inertia')
  ->content_type_like(qr/json/)
  ->json_is('/component' => 'TestComponent')
  ->json_is('/props/user/name' => 'Alice')
  ->json_is('/props/user/id' => 123)
  ->json_is('/props/posts/0/title' => 'First Post')
  ->json_is('/version' => '1.0.0')
  ->json_like('/url' => qr{/test$});

# Test regular request returns HTML
$t->get_ok('/test')
  ->status_is(200)
  ->header_is('Vary' => 'X-Inertia')
  ->content_type_like(qr/html/)
  ->content_unlike(qr/^{/)  # Should not start with JSON
  ->content_like(qr/data-page/);

done_testing();