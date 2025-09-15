use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use lib 'lib';

# Configure the plugin
plugin 'Inertia' => {
    version => '1.0.0',
    layout  => '<div id="app" data-page="<%= $data_page %>"></div>'
};

# Test route
get '/' => sub {
    my $c = shift;
    $c->inertia('Home', { message => 'Hello World' });
};

my $t = Test::Mojo->new;

# Test regular HTTP request (non-Inertia)
$t->get_ok('/')
  ->status_is(200)
  ->content_type_like(qr/html/)
  ->content_like(qr/data-page/)
  ->content_like(qr/&quot;component&quot;:&quot;Home&quot;/)
  ->content_like(qr/&quot;message&quot;:&quot;Hello World&quot;/)
  ->content_like(qr/&quot;version&quot;:&quot;1.0.0&quot;/);

done_testing();