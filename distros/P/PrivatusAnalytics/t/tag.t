use strict;
use warnings;
use Test::More;

use PrivatusAnalytics qw(inject_tag);

delete @ENV{qw(PRIVATUS_SITE_ID PRIVATUS_SCRIPT_HOST PLACK_ENV)};

sub pa { PrivatusAnalytics->new( site_id => 'pa_TEST123456', enabled => 1, @_ ) }

my $basic = '<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_TEST123456"></script>';

is( pa()->tag, $basic, 'prints the basic snippet' );
is( pa( site_id => undef )->tag, '', 'prints nothing without a site id' );
is( pa( site_id => '  ' )->tag,  '', 'a blank site id is no site id' );

{
    local $ENV{PRIVATUS_SITE_ID} = 'pa_FROMENV';
    like( pa( site_id => undef )->tag, qr/data-site="pa_FROMENV"/, 'the site id falls back to PRIVATUS_SITE_ID' );
}
{
    local $ENV{PRIVATUS_SCRIPT_HOST} = 'https://stats.example.com/';
    like( pa()->tag, qr{src="https://stats.example.com/js/pa.js"}, 'the host falls back to PRIVATUS_SCRIPT_HOST' );
}
like(
    pa( script_host => 'https://cdn.example.com/' )->tag,
    qr{src="https://cdn.example.com/js/pa.js"},
    'the trailing slash is removed'
);

subtest 'environments' => sub {
    my $pa = PrivatusAnalytics->new( site_id => 'pa_X' );
    is( $pa->tag, '', 'off outside production by default' );
    ok( !$pa->is_enabled('development'), 'not in development' );
    ok( $pa->is_enabled('production'),   'on in production' );
    is( PrivatusAnalytics->new( site_id => 'pa_X', environment => 'production' )->tag =~ /pa_X/ ? 1 : 0,
        1, 'environment setting' );
    local $ENV{PLACK_ENV} = 'production';
    like( $pa->tag, qr/pa_X/, 'PLACK_ENV is the plain fallback' );
    is( PrivatusAnalytics->new( site_id => 'pa_X', enabled => 0 )->tag, '', 'enabled => 0 forces it off' );
    like(
        PrivatusAnalytics->new( site_id => 'pa_X', environment => 'staging', enabled_environments => [qw(staging)] )
          ->tag,
        qr/pa_X/, 'enabled_environments'
    );
    like( PrivatusAnalytics->new( site_id => 'pa_X', environment => sub { 'production' } )->tag,
        qr/pa_X/, 'environment may be a code ref' );
};

my $tag = pa( modules => [qw(engage auto)], excluded_paths => [ '/admin/*', '/preview/*' ] )->tag;
like( $tag, qr/data-modules="engage,auto"/,           'modules' );
like( $tag, qr{data-exclude="/admin/\*,/preview/\*"}, 'excluded paths' );

like( pa( modules => [] )->tag, qr/data-modules=""/, 'an empty modules list loads none' );
unlike( pa( excluded_paths => [] )->tag, qr/data-exclude/, 'an empty exclude list prints nothing' );

$tag = pa( domains => 'example.com, www.example.com', spa => 'hash', manual => 1 )->tag;
like( $tag, qr/data-domains="example.com,www.example.com"/, 'domains from a comma string' );
like( $tag, qr/data-spa="hash"/,                            'spa mode' );
like( $tag, qr/data-manual="true"/,                         'manual mode' );

unlike( pa( spa => 'bogus' )->tag, qr/data-spa/, 'an unknown spa mode is ignored' );
unlike( pa( spa => 'auto' )->tag,  qr/data-spa/, 'auto is the default and not printed' );

like( pa( excluded_paths => ['/a"b'] )->tag, qr{data-exclude="/a&quot;b"}, 'values are escaped' );

like( pa( modules => ['engage'] )->tag( modules => ['vitals'] ),
    qr/data-modules="vitals"/, 'per call options override the settings' );
is( pa()->tag( enabled => 0 ), '', 'enabled can be overridden per call' );
like( pa()->tag( { site_id => 'pa_OTHER' } ), qr/pa_OTHER/, 'overrides as a hash ref' );

$tag = pa( extra_attributes => { 'data-mask' => '/orders/*->/orders/:id' } )->tag( nonce => 'abc123' );
like( $tag, qr{data-mask="/orders/\*-&gt;/orders/:id"},                             'extra attributes' );
like( $tag, qr/nonce="abc123"/,                                                     'nonce' );
like( pa( nonce => sub { "n-$_[0]" } )->tag( request => 'req' ), qr/nonce="n-req"/, 'nonce code ref gets the request' );

eval { PrivatusAnalytics->new( site_idd => 'x' ) };
like( $@, qr/Unknown PrivatusAnalytics setting 'site_idd'/, 'unknown settings are an error' );

subtest 'page props' => sub {
    my $html  = pa()->tag( props => [ plan => 'pro', role => 'admin' ] );
    my $props = '<script>window.privatusPageProps=function(){return {"plan":"pro","role":"admin"}}</script>';
    my $tracker =
      '<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_TEST123456" data-props="privatusPageProps"></script>';
    is( $html, "$props\n$tracker", 'props print an inline script before the tag and data-props on it' );

    like(
        pa()->tag( props => { plan => 'pro' }, nonce => 'abc' ),
        qr/\A<script nonce="abc">window.privatusPageProps=/,
        'the props script gets the nonce'
    );
    unlike( pa()->tag( props => { plan => undef } ), qr/privatusPageProps/, 'empty props print nothing extra' );
    like( pa( props => { plan => 'pro' } )->tag, qr/\{"plan":"pro"\}/, 'configured props can be a hash ref' );
    like( pa( props => sub { { plan => $_[0]{plan} } } )->tag( request => { plan => 'team' } ),
        qr/\{"plan":"team"\}/, 'configured props can be a code ref that gets the request' );
    like(
        pa( props => [ plan => 'pro', role => 'admin' ] )->tag( props => [ role => undef, tier => 'gold' ] ),
        qr/\{"plan":"pro","tier":"gold"\}/,
        'per call props merge over configured ones and undef removes one'
    );
    is( pa( enabled => 0, props => sub { die "should not run\n" } )->tag,
        '', 'the props code ref is not called when off' );
};

subtest 'queue stub' => sub {
    my $stub =
        q~window.privatus=window.privatus||{q:[]};['track','pageview','props','optOut','optIn','ready']~
      . q~.forEach(function(m){window.privatus[m]=window.privatus[m]||function(){window.privatus.q.push(~
      . q~[m,Array.prototype.slice.call(arguments)])}})~;
    is( PrivatusAnalytics::QUEUE_STUB, $stub, 'the queue stub is the official one' );

    my @parts = split /\n/, pa( queue_stub => 1 )->tag( nonce => 'abc', props => { plan => 'pro' } );
    is( $parts[0], qq{<script nonce="abc">$stub</script>}, 'the stub prints first' );
    like( $parts[1], qr/privatusPageProps/, 'then the props' );
    like( $parts[2], qr{/js/pa\.js},        'then the tracker' );

    like( pa()->tag( queue_stub => 1 ), qr/q:\[\]/, 'the stub can be switched on per call' );
    unlike( pa()->tag, qr/q:\[\]/, 'off by default' );

    my $boom = sub { die "should not run\n" };
    is(
        pa( enabled => 0, queue_stub => 1, props => $boom )->tag( nonce => 'abc', props => { plan => 'pro' } ),
        qq{<script nonce="abc">$stub</script>},
        'off with the stub on prints exactly the stub, with the nonce'
    );
    is( pa( enabled => 0, queue_stub => 1 )->tag, "<script>$stub</script>", 'off with the stub on and no nonce' );
    is( pa( enabled => 0, queue_stub => 0 )->tag( props => { plan => 'pro' }, nonce => 'abc' ),
        '', 'off with the stub off prints nothing' );
    is(
        pa( site_id => undef, queue_stub => 1 )->tag( nonce => 'abc', props => { plan => 'pro' } ),
        qq{<script nonce="abc">$stub</script>},
        'no site id with the stub on prints only the stub'
    );
    is(
        PrivatusAnalytics->new( site_id => 'pa_X', queue_stub => 1 )->tag,
        "<script>$stub</script>",
        'outside production with the stub on prints only the stub'
    );
    is( pa()->tag( enabled => 0, queue_stub => 1 ), "<script>$stub</script>", 'per call off and stub on' );
    ok(
        !pa( auto_inject => 1, enabled => 0, queue_stub => 1 )
          ->wants_inject( status => 200, content_type => 'text/html' ),
        'auto inject still adds nothing when off'
    );
};

subtest 'inject' => sub {
    my $pa = pa( auto_inject => 1 );
    my %ok = ( status => 200, content_type => 'text/html; charset=UTF-8' );
    ok( $pa->wants_inject(%ok),                                        'HTML 200' );
    ok( !pa()->wants_inject(%ok),                                      'not without auto_inject' );
    ok( !$pa->wants_inject( %ok, status => 404 ),                      'not for other statuses' );
    ok( !$pa->wants_inject( %ok, content_type => 'application/json' ), 'not for other types' );
    ok( !$pa->wants_inject( %ok, content_encoding => 'gzip' ),         'not when encoded' );
    ok( !$pa->wants_inject( %ok, requested_with => 'XMLHttpRequest' ), 'not for Ajax' );
    ok( !$pa->wants_inject( %ok, ) == !$pa->should_render,             'needs a tag' );
    ok( !pa( auto_inject => 1, enabled => 0 )->wants_inject(%ok),      'not when off' );

    is( inject_tag( '<html><HEAD></HEAD></html>', 'TAG' ), "<html><HEAD>TAG\n</head></html>", 'before </head>' );
    is( inject_tag( '<p>no head</p>',             'TAG' ), '<p>no head</p>',                  'no head, no change' );
    my $has = '<head><script src="/js/pa.js"></script></head>';
    is( inject_tag( $has, 'TAG' ), $has, 'already has the tag' );
};

done_testing;
