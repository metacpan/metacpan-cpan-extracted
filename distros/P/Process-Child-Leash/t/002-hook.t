use strict;
use warnings;
use Test::More;
use Sub::Override;
use Time::Out qw( timeout );
use Process::Child::Leash test => 1;

my @cases = (
    {
        subject    => "test timeout and kill",
        start_time => time - 6,
        timeout    => 5,
        expected   => { hook_return => "timeout. killed child process", }
    },
    {
        subject    => "test what happen if parent process is running then gone",
        parent_pid => 123,
        child_pid  => 456,
        kill_process_options => {
            123 => {
                after => time + 3,    ## after 3 seconds
            }
        },
        expected => {
            hook_return => "parent is gone. killed child process",
            killed_pid  => { 456 => 1 },
        },
    },
    {
        subject        => "test what happen if parent process is gone",
        parent_pid     => 123,
        child_pid      => 456,
        killed_process => { 123 => 1 },
        expected       => {
            hook_return => "parent is gone. killed child process",
            killed_pid  => { 456 => 1 },
        },
    },
    {
        subject        => "test what happen if child process is gone",
        parent_pid     => 789,
        child_pid      => 101,
        killed_process => { 101 => 1 },
        expected       => {
            hook_return => "child is gone. finish checking",
            killed_pid  => {},
        },
    },
);

my $_30_seconds = 30;

timeout $_30_seconds => sub {
    foreach my $case (@cases) {
        my $overrider = Sub::Override->new;

        my %killed_pid = ( %{ $case->{killed_process} || {} } );

        my $last_killed_pid = -1;
        $overrider->replace(
            "Process::Child::Leash::_kill_process" => sub {
                my $self = shift;
                $last_killed_pid = shift;
                $killed_pid{$last_killed_pid} = 1;
            }
        );

        if ( $case->{keep_pid_alive} ) {
            delete $killed_pid{$last_killed_pid};
        }

        $overrider->replace(
            "Process::Child::Leash::_is_process_still_running" => sub {
                my $self = shift;
                my $pid  = shift;

                if ( my $options = $case->{kill_process_options}{$pid} ) {
                    if ( time > $options->{after} ) {
                        $self->_kill_process($pid);
                        $case->{killed_process}{$pid} = 1;
                    }
                }

                return $killed_pid{$pid} ? 0 : 1;
            }
        );

        my $leash = Process::Child::Leash->new(
            ( $case->{timeout} ? ( timeout => $case->{timeout} ) : () ),
            (
                $case->{start_time} ? ( _started_time => $case->{start_time} )
                : ()
            ),
            (
                $case->{parent_pid} ? ( _parent_pid => $case->{parent_pid} )
                : ()
            ),
            ( $case->{child_pid} ? ( _child_pid => $case->{child_pid} ) : () ),
        );
        my $result = $leash->_baby_sit;

        my %expected = %{ $case->{expected} };

        map { delete $killed_pid{$_} } keys %{ $case->{killed_process} };

        subtest $case->{subject} => sub {
            is $result, $expected{hook_return}, "hook return";
            if ( $expected{killed_pid} ) {
                is_deeply \%killed_pid, $expected{killed_pid}, "killed pid";
            }
        };

    }

    done_testing;
};
