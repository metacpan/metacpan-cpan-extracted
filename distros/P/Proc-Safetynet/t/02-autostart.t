use strict;
use warnings;
use Test::More qw/no_plan/;
use Data::Dumper;

BEGIN {
    use_ok 'Proc::Safetynet';
    use_ok 'Proc::Safetynet::Program::Storage::TextFile';
    use_ok 'POE::Kernel';
    use_ok 'POE::Session';
}


my $programs = Proc::Safetynet::Program::Storage::TextFile->new(
    file => '/tmp/test.programs',
);

$programs->add( Proc::Safetynet::Program->new( 'name' => 'a', command => $^X, autostart => 1 ) );
$programs->add( Proc::Safetynet::Program->new( 'name' => 'b', command => $^X, autostart => 1, autorestart => 1, autorestart_wait => 2 ) );


my $SUPERVISOR = q{SUPERVISOR};
my $SHELL   = q{SHELL};

my $supervisor = Proc::Safetynet::Supervisor->spawn(
    alias       => $SUPERVISOR,
    programs    => $programs,
    binpath     => '/bin:/usr/bin',
);

# shell
POE::Session->create(
    inline_states => {
        _start => sub {
            $_[KERNEL]->alias_set( $SHELL );
            $supervisor->yield( 'start_work' );
            $_[KERNEL]->delay( 'c1' => 2 );
            $_[KERNEL]->delay( 'timeout' => 15 );
        },
        c1 => sub {
            $supervisor->yield( 'info_status', [ $SHELL, 'c2' ], [ ], 'a' );
            $_[KERNEL]->delay( 'timeout' => 15 );
        },
        c2 => sub {
            my $r = $_[ARG1];
            my $ps = $r->{result};
            ok $ps->is_running, 'running "a"';
            kill 'TERM', $ps->pid(); # force kill
            $supervisor->yield( 'info_status', [ $SHELL, 'c3' ], [ ], 'b' );
            $_[KERNEL]->delay( 'timeout' => 15 );
        },
        c3 => sub {
            my $r = $_[ARG1];
            my $ps = $r->{result};
            ok $ps->is_running, 'running "b"';
            kill 'TERM', $ps->pid(); # force kill
            $_[KERNEL]->delay( 'c4' => 6 );
            $_[KERNEL]->delay( 'timeout' => 15 );
        },
        c4 => sub {
            $supervisor->yield( 'info_status', [ $SHELL, 'c5' ], [ ], 'b' );
            $_[KERNEL]->delay( 'timeout' => 15 );
        },
        c5 => sub {
            my $r = $_[ARG1];
            my $ps = $r->{result};
            ok $ps->is_running, 'running "b" after restart';
            my $p = $programs->retrieve( 'b' );
            $p->autorestart(0);
            $supervisor->yield( 'stop_program', [ $SHELL, 'c6' ], [ ], 'b' );
            $_[KERNEL]->delay( 'timeout' => 15 );
        },
        c6 => sub {
            my $r = $_[ARG1];
            my $result = $r->{result};
            ok $result, 'b stopped';
            $_[KERNEL]->delay( 'c7' => 6 );
        },
        c7 => sub {
            $supervisor->yield( 'info_status', [ $SHELL, 'c8' ], [ ], 'b' );
            $_[KERNEL]->delay( 'timeout' => 15 );
        },
        c8 => sub {
            my $r = $_[ARG1];
            my $ps = $r->{result};
            is $ps->is_running, 0, 'b should not restart';
            $_[KERNEL]->yield( 'shutdown' );
        },
        timeout => sub {
            fail "operation timeout";
            $_[KERNEL]->yield( 'shutdown' );
        },
        shutdown => sub {
            pass "shutdown";
            $_[KERNEL]->delay('timeout');
            $_[KERNEL]->alias_remove( $SHELL );
            $supervisor->yield( 'shutdown' );
        },
    },
);

POE::Kernel->run();


__END__
