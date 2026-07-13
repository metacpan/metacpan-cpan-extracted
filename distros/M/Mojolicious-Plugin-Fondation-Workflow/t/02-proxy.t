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

my $tmpdir = tempdir(CLEANUP => 1);
my $dbfile = File::Spec->catfile($tmpdir, 'test.db');

# Check if DBIx::Async is available
my $has_dbix_async = eval { require Mojolicious::Plugin::Fondation::Model::DBIx::Async; 1 };

my $yaml_template = File::Spec->catfile(
    abs_path("$Bin/.."), 't', 'conf', 'workflows', 'ticket.yaml'
);

my $yaml_path;
my @deps;
my $needs_deploy;

if ($has_dbix_async) {
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

my $app = create_test_app($tmpdir);

$app->plugin('Fondation' => {
    dependencies => \@deps,
});

if ($needs_deploy) {
    my $c     = $app->build_controller;
    my $schema = $c->schema;
    $schema->deploy->get;
}

my $t = Test::Mojo->new($app);

# ── Test: Proxy actions ─────────────────────────────────────────────

subtest 'actions in draft state' => sub {
    my $res = $t->post_ok('/test/actions', json => { type => 'ticket' })
        ->status_is(200)
        ->tx->res->json;

    is ref $res, 'ARRAY', 'actions returns array';
    is scalar @$res, 2, 'draft has 2 actions (submit, cancel)';

    my %by_name = map { $_->{name} => $_ } @$res;
    ok exists $by_name{submit}, 'submit action exists';
    ok exists $by_name{cancel}, 'cancel action exists';

    is $by_name{submit}{label}, 'Submit', 'action label';
    is $by_name{submit}{color}, 'primary', 'action color';
    is $by_name{submit}{permission}, 'ticket.submit', 'action permission';
    is $by_name{cancel}{group}, 'danger', 'cancel in danger group';
};

# ── Test: Execute action ────────────────────────────────────────────

subtest 'execute submit' => sub {
    my $res = $t->post_ok('/test/execute', json => {
        type   => 'ticket',
        action => 'submit',
        params => { comment => 'looks good' },
    })->status_is(200)->tx->res->json;

    is $res->{state}, 'submitted', 'transitioned to submitted';
};

# ── Test: can ───────────────────────────────────────────────────────

subtest 'can method' => sub {
    my $res = $t->post_ok('/test/can', json => {
        type   => 'ticket',
        action => 'submit',
    })->status_is(200)->tx->res->json;

    ok $res->{can}, 'can submit in draft';
};

# ── Test: History ──────────────────────────────────────────────────

subtest 'history' => sub {
    my $res = $t->post_ok('/test/history', json => {
        type   => 'ticket',
        action => 'submit',
        params => { comment => 'testing' },
    })->status_is(200)->tx->res->json;

    is ref $res, 'ARRAY', 'history returns array';
    ok scalar @$res >= 1, 'history has entries after execute';
};

done_testing;
