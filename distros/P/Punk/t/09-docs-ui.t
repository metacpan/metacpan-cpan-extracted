#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;
use File::Raw::JSON qw(file_json_decode);

# The docs keyword: Open::API::UI routes folded into the static table.

plan skip_all => 'Open::API::UI (Template::Stencil + Markdown::Simple) '
    . 'required for these tests'
    unless eval { require Open::API::UI; 1 };

sub spec {
    return {
        openapi => '3.1.0',
        info    => { title => 'DocsTest', version => '1' },
        paths   => { '/pets' => { get => {
            operationId => 'listPets',
            responses   => { 200 => { description => 'ok' } },
        } } },
    };
}

{
    package DocsApp;
    use Punk;
    api main::spec() => { handlers => { listPets => sub { [] } } };
    docs '/docs';
    package main;

    my $app = DocsApp->to_app;
    my $r = hit($app, path => '/docs');
    is($r->[0], 200, 'GET /docs serves');
    my %h = @{ $r->[1] };
    is($h{'Content-Type'}, 'text/html; charset=utf-8', 'docs are html');
    like($r->[2][0], qr/id="op-listPets"/, 'the page lists the operations');
    like($h{'Content-Security-Policy'} // '', qr/script-src 'self'/,
        'UI responses carry the docs CSP');

    is(hit($app, path => '/docs/app.js')->[0], 200, 'app.js serves');
    is(hit($app, path => '/docs/app.css')->[0], 200, 'app.css serves');

    $r = hit($app, path => '/openapi.json');
    is($r->[0], 200, 'the spec JSON serves');
    is(file_json_decode($r->[2][0])->{info}{title}, 'DocsTest',
        'and matches the mounted document');

    my $head = hit($app, method => 'HEAD', path => '/docs');
    is($head->[0], 200, 'HEAD /docs is 200');
    is($head->[2][0], '', 'HEAD body empty');

    {
        my $post = hit($app, method => 'POST', path => '/docs');
        is($post->[0], 405, 'POST /docs answers 405 (docs routes are GET)');
        my %ph = @{ $post->[1] };
        is($ph{Allow}, 'GET', 'with Allow: GET');
    }
    is(hit($app, path => '/pets')->[0], 200,
        'spec operations still serve next to the docs');
}

# ---- docs against a prefixed mount + custom ui options -----------------------
{
    package PrefixedDocs;
    use Punk;
    my $v1 = under '/v1';
    my $m = $v1->api(main::spec() => {
        handlers => { listPets => sub { [] } } });
    docs '/documentation' => $m, { spec_path => '/spec.json' };
    package main;

    my $app = PrefixedDocs->to_app;
    is(hit($app, path => '/documentation')->[0], 200,
        'custom docs path serves');
    is(hit($app, path => '/spec.json')->[0], 200, 'custom spec_path serves');
    is(hit($app, path => '/docs')->[0], 404, 'default path not taken');
}

# ---- boot croaks -------------------------------------------------------------
{
    package NoApiDocs;
    use Punk;
    docs '/docs';
    package main;
    my $err = '';
    eval { NoApiDocs->to_app } or $err = $@;
    like($err, qr/docs needs an api mount/, 'docs without an api croaks');
}
{
    package CollideDocs;
    use Punk;
    api {
        openapi => '3.1.0', info => { title => 'x', version => '1' },
        paths => { '/docs' => { get => {
            operationId => 'docsOp',
            responses   => { 200 => { description => 'ok' } } } } },
    } => { handlers => { docsOp => sub { [] } } };
    docs '/docs';
    package main;
    my $err = '';
    eval { CollideDocs->to_app } or $err = $@;
    like($err, qr/docs path '\/docs' is declared by the mounted spec/,
        'a docs path the spec declares croaks at to_app');
}

done_testing();
