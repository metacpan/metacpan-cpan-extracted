#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use Test::More;
use Open::API;
use File::Raw::JSON qw(file_json_decode);

# The Open::API::UI object on its own: rendered page, spec JSON, assets,
# headers and the framework routes contract.

plan skip_all => 'Template::Stencil 0.02+ and Markdown::Simple not available'
    unless eval { require Template::Stencil;
                  Template::Stencil->VERSION('0.02');
                  require Markdown::Simple; 1 };

require Open::API::UI;

my $SPEC = "$FindBin::Bin/spec/petstore.json";
my $api  = Open::API->new(spec => $SPEC);

# ---- construction ------------------------------------------------------------
{
    my $err = '';
    eval { Open::API::UI->new } or $err = $@;
    like($err, qr/'api' must be an Open::API/, 'new without api croaks');

    $err = '';
    eval { Open::API::UI->new(api => $api, nope => 1) } or $err = $@;
    like($err, qr/unknown option\(s\) 'nope'/, 'unknown option croaks');

    $err = '';
    eval { Open::API::UI->new(api => $api, path => 'docs') } or $err = $@;
    like($err, qr/'path' must start with '\//, 'relative path croaks');

    $err = '';
    eval { Open::API::UI->new(api => $api, path => '/x', spec_path => '/x') }
        or $err = $@;
    like($err, qr/must differ/, 'path == spec_path croaks');
}

# ---- index_html --------------------------------------------------------------
{
    my $ui = Open::API::UI->new(api => $api);
    my $html = $ui->index_html;
    ok(!utf8::is_utf8($html), 'index_html returns bytes');
    like($html, qr/<title>Petstore<\/title>/, 'title from info.title');
    like($html, qr/id="op-$_"/, "operation anchor op-$_")
        for qw(listPets createPet getPet deletePet);
    like($html, qr/<span class="oa-method">GET<\/span>/, 'method badge');
    like($html, qr{href="/docs/app\.css"}, 'stylesheet under the base path');
    like($html, qr{src="/docs/app\.js"}, 'script under the base path');
    like($html, qr/id="oa-config"/, 'config block present');
    is($ui->index_html, $html, 'second call returns the cached bytes');

    my ($cfg) = $html =~ m{id="oa-config">(.*?)</script>}s;
    my $config = file_json_decode($cfg);
    is($config->{basePath}, '/docs', 'config basePath default');
    is($config->{specPath}, '/openapi.json', 'config specPath default');
    is($config->{tryIt}, 1, 'config tryIt default on');
    is($config->{csrf}{header}, 'X-CSRF-Token', 'config csrf header default');
    is($config->{csrf}{cookie}, 'csrf', 'config csrf cookie default');
}

# ---- options reach the page --------------------------------------------------
{
    my $ui = Open::API::UI->new(api => $api,
        path => '/d/', spec_path => '/s.json', title => 'Mine',
        try_it => 0, csrf => 0);
    my $html = $ui->index_html;
    like($html, qr/<title>Mine<\/title>/, 'title override');
    like($html, qr{src="/d/app\.js"}, 'trailing slash stripped from path');
    my ($cfg) = $html =~ m{id="oa-config">(.*?)</script>}s;
    my $config = file_json_decode($cfg);
    is($config->{specPath}, '/s.json', 'custom spec_path in config');
    ok(!$config->{tryIt}, 'try_it 0 reaches the config');
    ok(!$config->{csrf}, 'csrf 0 reaches the config');

    my $ui2 = Open::API::UI->new(api => $api,
        csrf => { header => 'X-XSRF' });
    ($cfg) = $ui2->index_html =~ m{id="oa-config">(.*?)</script>}s;
    $config = file_json_decode($cfg);
    is($config->{csrf}{header}, 'X-XSRF', 'custom csrf header');
    is($config->{csrf}{cookie}, 'csrf', 'csrf cookie name defaulted');
}

# ---- markdown descriptions ---------------------------------------------------
{
    my $spec = {
        openapi => '3.1.0',
        info    => {
            title => 'md', version => '1',
            description => "**bold** and a [link](https://x.example)\n\n"
                         . "<script>alert(1)</script>",
        },
        tags  => [ { name => 'pets', description => 'about *pets*' } ],
        paths => { '/pets' => { get => {
            operationId => 'listPets',
            tags        => ['pets'],
            description => 'returns `all` pets',
            responses   => { 200 => { description => 'ok' } },
        } } },
    };
    my $ui = Open::API::UI->new(api => Open::API->new(spec => $spec));
    my $html = $ui->index_html;
    like($html, qr/<strong>bold<\/strong>/, 'info description is markdown');
    like($html, qr/<a href="https:\/\/x\.example">link<\/a>/,
        'markdown links render');
    unlike($html, qr/<script>alert/, 'raw HTML in markdown is stripped');
    like($html, qr/<em>pets<\/em>/, 'tag description is markdown');
    like($html, qr/<code>all<\/code>/,
        'operation description is markdown, rendered into the shell');
}

# ---- spec_json ---------------------------------------------------------------
{
    my $ui = Open::API::UI->new(api => $api);
    is_deeply(file_json_decode($ui->spec_json), $api->spec,
        'spec_json round-trips to the compiled document');
}

# ---- asset -------------------------------------------------------------------
{
    my $ui = Open::API::UI->new(api => $api);
    my ($ct, $css) = $ui->asset('app.css');
    is($ct, 'text/css; charset=utf-8', 'css content type');
    ok(length $css, 'css is non-empty');
    ($ct, my $js) = $ui->asset('app.js');
    is($ct, 'application/javascript; charset=utf-8', 'js content type');
    ok(length $js, 'js is non-empty');
    my @none = $ui->asset('evil.txt');
    is(scalar @none, 0, 'unknown asset name returns the empty list');
    @none = $ui->asset('../UI.pm');
    is(scalar @none, 0, 'path traversal name returns the empty list');
}

# ---- headers -----------------------------------------------------------------
{
    my $ui = Open::API::UI->new(api => $api);
    my %h = @{ $ui->headers };
    like($h{'Content-Security-Policy'}, qr/script-src 'self'/,
        'default CSP allows own script');
    is($h{'X-Frame-Options'}, 'DENY', 'default frame options');

    my $ui2 = Open::API::UI->new(api => $api, headers => {
        'x-frame-options' => undef,
        'Cache-Control'   => 'no-store',
        'X-Extra'         => 'yes',
    });
    my %h2 = @{ $ui2->headers };
    ok(!exists $h2{'X-Frame-Options'}, 'undef removes (case-insensitive)');
    is($h2{'Cache-Control'}, 'no-store', 'override replaces');
    is($h2{'X-Extra'}, 'yes', 'unknown name is added');
}

# ---- routes ------------------------------------------------------------------
{
    my $ui = Open::API::UI->new(api => $api);
    my $routes = $ui->routes;
    is_deeply([ map "$_->{method} $_->{path}", @$routes ],
        [ 'GET /docs', 'GET /docs/', 'GET /docs/app.js',
          'GET /docs/app.css', 'GET /openapi.json' ],
        'the route set');
    for my $r (@$routes) {
        my $resp = $r->{response}->();
        is(ref $resp, 'ARRAY', "$r->{path} response is a triplet");
        is($resp->[0], 200, "$r->{path} status 200");
        my %h = @{ $resp->[1] };
        ok($h{'Content-Type'}, "$r->{path} has a content type");
        is($h{'Content-Length'}, length $resp->[2][0],
            "$r->{path} content length matches the body");
        ok($h{'Content-Security-Policy'}, "$r->{path} carries the CSP");
    }
    my $one = $routes->[0]{response}->();
    my $two = $routes->[0]{response}->();
    isnt($one->[1], $two->[1], 'each call returns a fresh header arrayref');
    is($one->[2][0], $two->[2][0], 'the body bytes are the shared cache');
}

# ---- to_app ------------------------------------------------------------------
{
    my $app = Open::API::UI->new(api => $api)->to_app;
    is($app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/docs' })->[0], 200,
        'to_app serves the page');
    my $head = $app->({ REQUEST_METHOD => 'HEAD', PATH_INFO => '/docs' });
    is($head->[0], 200, 'HEAD is 200');
    is($head->[2][0], '', 'HEAD body is empty');
    is($app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/nope' })->[0], 404,
        'unknown path 404s');
    is($app->({ REQUEST_METHOD => 'POST', PATH_INFO => '/docs' })->[0], 404,
        'non-GET 404s');
}

done_testing();
