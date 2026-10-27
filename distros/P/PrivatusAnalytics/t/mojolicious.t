use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
    plan skip_all => 'Mojolicious is not installed' unless eval { require Mojolicious; require Test::Mojo; 1 };
}

use Mojolicious::Lite;
use Test::Mojo;

delete @ENV{qw(PRIVATUS_SITE_ID PRIVATUS_SCRIPT_HOST)};

app->log->level('fatal');

sub make_app {
    my (%conf) = @_;
    my $app = Mojolicious->new( mode => delete $conf{mode} // 'production' );
    $app->log->level('fatal');
    $app->plugin( PrivatusAnalytics => { site_id => 'pa_TEST123456', %conf } );
    push @{ $app->renderer->classes }, 'main';
    my $r = $app->routes;
    $r->get('/')->to( cb => sub { shift->render( template => 'home' ) } );
    $r->get('/plain')->to( cb => sub { shift->render( template => 'plain' ) } );
    $r->get('/props')->to( cb => sub { shift->render( template => 'props' ) } );
    $r->get('/nonce')
      ->to( cb => sub { my $c = shift; $c->stash( csp_nonce => 'n0nce' ); $c->render( template => 'props' ) } );
    $r->get('/has')->to( cb => sub { shift->render( template => 'has' ) } );
    $r->get('/missing')->to( cb => sub { shift->render( template => 'plain', status => 404 ) } );
    $r->get('/json')->to( cb => sub { shift->render( json => { head => '</head>' } ) } );
    $r->get('/text')->to( cb => sub { shift->render( text => '<html><head></head><body>ü</body></html>' ) } );
    return Test::Mojo->new($app);
}

my $t = make_app();
$t->get_ok('/')
  ->status_is(200)
  ->element_exists('head script[src="https://privatusstats.com/js/pa.js"][data-site="pa_TEST123456"]')
  ->content_like(qr/<button data-privatus-event="Report exported" data-privatus-prop-format="csv">/)
  ->content_like(qr/<a href="\/pricing" data-privatus-click="pricing.cta">/)
  ->content_like(qr/<a >nope<\/a>/)
  ->content_like(qr/<a data-privatus-event="Guide opened" href="\/guide">Guide<\/a>/)
  ->content_like(qr/<span data-privatus-click="nav.home">x<\/span>/);
unlike( $t->tx->res->body, qr/data-privatus-click="has space"/, 'an invalid click name prints nothing' );

$t->get_ok('/plain')->status_is(200)->content_unlike( qr/pa\.js/, 'no auto inject by default' );

$t = make_app( mode => 'development' );
$t->get_ok('/')
  ->status_is(200)
  ->content_unlike( qr/pa\.js/, 'off outside production' )
  ->content_like( qr/data-privatus-event="Report exported"/, 'event attributes still print' );

$t = make_app( mode => 'development', enabled => 1 );
$t->get_ok('/')->content_like( qr/pa\.js/, 'enabled forces it on' );

$t = make_app( props => sub { my $c = shift; { plan => 'pro', path => $c->req->url->path->to_string } } );
$t->get_ok('/props')
  ->content_like(
    qr/<script>window.privatusPageProps=function\(\)\{return \{"path":"\/props","plan":"pro","section":"billing"\}\}<\/script>/
  )->content_like(qr/data-props="privatusPageProps"/);
$t->get_ok('/nonce')
  ->content_like( qr/<script nonce="n0nce">window.privatusPageProps/,          'csp_nonce stash value' )
  ->content_like( qr/nonce="n0nce" data-props="privatusPageProps"><\/script>/, 'the tracker gets the nonce too' );

$t = make_app( nonce => sub { 'from-' . ref shift } );
$t->get_ok('/props')->content_like( qr/nonce="from-Mojolicious::Controller"/, 'nonce code ref gets the controller' );

$t = make_app( auto_inject => 1, props => { plan => 'pro' } );
$t->get_ok('/plain')
  ->status_is(200)
  ->element_exists('head script[src$="/js/pa.js"]')
  ->content_like( qr/<\/script>\n<\/head>/, 'injected just before </head>' );
my $length = $t->tx->res->headers->content_length;
is( $length, $t->tx->res->content->asset->size, 'Content-Length matches the body' );

$t->get_ok('/has')->status_is(200);
my @found = $t->tx->res->body =~ m{/js/pa\.js}g;
is( scalar @found, 1, 'a page with the tag is left alone' );

$t->get_ok('/missing')->status_is(404)->content_unlike( qr/pa\.js/, 'only status 200' );
$t->get_ok('/json')->content_unlike( qr/pa\.js/, 'only HTML' );
$t->get_ok( '/plain', { 'X-Requested-With' => 'XMLHttpRequest' } )->content_unlike( qr/pa\.js/, 'not for Ajax' );
$t->get_ok('/text')->content_like( qr/pa\.js/, 'text rendered as html format' )->content_like( qr/ü/, 'text kept' );

$t = make_app( auto_inject => 1, props => { city => 'Zürich' } );
$t->get_ok('/plain')->content_like( qr/"city":"Zürich"/, 'non ASCII props are encoded once' );

$t = make_app( auto_inject => 1, mode => 'development' );
$t->get_ok('/plain')->content_unlike( qr/pa\.js/, 'auto inject is off outside production' );

done_testing;

__DATA__
@@ home.html.ep
<html><head><title>Home</title>
%= privatus_analytics_tag
</head><body>
<button <%= privatus_event 'Report exported', { format => 'csv' } %>>Export</button>
<a href="/pricing" <%= privatus_click 'pricing.cta' %>>See plans</a>
<a <%= privatus_click 'has space' %>>nope</a>
%= link_to Guide => '/guide', privatus_event_data('Guide opened')
%= tag span => (privatus_click_data('nav.home')) => 'x'
</body></html>

@@ plain.html.ep
<html><head><title>Plain</title></head><body>Hi</body></html>

@@ props.html.ep
<html><head>
%= privatus_analytics_tag props => { section => 'billing' }
</head><body>Props</body></html>

@@ has.html.ep
<html><head><script defer src="https://privatusstats.com/js/pa.js" data-site="pa_OWN"></script></head><body></body></html>
