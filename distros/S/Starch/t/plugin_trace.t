#!/usr/bin/env perl
use strictures 2;

# If this test fails it may not be due to obvious breakage, but instead
# due to a change in how the various starch objects are created which
# could be a breakage or cause for fixing this test.

use Test::More;
use Log::Any::Test;
use Log::Any qw($log);

use Test::Starch;
use Starch;

Test::Starch->new(
    plugins => ['::Trace'],
)->test();
$log->clear();

my $starch = Starch->new(
    plugins => ['::Trace'],
    store => { class => '::Memory' },
);

my $manager_class = 'Starch::Manager';
my $state_class = 'Starch::State';
my $store_class   = 'Starch::Store::Memory';

subtest 'manager created with store' => sub{
    $log->category_contains_ok(
        $manager_class,
        qr{^starch\.manager\.new$},
        'starch.manager.new',
    );
    $log->category_contains_ok(
        $store_class,
        qr{^starch\.store\.Memory\.new$},
        'starch.store.Memory.new',
    );
    log_empty_ok();
};

subtest 'create state' => sub{
    my $state = $starch->state();
    my $state_id = $state->id();

    $log->category_contains_ok(
        $state_class,
        qr{^starch\.state\.new\.$state_id$},
        'starch.state.new.$state_id',
    );
    $log->category_contains_ok(
        $manager_class,
        qr{^starch\.manager\.generate_state_id\.$state_id$},
        'starch.manager.generate_state_id.$state_id',
    );
    $log->category_contains_ok(
        $manager_class,
        qr{^starch\.manager.state\.created\.$state_id$},
        'starch.manager.state.created.$state_id',
    );
    log_empty_ok();
};

subtest 'retrieve state' => sub{
    my $state = $starch->state('1234');
    my $state_id = $state->id();

    $log->category_contains_ok(
        $state_class,
        qr{^starch\.state\.new\.$state_id$},
        'starch.state.new.$state_id',
    );
    $log->category_contains_ok(
        $manager_class,
        qr{^starch\.manager.state\.retrieved\.$state_id$},
        'starch.manager.state.retrieved.$state_id',
    );
    log_empty_ok();
};

subtest 'state methods' => sub{
    my $state = $starch->state();
    my $state_id = $state->id();
    $log->clear();

    $state->save();
    $log->category_contains_ok(
        $state_class,
        qr{^starch\.state\.save\.$state_id$},
        'starch.state.save.$state_id',
    );
    log_empty_ok('log is empty after non-dirty save');

    $state->data->{foo} = 34;
    $state->save();
    $log->category_contains_ok(
        $state_class,
        qr{^starch\.state\.save\.$state_id$},
        'starch.state.save.$state_id',
    );
    $log->category_contains_ok(
        $store_class,
        qr{^starch\.store\.Memory\.set\.starch-state:$state_id$},
        'starch.store.Memory.set.starch-state:$state_id',
    );
    $log->category_contains_ok(
        $state_class,
        qr{^starch\.state\.mark_clean\.$state_id$},
        'starch.state.mark_clean.$state_id',
    );
    log_empty_ok();

    $state->reload();
    $state->mark_clean();
    $state->rollback();
    $state->delete();

    $log->category_contains_ok(
        $state_class,
        qr{^starch\.state\.reload\.$state_id$},
        'starch.state.reload.$state_id',
    );
    $log->category_contains_ok(
        $state_class,
        qr{^starch\.state\.mark_clean\.$state_id$},
        'starch.state.mark_clean.$state_id',
    );
    $log->category_contains_ok(
        $state_class,
        qr{^starch\.state\.rollback\.$state_id$},
        'starch.state.rollback.$state_id',
    );
    $log->category_contains_ok(
        $store_class,
        qr{^starch\.store\.Memory\.get\.starch-state:$state_id$},
        'starch.store.Memory.get.starch-state:$state_id',
    );
    $log->category_contains_ok(
        $state_class,
        qr{^starch\.state\.delete\.$state_id$},
        'starch.state.delete.$state_id',
    );
    $log->category_contains_ok(
        $store_class,
        qr{^starch\.store\.Memory\.remove\.starch-state:$state_id$},
        'starch.store.Memory.remove.starch-state:$state_id',
    );
    log_empty_ok();
};

done_testing;

# Workaround: https://github.com/dagolden/Log-Any/issues/30
sub log_empty_ok {
    my ($test_msg) = @_;
    $test_msg = 'log is empty' if !defined $test_msg;
    my $msgs = $log->msgs();
    ok( (@$msgs == 0), $test_msg );
    use Data::Dumper;
    diag( Dumper($msgs) ) if @$msgs;
    $log->clear();
}
