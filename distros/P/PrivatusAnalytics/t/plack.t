use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
    plan skip_all => 'Plack is not installed' unless eval { require Plack::Test; require Plack::Builder; 1 };
}

use Encode                qw(encode_utf8 decode_utf8);
use HTTP::Request::Common qw(GET);
use Plack::Builder;
use Plack::Test;

delete @ENV{qw(PRIVATUS_SITE_ID PRIVATUS_SCRIPT_HOST)};

my $page = encode_utf8('<html><head><title>Hi</title></head><body>ü</body></html>');

sub app_with {
    my ( $settings, $response ) = @_;
    my $app = sub {
        my $env = shift;
        return $response
          ? $response->($env)
          : [ 200, [ 'Content-Type' => 'text/html; charset=utf-8', 'Content-Length' => length $page ], [$page] ];
    };
    return Plack::Test->create(
        builder { enable 'PrivatusAnalytics', site_id => 'pa_TEST123456', %{$settings}; $app } );
}

{
    local $ENV{PLACK_ENV} = 'deployment';
    my $res = app_with( {} )->request( GET '/' );
    like(
        $res->content,
        qr{<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_TEST123456"></script>\n</head>},
        'injected before </head> under PLACK_ENV=deployment'
    );
    is( $res->header('Content-Length'), length $res->content, 'Content-Length is fixed' );
    like( decode_utf8( $res->content ), qr/ü/, 'the body is kept' );
}
{
    local $ENV{PLACK_ENV} = 'production';
    like( app_with( {} )->request( GET '/' )->content, qr/pa\.js/, 'on under PLACK_ENV=production' );
}
{
    local $ENV{PLACK_ENV} = 'development';
    unlike( app_with( {} )->request( GET '/' )->content, qr/pa\.js/, 'off in development' );
    like( app_with( { enabled => 1 } )->request( GET '/' )->content, qr/pa\.js/, 'enabled forces it on' );
}

my %on = ( enabled => 1 );

like(
    app_with( { %on, props => sub { { path => $_[0]->path_info, plan => 'pro' } }, nonce => sub { $_[0]{nonce} } },
        undef )->request( GET '/x' )->content,
    qr/window.privatusPageProps=function\(\)\{return \{"path":"\/x","plan":"pro"\}\}/,
    'props code ref gets a Plack::Request'
);

like( app_with( { %on, props => { city => 'Zürich' } } )->request( GET '/' )->content,
    qr/"city":"Z\xc3\xbcrich"/, 'non ASCII props are encoded as UTF-8' );

my $nonce_app = app_with( { %on, props => { plan => 'pro' } },
    sub { $_[0]{'plack.csp_nonce'} = 'abc'; [ 200, [ 'Content-Type' => 'text/html' ], [$page] ] } );
like(
    $nonce_app->request( GET '/' )->content,
    qr/<script nonce="abc">window.privatusPageProps/,
    'plack.csp_nonce is used'
);

my @skip = (
    [ 'status 404', sub { [ 404, [ 'Content-Type' => 'text/html' ],        [$page] ] } ],
    [ 'JSON',       sub { [ 200, [ 'Content-Type' => 'application/json' ], ['{"a":"</head>"}'] ] } ],
    [ 'gzip',       sub { [ 200, [ 'Content-Type' => 'text/html', 'Content-Encoding' => 'gzip' ], [$page] ] } ],
    [ 'no head',    sub { [ 200, [ 'Content-Type' => 'text/html' ],                               ['<p>hi</p>'] ] } ],
    [
        'has tag',
        sub { [ 200, [ 'Content-Type' => 'text/html' ], ['<head><script src="/js/pa.js"></script></head>'] ] }
    ],
    [
        'streaming',
        sub {
            sub { my $w = shift->( [ 200, [ 'Content-Type' => 'text/html' ] ] ); $w->write($page); $w->close }
        }
    ],
);
for my $case (@skip) {
    my ( $name, $app ) = @{$case};
    my @tags = app_with( \%on, $app )->request( GET '/' )->content =~ m{/js/pa\.js}g;
    ok( @tags <= 1 && !grep( { /pa_TEST123456/ } app_with( \%on, $app )->request( GET '/' )->content ),
        "left alone: $name" );
}

my $ajax = app_with( \%on )->request( GET '/', 'X-Requested-With' => 'XMLHttpRequest' );
unlike( $ajax->content, qr/pa\.js/, 'not for Ajax' );

my $fh_app = app_with( \%on, sub { open my $fh, '<', \$page or die; [ 200, [ 'Content-Type' => 'text/html' ], $fh ] } );
like( $fh_app->request( GET '/' )->content, qr/pa\.js/, 'file handle bodies work' );

unlike( app_with( { %on, auto_inject => 0 } )->request( GET '/' )->content,
    qr/pa\.js/, 'auto_inject => 0 turns it off' );

done_testing;
