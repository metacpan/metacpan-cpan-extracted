#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use Test::More;
use Open::API;
use Open::API::Plack;
use File::Raw::JSON qw(file_json_decode);

# Same guard as t/23: the versions, not just the module names, and the
# perl the UI needs rather than the one the distribution promises.
plan skip_all => 'the docs UI needs perl 5.010'
    if $] < 5.010;
plan skip_all => 'Template::Stencil 0.02+ and Markdown::Simple 0.18+ '
              . 'are not available'
    unless eval { require Template::Stencil;
                  Template::Stencil->VERSION('0.02');
                  require Markdown::Simple;
                  Markdown::Simple->VERSION('0.18'); 1 };

my $SPEC = "$FindBin::Bin/spec/petstore.json";

sub run_app {
    my ($app, %o) = @_;
    my $body = defined $o{body} ? $o{body} : '';
    open my $in, '<', \$body or die;
    return $app->({
        REQUEST_METHOD => $o{method} || 'GET',
        PATH_INFO      => $o{path}   || '/',
        QUERY_STRING   => $o{query}  || '',
        CONTENT_TYPE   => ($body ne '' ? 'application/json' : ''),
        CONTENT_LENGTH => length $body,
        'psgi.input'   => $in,
        %{ $o{env} || {} },
    });
}

sub header {
    my ($resp, $name) = @_;
    my @h = @{ $resp->[1] };
    while (my ($k, $v) = splice @h, 0, 2) {
        return $v if lc $k eq lc $name;
    }
    return undef;
}

# ---- ui => 1 serves the docs, the assets and the spec ------------------------
{
    my $plack = Open::API::Plack->new(spec => $SPEC, ui => 1,
        handlers => { listPets => sub { [ { id => 1, name => 'rex' } ] } });
    my $app = $plack->to_app;

    my $r = run_app($app, path => '/docs');
    is($r->[0], 200, 'GET /docs is 200');
    is(header($r, 'Content-Type'), 'text/html; charset=utf-8', 'docs are html');
    like($r->[2][0], qr/id="op-listPets"/, 'the page lists the operations');

    is(run_app($app, path => '/docs/')->[0], 200, 'trailing slash serves too');

    $r = run_app($app, path => '/docs/app.js');
    is($r->[0], 200, 'GET /docs/app.js is 200');
    is(header($r, 'Content-Type'), 'application/javascript; charset=utf-8',
        'js content type');
    $r = run_app($app, path => '/docs/app.css');
    is(header($r, 'Content-Type'), 'text/css; charset=utf-8', 'css content type');

    $r = run_app($app, path => '/openapi.json');
    is($r->[0], 200, 'GET /openapi.json is 200');
    is(header($r, 'Content-Type'), 'application/json', 'spec content type');
    is_deeply(file_json_decode($r->[2][0]), $plack->api->spec,
        'the served spec is the compiled document');
}

# ---- UI headers vs API headers ----------------------------------------------
{
    my $app = Open::API::Plack->new(spec => $SPEC, ui => 1,
        handlers => { listPets => sub { [] } })->to_app;

    my $ui = run_app($app, path => '/docs');
    like(header($ui, 'Content-Security-Policy'), qr/script-src 'self'/,
        'UI responses carry the docs CSP');
    is(header($ui, 'X-Content-Type-Options'), 'nosniff', 'UI nosniff');
    is(header($ui, 'X-Frame-Options'), 'DENY', 'UI frame options');

    my $api = run_app($app, path => '/pets');
    like(header($api, 'Content-Security-Policy'), qr/default-src 'none'/,
        'API responses keep the strict CSP');
    unlike(header($api, 'Content-Security-Policy'), qr/script-src/,
        'the docs CSP never leaks onto API responses');
}

# ---- everything else is byte-identical to a ui-less app ----------------------
{
    my $app = Open::API::Plack->new(spec => $SPEC, ui => 1,
        handlers => { listPets => sub { [] } })->to_app;

    is(run_app($app, path => '/pets')->[0], 200, 'spec route still serves');
    is(run_app($app, path => '/nope')->[0], 404, 'unknown paths still 404');
    is(run_app($app, path => '/pets/x')->[0], 400,
        'validation still runs (bad petId is 400)');
    is(run_app($app, method => 'POST', path => '/docs')->[0], 404,
        'POST /docs falls through to the router (404)');

    my $head = run_app($app, method => 'HEAD', path => '/docs');
    is($head->[0], 200, 'HEAD /docs is 200');
    is($head->[2][0], '', 'HEAD body is empty');

    my $plain = Open::API::Plack->new(spec => $SPEC,
        handlers => { listPets => sub { [] } })->to_app;
    is(run_app($plain, path => '/docs')->[0], 404,
        'without ui, /docs stays a 404');
}

# ---- custom path and spec_path ----------------------------------------------
{
    my $app = Open::API::Plack->new(spec => $SPEC,
        ui => { path => '/d', spec_path => '/s.json' },
        handlers => { listPets => sub { [] } })->to_app;
    is(run_app($app, path => '/d')->[0], 200, 'custom ui path serves');
    is(run_app($app, path => '/s.json')->[0], 200, 'custom spec path serves');
    is(run_app($app, path => '/docs')->[0], 404, 'the default path is not taken');
    like(run_app($app, path => '/d')->[2][0], qr{src="/d/app\.js"},
        'assets link under the custom path');
}

# ---- the csrf configuration reaches the page --------------------------------
{
    my $plack = Open::API::Plack->new(spec => $SPEC, ui => 1,
        handlers => { listPets => sub { [] } },
        csrf => { header => 'X-XSRF', cookie => 'xsrf',
                  check => sub { 0 } });
    my $r = run_app($plack->to_app, path => '/docs');
    my ($cfg) = $r->[2][0] =~ m{id="oa-config">(.*?)</script>}s;
    my $config = file_json_decode($cfg);
    is($config->{csrf}{header}, 'X-XSRF', 'csrf header name from the app');
    is($config->{csrf}{cookie}, 'xsrf', 'csrf cookie name from the app');

    my $plain = Open::API::Plack->new(spec => $SPEC, ui => 1,
        handlers => { listPets => sub { [] } });
    ($cfg) = run_app($plain->to_app, path => '/docs')->[2][0]
        =~ m{id="oa-config">(.*?)</script>}s;
    ok(!file_json_decode($cfg)->{csrf},
        'no csrf on the app: none in the page config');
}

# ---- accessor form, chaining, reconfiguration --------------------------------
{
    my $plack = Open::API::Plack->new(spec => $SPEC,
        handlers => { listPets => sub { [] } });
    my $ret = $plack->ui(1);
    is(ref $ret, 'Open::API::Plack', 'ui setter chains');
    is($plack->ui, 1, 'ui getter round-trips');
    is(run_app($plack->to_app, path => '/docs')->[0], 200,
        'ui set via the accessor serves');

    $plack->ui(0);
    is(run_app($plack->to_app, path => '/docs')->[0], 404,
        'ui switched back off: the next app has no docs');
}

# ---- a spec that owns the docs path croaks at to_app -------------------------
{
    my $spec = {
        openapi => '3.1.0', info => { title => 'clash', version => '1' },
        paths => { '/docs' => { get => {
            operationId => 'docsOp',
            responses   => { 200 => { description => 'ok' } },
        } } },
    };
    my $plack = Open::API::Plack->new(spec => $spec, ui => 1,
        handlers => { docsOp => sub { [] } });
    my $err = '';
    eval { $plack->to_app } or $err = $@;
    like($err, qr/path '\/docs' is declared by spec operation 'docsOp'/,
        'ui path collision croaks at startup naming the operation');

    $plack->ui({ path => '/documentation' });
    is(run_app($plack->to_app, path => '/documentation')->[0], 200,
        'a non-colliding ui path serves');
}

done_testing();
