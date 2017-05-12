use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;
use Test::Moose;
use File::Temp qw(tempdir);
use File::Spec::Functions;

my $dir = tempdir( CLEANUP => 1 );

BEGIN {
    use_ok('MooseX::Daemonize::Core');
    use_ok('MooseX::Daemonize::Pid');
}

use constant DEBUG => 0;

$ENV{MX_DAEMON_STDOUT} = catfile($dir, 'Out.txt');
$ENV{MX_DAEMON_STDERR} = catfile($dir, 'Err.txt');

{
    package MyFooDaemon;
    use Moose;

    with 'MooseX::Daemonize::Core';

    has 'daemon_pid' => (is => 'rw', isa => 'MooseX::Daemonize::Pid');

    # capture the PID from the fork
    around 'daemon_fork' => sub {
        my $next = shift;
        my $self = shift;
        if (my $pid = $self->$next(@_)) {
            $self->daemon_pid(
                MooseX::Daemonize::Pid->new(pid => $pid)
            );
        }
    };

    sub start {
        my $self = shift;
        # tell it to ignore zombies ...
        $self->ignore_zombies( 1 );
        $self->no_double_fork( 1 );
        $self->daemonize;
        return unless $self->is_daemon;
        # change to our local dir
        # so that we can debug easier
        chdir $dir;
        # make it easy to find with ps
        $0 = 'test-app';
        $SIG{INT} = sub {
            print "Got INT! Oh Noes!";
            exit;
        };
        while (1) {
            print "Hello from $$\n";
            sleep(10);
        }
        exit;
    }
}

my $d = MyFooDaemon->new;
isa_ok($d, 'MyFooDaemon');
does_ok($d, 'MooseX::Daemonize::Core');

is(
    exception { $d->start },
    undef,
    '... successfully daemonized from (' . $$ . ')',
);

my $p = $d->daemon_pid;
isa_ok($p, 'MooseX::Daemonize::Pid');

ok($p->is_running, '... the daemon process is running (' . $p->pid . ')');

my $pid = $p->pid;
if (DEBUG) {
    diag `ps $pid`;
    diag "-------";
    diag `ps -x | grep test-app`;
    diag "-------";
    diag "killing $pid";
}
kill INT => $p->pid;
diag "killed $pid" if DEBUG;

# give the process time to be killed on slow/loaded systems
for (1..10) {
    last unless kill 0 => $pid;
    # sleep a little before retrying
    sleep(2);
}

if (DEBUG) {
    diag `ps $pid`;
    diag "-------";
    diag `ps -x | grep test-app`;
}

ok(!$p->is_running, '... the daemon process is no longer running (' . $p->pid . ')');

unlink $ENV{MX_DAEMON_STDOUT};
unlink $ENV{MX_DAEMON_STDERR};

done_testing;

