use Mojo::Base -strict, -signatures;

use Test::More;
use Test::Mojo;
use FindBin '$Bin';
use File::Temp qw(tempdir);
use File::Spec;
use JSON::PP qw(decode_json);
use Cwd qw(abs_path);
use Mojolicious::Plugin::Fondation::TestHelper qw(create_test_app);

use lib "$Bin/lib";
use lib "$Bin/../lib";

# Temp directory and optional SQLite DB
my $tmpdir = tempdir(CLEANUP => 1);
my $dbfile = File::Spec->catfile($tmpdir, 'test.db');

# Check if DBIx::Async is available
my $has_dbix_async = eval { require Mojolicious::Plugin::Fondation::Model::DBIx::Async; 1 };

# YAML path: absolute so it works regardless of $app->home
my $yaml_template = File::Spec->catfile(
    abs_path("$Bin/.."), 't', 'conf', 'workflows', 'ticket.yaml'
);

my $yaml_path;
my @deps;
my $needs_deploy;

if ($has_dbix_async) {
    # DBI mode: use DBI persister + DBIx::Async for schema deployment
    $yaml_path    = $yaml_template;
    $needs_deploy = 1;
    push @deps,
        {'Fondation::Model::DBIx::Async' => {
            backends => [
                test => {
                    dsn          => "dbi:SQLite:dbname=$dbfile",
                    schema_class => 'TestWorkflowSchema',
                    workers      => 1,
                },
            ],
            models => {
                workflow         => { source => 'Workflow' },
                workflow_history => { source => 'WorkflowHistory' },
            },
        }},
        {'Fondation::Workflow' => {
            persister => {
                dsn      => "dbi:SQLite:dbname=$dbfile",
                user     => '',
                password => '',
            },
            workflows => {
                ticket => $yaml_path,
            },
        }};
} else {
    # File mode: use Workflow::Persister::File, no DB needed
    require YAML;
    my $yaml_data = YAML::LoadFile($yaml_template);
    $yaml_data->{persister} = 'TestFilePersister';
    $yaml_data->{persister_config} = [{
        name  => 'TestFilePersister',
        class => 'Workflow::Persister::File',
        path  => $tmpdir,
    }];
    my $temp_yaml = File::Spec->catfile($tmpdir, 'ticket_file.yaml');
    YAML::DumpFile($temp_yaml, $yaml_data);
    $yaml_path    = $temp_yaml;
    $needs_deploy = 0;
    push @deps,
        {'Fondation::Workflow' => {
            workflows => {
                ticket => $yaml_path,
            },
        }};
}

push @deps, {'Fondation::TestWorkflow' => {}};

# Build Fondation app
my $app = create_test_app($tmpdir);

$app->plugin('Fondation' => {
    dependencies => \@deps,
});

# Deploy the workflow tables only in DBI mode
if ($needs_deploy) {
    my $c     = $app->build_controller;
    my $schema = $c->schema;
    $schema->deploy->get;
}

my $t = Test::Mojo->new($app);

# ── Test 1: Plugin loaded ───────────────────────────────────────────

subtest 'Plugin loaded' => sub {
    ok defined $app->renderer->helpers->{workflow},
        'workflow helper registered';
};

# ── Test 2: Create workflow ─────────────────────────────────────────

subtest 'Create workflow' => sub {
    my $res = $t->post_ok('/test/create', json => { type => 'ticket' })
        ->status_is(200)
        ->tx->res->json;

    ok defined $res->{id}, 'workflow has an id';
    is $res->{state}, 'draft', 'initial state is draft';
};

# ── Test 3: Fetch workflow ──────────────────────────────────────────

subtest 'Fetch workflow' => sub {
    my $create_res = $t->post_ok('/test/create', json => { type => 'ticket' })
        ->tx->res->json;

    my $id = $create_res->{id};

    my $fetch_res = $t->get_ok("/test/fetch/$id?type=ticket")
        ->status_is(200)
        ->tx->res->json;

    is $fetch_res->{id}, $id, 'fetched correct workflow';
    is $fetch_res->{state}, 'draft', 'fetched workflow state is draft';
};

done_testing;
