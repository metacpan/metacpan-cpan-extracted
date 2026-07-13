#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Temp 'tempdir';
use FindBin;
use Mojo::File 'path';

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

use Mojolicious::Plugin::Fondation::TestHelper qw(create_test_app create_fondation_app);

# Load the command module
use_ok 'Mojolicious::Plugin::Fondation::Command::fondation';

# ═══════════════════════════════════════════════════════════════════════════
# Helper: create a Fondation app with test plugins that declare fondation steps
# ═══════════════════════════════════════════════════════════════════════════

sub build_app {
    my $tmpdir = tempdir(CLEANUP => 1);
    my $app    = create_fondation_app($tmpdir, {
        dependencies => [
            {'Fondation::TestInit'    => { share_dir => "$FindBin::Bin/share/fondation/test_init" }},
            {'Fondation::TestUpgrade' => { share_dir => "$FindBin::Bin/share/fondation/test_upgrade" }},
            {'Fondation::TestClean'   => { share_dir => "$FindBin::Bin/share/fondation/test_clean" }},
        ],
    });
    return $app;
}

# ═══════════════════════════════════════════════════════════════════════════
# 1. Command can be instantiated
# ═══════════════════════════════════════════════════════════════════════════

subtest 'Command instantiation' => sub {
    my $app = build_app;
    my $cmd = Mojolicious::Plugin::Fondation::Command::fondation->new(app => $app);
    isa_ok($cmd, 'Mojolicious::Plugin::Fondation::Command::fondation');
    like($cmd->description, qr/init|upgrade|refresh/i, 'description mentions commands');
};

# ═══════════════════════════════════════════════════════════════════════════
# 2. _collect_steps gathers fondation_init from plugins
# ═══════════════════════════════════════════════════════════════════════════

subtest '_collect_steps -- fondation_init' => sub {
    my $app   = build_app;
    my $cmd   = Mojolicious::Plugin::Fondation::Command::fondation->new(app => $app);
    my @steps = $cmd->_collect_steps($app, 'fondation_init');

    ok(@steps > 0, 'found plugins with fondation_init');

    # Find TestInit plugin steps
    my ($ti) = grep { $_->{long_name} eq 'Mojolicious::Plugin::Fondation::TestInit' } @steps;
    ok($ti, 'TestInit found');
    is_deeply($ti->{steps}, [ ['test_init', 'setup'], ['test_init', 'seed'] ],
        'TestInit fondation_init steps correct');
};

# ═══════════════════════════════════════════════════════════════════════════
# 3. _collect_steps gathers fondation_upgrade from plugins
# ═══════════════════════════════════════════════════════════════════════════

subtest '_collect_steps -- fondation_upgrade' => sub {
    my $app   = build_app;
    my $cmd   = Mojolicious::Plugin::Fondation::Command::fondation->new(app => $app);
    my @steps = $cmd->_collect_steps($app, 'fondation_upgrade');

    my ($tu) = grep { $_->{long_name} eq 'Mojolicious::Plugin::Fondation::TestUpgrade' } @steps;
    ok($tu, 'TestUpgrade found');
    is_deeply($tu->{steps}, [ ['test_upgrade', 'migrate'] ],
        'TestUpgrade fondation_upgrade steps correct');
};

# ═══════════════════════════════════════════════════════════════════════════
# 4. _collect_clean gathers fondation_clean from plugins
# ═══════════════════════════════════════════════════════════════════════════

subtest '_collect_clean' => sub {
    my $app = build_app;
    my $cmd = Mojolicious::Plugin::Fondation::Command::fondation->new(app => $app);
    my @clean = $cmd->_collect_clean($app);

    my ($tc) = grep { $_->{long_name} eq 'Mojolicious::Plugin::Fondation::TestClean' } @clean;
    ok($tc, 'TestClean found');
    is_deeply($tc->{targets}, ['test_clean_dir/', 'test_clean_file.txt'],
        'TestClean fondation_clean targets correct');
};

# ═══════════════════════════════════════════════════════════════════════════
# 5. Plugin with no steps is skipped
# ═══════════════════════════════════════════════════════════════════════════

subtest 'Plugin without fondation_init is not collected' => sub {
    my $app   = build_app;
    my $cmd   = Mojolicious::Plugin::Fondation::Command::fondation->new(app => $app);
    my @steps = $cmd->_collect_steps($app, 'fondation_init');

    # TestUpgrade should NOT appear in fondation_init collection
    ok(!(grep { $_->{long_name} eq 'Mojolicious::Plugin::Fondation::TestUpgrade' } @steps),
        'TestUpgrade not in fondation_init (has only upgrade)');
};

# ═══════════════════════════════════════════════════════════════════════════
# 6. _run_init calls steps in load order
# ═══════════════════════════════════════════════════════════════════════════

subtest '_run_init invokes steps through commands->run' => sub {
    my $app  = build_app;
    my $cmd  = Mojolicious::Plugin::Fondation::Command::fondation->new(app => $app);

    # Mock commands->run to record calls instead of executing
    my @calls;
    {
        no warnings 'redefine';
        local *Mojolicious::Commands::run = sub {
            my ($self, @args) = @_;
            push @calls, \@args;
        };
        $cmd->_run_init($app);
    }

    ok(@calls >= 2, 'at least 2 command calls made (from TestInit)');

    # First two calls should be from TestInit
    is_deeply($calls[0], ['test_init', 'setup'], 'first call: test_init setup');
    is_deeply($calls[1], ['test_init', 'seed'],  'second call: test_init seed');
};

# ═══════════════════════════════════════════════════════════════════════════
# 7. _run_refresh cleans and then inits
# ═══════════════════════════════════════════════════════════════════════════

subtest '_run_refresh cleans then inits' => sub {
    my $tmpdir = tempdir(CLEANUP => 1);
    my $app    = create_fondation_app($tmpdir, {
        dependencies => [
            {'Fondation::TestClean' => { share_dir => "$FindBin::Bin/share/fondation/test_clean" }},
            {'Fondation::TestInit'  => { share_dir => "$FindBin::Bin/share/fondation/test_init" }},
        ],
    });

    # Create files/dirs that fondation_clean should remove
    my $home = $app->home;
    path($home->child('test_clean_dir'))->make_path;
    path($home->child('test_clean_dir', 'subfile.txt'))->spurt('data');
    path($home->child('test_clean_file.txt'))->spurt('data');

    ok(-d $home->child('test_clean_dir'), 'test_clean_dir exists before refresh');
    ok(-f $home->child('test_clean_file.txt'), 'test_clean_file.txt exists before refresh');

    my $cmd = Mojolicious::Plugin::Fondation::Command::fondation->new(app => $app);

    # Mock commands->run for the init phase
    my @calls;
    {
        no warnings 'redefine';
        local *Mojolicious::Commands::run = sub {
            my ($self, @args) = @_;
            push @calls, \@args;
        };
        $cmd->_run_refresh($app);
    }

    ok(!-d $home->child('test_clean_dir'), 'test_clean_dir removed by refresh');
    ok(!-f $home->child('test_clean_file.txt'), 'test_clean_file.txt removed by refresh');
    ok(@calls >= 2, 'init steps also ran after clean');
};

done_testing;
