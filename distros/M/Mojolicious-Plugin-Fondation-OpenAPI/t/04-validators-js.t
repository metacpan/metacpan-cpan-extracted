#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Mojo::File 'path';
use Mojo::JSON qw(decode_json false true);
use File::Temp 'tempdir';
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../../Mojolicious-Plugin-Fondation/lib";

use Mojolicious::Plugin::Fondation::TestHelper qw(create_test_app);

sub build_app {
    my $tmpdir = tempdir(CLEANUP => 1);
    my $dbfile = "$tmpdir/test.db";
    my $app    = create_test_app($tmpdir);

    $app->plugin('Fondation' => {
        dependencies => [
            {'Fondation::Model::DBIx::Async' => {
                backends => [
                    test => {
                        dsn          => "dbi:SQLite:dbname=$dbfile",
                        schema_class => 'TestSchema',
                        workers      => 1,
                    },
                ],
                models => {
                    foo => {source => 'Foo'},
                    bar => {source => 'Bar'},
                },
            }},
            {'Fondation::TestOpenAPI' => {}},
            {'Fondation::OpenAPI' => {}},
        ],
    });

    return $app;
}

sub generate_validators {
    my ($app) = @_;
    my $config = $app->defaults->{'openapi.config'};
    require Mojolicious::Plugin::Fondation::OpenAPI::Command::openapi;
    my $cmd = Mojolicious::Plugin::Fondation::OpenAPI::Command::openapi->new(app => $app);
    my $schema_class = $cmd->_get_schema_class($app, $config);
    my $spec = $cmd->_build_spec($schema_class, $app, $config);
    return $cmd->_build_validators_js($spec);
}

# ==========================================================================
# 1. validators.js structure
# ==========================================================================

{
    my $app = build_app;
    my $js  = generate_validators($app);

    like($js, qr/var FondationSchemas = \{\};/, 'FondationSchemas declaration');
    like($js, qr/window\.FondationValidators/,   'FondationValidators global');
    like($js, qr/validate: function/,            'validate function exists');
}

# ==========================================================================
# 2. Only 3 schemas in validators (Bar, Foo, FooCreate)
# ==========================================================================

{
    my $app = build_app;
    my $js  = generate_validators($app);

    my @schemas = $js =~ /FondationSchemas\['([^']+)'\]/g;
    is(scalar @schemas, 6, '6 schemas in validators.js');

    my %seen = map { $_ => 1 } @schemas;
    ok($seen{Bar},       'Bar in validators');
    ok($seen{Foo},       'Foo in validators');
    ok($seen{FooCreate}, 'FooCreate in validators');
    ok($seen{FooUpdate}, 'FooUpdate in validators');
    ok($seen{FooPatch},  'FooPatch in validators');
    ok($seen{BarPatch},  'BarPatch in validators');
    ok(!$seen{BarCreate}, 'no BarCreate in validators');
}

# ==========================================================================
# 3. FooCreate validators -- password required
# ==========================================================================

{
    my $app = build_app;
    my $js  = generate_validators($app);

    # Extract FooCreate section
    my ($foocreate) = $js =~ /FondationSchemas\['FooCreate'\] = \{(.*?)\};/s;
    ok(defined $foocreate, 'FooCreate section exists');

    # password should have required: true
    like($foocreate, qr/'password':\s*\{[^}]*required:\s*true/, 'password required in FooCreate');
}

# ==========================================================================
# 4. Bar validators -- no password, no writeOnly handling needed
# ==========================================================================

{
    my $app = build_app;
    my $js  = generate_validators($app);

    my ($bar) = $js =~ /FondationSchemas\['Bar'\] = \{(.*?)\};/s;
    ok(defined $bar, 'Bar section exists');

    # title should have required: true
    like($bar, qr/'title':\s*\{[^}]*required:\s*true/, 'title required in Bar');
    # body should have maxLength: 10000
    like($bar, qr/'body':\s*\{[^}]*maxLength:\s*10000/, 'body maxLength in Bar');
}

done_testing;
