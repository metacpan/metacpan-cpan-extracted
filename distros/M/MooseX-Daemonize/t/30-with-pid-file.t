use strict;
use warnings;

use File::Spec::Functions;

use Test::More 0.88;
use Test::Fatal;
use Test::Moose;
use File::Temp qw(tempdir);

my $dir = tempdir( CLEANUP => 1 );


BEGIN {
    use_ok('MooseX::Daemonize::Core');
}

use constant DEBUG => 0;

my $PIDFILE            = catfile($dir, 'test-app.pid');
$ENV{MX_DAEMON_STDOUT} = catfile($dir, 'Out.txt');
$ENV{MX_DAEMON_STDERR} = catfile($dir, 'Err.txt');

{
    package MyFooDaemon;
    use Moose;

    with 'MooseX::Daemonize::WithPidFile';

    sub init_pidfile {
        MooseX::Daemonize::Pid::File->new( file => $PIDFILE )
    }

    sub start {
        my $self = shift;

        # this tests our bad PID
        # cleanup functionality.
        print "Our parent PID is " . $self->pidfile->pid . "\n" if ::DEBUG;

        $self->daemonize;
        return unless $self->is_daemon;

        # make it easy to find with ps
        $0 = 'test-app-2';
        $SIG{INT} = sub {
            print "Got INT! Oh Noes!";
            $self->pidfile->remove;
            exit;
        };
        while (1) {
            print "Hello from $$\n";
            sleep(10);
        }
        exit;
    }
}

my $d = MyFooDaemon->new( pidfile => $PIDFILE );
isa_ok($d, 'MyFooDaemon');
does_ok($d, 'MooseX::Daemonize::Core');
does_ok($d, 'MooseX::Daemonize::WithPidFile');

ok($d->has_pidfile, '... we have a pidfile value');

{
    my $p = $d->pidfile;
    isa_ok($p, 'MooseX::Daemonize::Pid::File');
    #diag $p->dump;
}

ok(!(-e $PIDFILE), '... the PID file does not exist yet');

is(
    exception { $d->start },
    undef,
    '... successfully daemonized from (' . $$ . ')',
);

my $p = $d->pidfile;
isa_ok($p, 'MooseX::Daemonize::Pid::File');
#diag $p->dump;

sleep(2);

ok($p->does_file_exist, '... the PID file exists');
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
ok(!(-e $PIDFILE), '... the PID file has been removed');

unlink $ENV{MX_DAEMON_STDOUT};
unlink $ENV{MX_DAEMON_STDERR};

done_testing;

