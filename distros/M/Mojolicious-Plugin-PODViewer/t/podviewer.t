use Mojo::Base -strict;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Test::Mojo;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use Mojolicious::Lite;

# POD viewer plugin
my $route = app->routes->any( '/perldoc' );
plugin('PODViewer' => {
    default_module => 'MojoliciousTest::Default',
    allow_modules => [qw( MojoliciousTest )],
    route => $route,
});

# Default layout
app->defaults(layout => 'gray');

get '/' => sub {
  my $c = shift;
  $c->render('simple', handler => 'pod');
};

post '/' => 'index';

post '/block';

get '/art';

get '/empty' => {inline => '', handler => 'pod'};

my $t = Test::Mojo->new;

# Simple POD template
$t->get_ok('/')->status_is(200)
  ->content_like(qr!<h1 id="Test123">Test123</h1>!)
  ->content_like(qr|<p>It <code>works</code>!</p>|);

# POD helper
$t->post_ok('/')->status_is(200)->content_like(qr!test123<h1 id="A">A</h1>!)
  ->content_like(qr!<h1 id="B">B</h1>!)
  ->content_like(qr!\s+<p><code>test</code></p>!)->content_like(qr/Gray/);

# POD filter
$t->post_ok('/block')->status_is(200)
  ->content_like(qr!test321<h2 id="lalala">lalala</h2>!)
  ->content_like(qr!<pre><code>\{\n  foo\(\);\n\}</code></pre>!)
  ->content_like(qr!<p><code>test</code></p>!)->content_like(qr/Gray/);

# Mixed indentation
$t->get_ok('/art')->status_is(200)->text_like('h2[id="art"]' => qr/art/)
  ->text_like('pre code' => qr/\s{2}#\n#\s{3}#\n\s{2}#/);

# Empty
$t->get_ok('/empty')->status_is(200)->content_is('');

# Default module
$t->get_ok( '/perldoc' )->status_is( 200 )
  ->element_exists( 'h1#Default-Page' )
  ->element_exists( '.crumbs > a[href=/perldoc/MojoliciousTest]', 'parent module in crumbtrail' )
  ->element_exists( '.crumbs > a[href=/perldoc]', 'default module in crumbtrail' )
  ->element_exists( '.crumbs .more a[href=https://metacpan.org/pod/MojoliciousTest::Default]', 'cpan link' )
  ->element_exists( '.crumbs .more a[href=/perldoc/MojoliciousTest/Default.txt]', 'source link' )
  ;

#diag $t->tx->res->body;

# Headings
$t->get_ok('/perldoc/MojoliciousTest/PODTest')->status_is(200)
  ->element_exists('h1#One')->element_exists('h2#Two')
  ->element_exists('h3#Three')->element_exists('h4#Four')
  ->element_exists('a[href=#One]')->element_exists('a[href=#Two]')
  ->element_exists('a[href=#Three]')->element_exists('a[href=#Four]')
  ->element_exists( '.crumbs > a[href=/perldoc/MojoliciousTest]', 'parent module in crumbtrail' )
  ->element_exists( '.crumbs > a[href=/perldoc/MojoliciousTest/PODTest]', 'current module in crumbtrail' )
  ->element_exists( '.crumbs .more a[href=https://metacpan.org/pod/MojoliciousTest::PODTest]', 'cpan link' )
  ->element_exists( '.crumbs .more a[href=/perldoc/MojoliciousTest/PODTest.txt]', 'source link' )
  ->text_like('pre code', qr/\$foo/);

# Trailing slash
$t->get_ok('/perldoc/MojoliciousTest/PODTest/')
  ->text_like('title', qr/PODTest/);

# Format
$t->get_ok('/perldoc/MojoliciousTest/PODTest.html')
  ->text_like('title', qr/PODTest/);

# Format (source)
$t->get_ok('/perldoc/MojoliciousTest/PODTest' => {Accept => 'text/plain'})
  ->status_is(200)->content_type_is('text/plain;charset=UTF-8')
  ->content_like(qr/package MojoliciousTest::PODTest/);

# Format (source with extension)
$t->get_ok('/perldoc/MojoliciousTest/PODTest.txt' =>
    {Accept => 'text/html,application/xhtml+xml,application/xml'})
  ->status_is(200)->content_type_is('text/plain;charset=UTF-8')
  ->content_like(qr/package MojoliciousTest::PODTest/);

# Negotiated source
$t->get_ok('/perldoc/MojoliciousTest/PODTest' => {Accept => 'text/plain'})
  ->status_is(200)->content_type_is('text/plain;charset=UTF-8')
  ->content_like(qr/package MojoliciousTest::PODTest/);

# Perldoc browser (unsupported format)
$t->get_ok('/perldoc/MojoliciousTest/PODTest.json')->status_is(404);

# Restrict to only desired set of modules
$t->get_ok('/perldoc/Mojolicious/Lite')->status_is(302)
  ->header_like( Location => qr{https://metacpan\.org/pod/Mojolicious::Lite} );

done_testing();

__DATA__

@@ layouts/gray.html.ep
<title><%= title %></title>
Gray <%= content %>

@@ index.html.ep
test123<%= pod_to_html "=head1 A\n\n=head1 B\n\nC<test>"%>

@@ block.html.ep
test321<%= pod_to_html begin %>=head2 lalala

  {
    foo();
  }

C<test><% end %>

@@ art.html.ep
<%= pod_to_html begin %>=head2 art

    #
  #   #
    #

<% end %>
