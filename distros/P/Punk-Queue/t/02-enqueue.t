#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PQTest;

plan skip_all => 'DBI and DBD::SQLite required' unless has_dbd();

my ($q) = make_queue();

# Defaults.
{
    my $id = $q->enqueue('add');
    ok($id > 0, "enqueue returns an id ($id)");

    my $j = $q->job_info($id);
    ok($j, 'job_info finds it');
    is($j->{task},         'add',       'task');
    is($j->{queue},        'default',   'default queue');
    is($j->{state},        'inactive',  'starts inactive');
    is($j->{priority},     0,           'default priority');
    is($j->{attempts},     1,           'default attempts');
    is($j->{retries},      0,           'no retries yet');
    is($j->{parents_left}, 0,           'no parents');
    is_deeply($j->{args},  [],          'no args is an empty list');
    is_deeply($j->{notes}, {},          'no notes is an empty hash');
    ok(!defined $j->{result},           'no result yet');
    ok(!defined $j->{started},          'not started');
    ok(!defined $j->{expires},          'no expiry by default');
    ok($j->{created} > 0,               'created is set');
    ok(abs($j->{delayed} - $j->{created}) < 0.01,
       'delayed defaults to created');
}

# Every option.
{
    my $id = $q->enqueue('mail.send' => ['a@b.c', 'hi'],
        queue    => 'mail',
        priority => 7,
        attempts => 5,
        delay    => 60,
        expire   => 3600,
        notes    => { source => 'test', n => 1 },
    );
    my $j = $q->job_info($id);

    is($j->{queue},    'mail',      'queue option');
    is($j->{priority}, 7,           'priority option');
    is($j->{attempts}, 5,           'attempts option');
    is_deeply($j->{args}, ['a@b.c', 'hi'], 'args round-trip');
    is_deeply($j->{notes}, { source => 'test', n => 1 }, 'notes round-trip');

    ok($j->{delayed} - $j->{created} >= 59, 'delay pushed delayed forward');
    ok($j->{expires} - $j->{created} >= 3599, 'expire set expires');
}

# Args are JSON, so they carry structure and unicode intact.
{
    my $payload = {
        nested => [ 1, 2, { deep => 'yes' } ],
        uni    => "caf\x{e9} \x{263a}",
        empty  => [],
        zero   => 0,
    };
    my $id = $q->enqueue('shape' => [$payload]);
    my $j  = $q->job_info($id);
    is_deeply($j->{args}[0], $payload, 'a nested structure round-trips');
    is($j->{args}[0]{uni}, "caf\x{e9} \x{263a}", 'unicode survives');
}

# Name validation. The rule is narrow on purpose: it is what makes the
# phase-5 LISTEN identifier assembly safe by construction.
{
    for my $bad ('has space', 'quote"s', "new\nline", 'semi;colon',
                 'back\\slash', '', 'x' x 65) {
        my $shown = length($bad) > 20 ? substr($bad, 0, 20) . '...' : $bad;
        eval { $q->enqueue($bad) };
        like($@, qr/invalid task name/, "rejects task name '$shown'");
    }

    for my $good ('a', 'mail.send', 'ns:task-1', 'A_b.C-d:9', 'x' x 64) {
        my $id = eval { $q->enqueue($good) };
        ok($id, "accepts task name '" . substr($good, 0, 20) . "'")
            or diag $@;
    }

    eval { $q->enqueue('ok.task', [], queue => 'bad queue') };
    like($@, qr/invalid queue name/, 'queue names get the same rule');
}

# The once-deferred options are live from phase 4 and covered by the
# conformance battery; what stays here is only their input validation.
{
    eval { $q->enqueue('t', [], parents => 'not an array') };
    like($@, qr/parents must be an array reference/,
         'parents wants an arrayref');

    eval { $q->enqueue('t', [], unique => 'bad key!') };
    like($@, qr/invalid unique name/, 'unique keys follow the name rule');
}

# Bad shapes.
{
    eval { $q->enqueue('t', { not => 'an array' }) };
    like($@, qr/args must be an array reference/, 'args must be an arrayref');

    eval { $q->enqueue('t', [], 'odd') };
    like($@, qr/odd number of options/, 'odd option list is caught');

    eval { $q->enqueue('t', [], attempts => 0) };
    like($@, qr/attempts must be at least 1/, 'attempts must be positive');
}

done_testing();
