#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Test::Exception::LessClever;

my $CLASS = 'Parallel::Runner';
use_ok($CLASS);

can_ok( $CLASS, qw/new exit_callback iteration_callback children _children pid max/ );

ok( my $one = $CLASS->new, "Created one" );
$one->reap_callback(
    sub {
        my ( $status, $pid, $pid_again, $proc ) = @_;
        ok( !$status, "Child exited cleanly" );
    }
);

isa_ok( $one, $CLASS );
is( $one->max, 1,  "got max" );
is( $one->pid, $$, "Stored pid" );
is_deeply(
    $one,
    {
        iteration_delay => 0.1,
        max             => 1,
        pid             => $$,
        _children       => [],
        reap_callback   => $one->reap_callback,
    },
    "Built properly"
);
my $parent_pid = $$;

$one->run(
    sub {
        if ( $$ == $parent_pid ) {
            warn "Did not fork!";
            exit(1);
        }
        else {
            diag "Forked as expected";
        }
    },
    'force_fork',
);

$one->finish;

throws_ok {
    my $one = $CLASS->new(2);
    $one->pid(0.5);
    $one->run( sub { 1 } );
}
qr/Called run\(\) in child process/, "Do not run in fork";

my $ran           = 0;
my $iter_callback = sub { $ran++ };
my $reap_callback = sub {
    my ( $exit, $pid, $ret ) = @_;
    ok( !$exit, "Exited 0" );
    is( $pid, $ret, "Return pid, not -1 or 0" );
};
$one = $CLASS->new(
    2,
    iteration_callback => $iter_callback,
    reap_callback      => $reap_callback,
    pipe               => 1,
);
is( $one->iteration_callback, $iter_callback, "Stored iter callback" );
is( $one->reap_callback,      $reap_callback, "Stored reap callback" );
is( $one->pipe,               1,              "Spawn with pipes" );

$one->run( sub { sleep 5 } );
$one->run( sub { sleep 5 } );
ok( !$ran, "No waiting yet" );
$one->run( sub { 1 } );
ok( $ran > 20, "Iterated while waiting" );
$one->finish;

$ran = 0;
$one->max(1);
ok( !$ran, "No waiting yet" );
$one->run( sub { sleep 5 }, 1 );
ok( $ran > 20, "Iterated while waiting" );
$one->finish;

my ( $read, $write );
unless ( pipe( $read, $write ) ) {
    skip "Pipe not available: $!", 1;
    done_testing;
    exit;
}

my $ecallback = sub { print $write "ran\n" };

$one = $CLASS->new(
    2,
    exit_callback => $ecallback,
    reap_callback => $reap_callback,
);
$one->run( sub { 1 } );
$one->finish;

my $data;
lives_ok {
    local $SIG{ALRM} = sub { die('alarm') };
    alarm 5;
    $data = <$read>;
    alarm 0;
}
"read from pipe";
is( $data, "ran\n", "exit callback ran" );

my @accum_data;
$one = $CLASS->new(
    2,
    data_callback => sub {
        my ($data) = @_;
        push @accum_data => $data;
    },
);
$one->run( sub { return "foo" } );
$one->run( sub { return "bar" } );
$one->run( sub { return "baz" } );
$one->run( sub { return "bat" } );
$one->finish;

is_deeply(
    [sort @accum_data],
    [sort qw/foo bar baz bat/],
    "Got all data returned by subprocesses"
);

@accum_data = ();
$one        = $CLASS->new(
    0,
    data_callback => sub {
        my ($data) = @_;
        push @accum_data => $data;
    },
);
$one->run( sub { return "foo" } );
$one->run( sub { return "bar" } );
$one->run( sub { return "baz" } );
$one->run( sub { return "bat" } );
$one->finish;

is_deeply(
    [sort @accum_data],
    [sort qw/foo bar baz bat/],
    "Got all data returned when not forking"
);

done_testing;
