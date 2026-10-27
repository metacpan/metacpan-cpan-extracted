use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
    plan skip_all => 'Dancer2 is not installed' unless eval { require Dancer2; require Plack::Test; 1 };
    delete @ENV{qw(PRIVATUS_SITE_ID PRIVATUS_SCRIPT_HOST DANCER_ENVIRONMENT PLACK_ENV)};
}

use HTTP::Request::Common qw(GET);
use Plack::Test;

my $layout = '<html><head><title>Hi</title></head><body>ü</body></html>';

{

    package ProdApp;
    use Dancer2;

    BEGIN {
        set environment => 'production';
        set plugins     => { PrivatusAnalytics => { site_id => 'pa_TEST123456', props => { plan => 'pro' } } };
        set logger      => 'Null';
    }
    use Dancer2::Plugin::PrivatusAnalytics;

    get '/tag'   => sub { privatus_analytics_tag( props => [ role => 'admin' ] ) };
    get '/event' => sub { privatus_event( 'Report exported', { format => 'csv' } ) };
    get '/click' => sub { privatus_click('pricing.cta') . '|' . privatus_click('has space') };
    get '/data'  => sub { join ',', privatus_event_data( 'Saved', a => 1 ), privatus_click_data('nav.home') };
    get '/page'  => sub { $layout };
    get '/nonce' => sub { var csp_nonce => 'abc'; privatus_analytics_tag() };
}

{

    package DevApp;
    use Dancer2;

    BEGIN {
        set environment => 'development';
        set plugins     => { PrivatusAnalytics => { site_id => 'pa_TEST123456', auto_inject => 1 } };
        set logger      => 'Null';
    }
    use Dancer2::Plugin::PrivatusAnalytics;

    get '/tag'   => sub { privatus_analytics_tag() };
    get '/event' => sub { privatus_event('Saved') };
    get '/page'  => sub { $layout };
}

{

    package InjectApp;
    use Dancer2;

    BEGIN {
        set environment => 'production';
        set plugins =>
          { PrivatusAnalytics => { site_id => 'pa_TEST123456', auto_inject => 1, props => { city => 'Zürich' } } };
        set logger => 'Null';
    }
    use Dancer2::Plugin::PrivatusAnalytics;

    get '/page'    => sub { $layout };
    get '/has'     => sub { '<head><script src="/js/pa.js"></script></head>' };
    get '/missing' => sub { status 404;                      $layout };
    get '/json'    => sub { content_type 'application/json'; '{"a":"</head>"}' };
}

my $prod = Plack::Test->create( ProdApp->to_app );
is(
    $prod->request( GET '/tag' )->content,
    qq{<script>window.privatusPageProps=function(){return {"plan":"pro","role":"admin"}}</script>\n}
      . '<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_TEST123456" data-props="privatusPageProps"></script>',
    'the tag with configured and per call props'
);
is(
    $prod->request( GET '/event' )->content,
    'data-privatus-event="Report exported" data-privatus-prop-format="csv"',
    'privatus_event'
);
is( $prod->request( GET '/click' )->content, 'data-privatus-click="pricing.cta"|', 'privatus_click' );
is(
    $prod->request( GET '/data' )->content,
    'data-privatus-event,Saved,data-privatus-prop-a,1,data-privatus-click,nav.home',
    'data lists'
);
unlike( $prod->request( GET '/page' )->content, qr/pa\.js/, 'no auto inject by default' );
like(
    $prod->request( GET '/nonce' )->content,
    qr/<script nonce="abc">window.privatusPageProps/,
    'the csp_nonce var is used'
);

my $dev = Plack::Test->create( DevApp->to_app );
is( $dev->request( GET '/tag' )->content,   '',                            'off outside production' );
is( $dev->request( GET '/event' )->content, 'data-privatus-event="Saved"', 'event attributes still print' );
unlike( $dev->request( GET '/page' )->content, qr/pa\.js/, 'no auto inject outside production' );

my $inject = Plack::Test->create( InjectApp->to_app );
my $res    = $inject->request( GET '/page' );
like( $res->content,         qr{data-props="privatusPageProps"></script>\n</head>}, 'auto inject before </head>' );
like( $res->decoded_content, qr/"city":"Zürich"/, 'non ASCII props are encoded once' );
like( $res->decoded_content, qr/ü/,               'the body is kept' );
is( $res->header('Content-Length'), length $res->content, 'Content-Length matches' );

my @found = $inject->request( GET '/has' )->content =~ m{/js/pa\.js}g;
is( scalar @found, 1, 'a page with the tag is left alone' );
unlike( $inject->request( GET '/missing' )->content, qr/pa\.js/,  'only status 200' );
unlike( $inject->request( GET '/json' )->content,    qr/pa_TEST/, 'only HTML' );
unlike( $inject->request( GET '/page', 'X-Requested-With' => 'XMLHttpRequest' )->content, qr/pa\.js/, 'not for Ajax' );

done_testing;
