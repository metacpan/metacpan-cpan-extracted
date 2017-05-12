use strict;
use warnings;
use File::Spec::Functions;

use Test::More tests => 29;
use Test::Moose;

use File::Temp qw(tempdir);

my $dir = tempdir( CLEANUP => 1 );

BEGIN {
    use_ok('MooseX::Daemonize');
}

use constant DEBUG => 0;

my $FILENAME           = catfile($dir, "im_alive");
$ENV{MX_DAEMON_STDOUT} = catfile($dir, 'Out.txt');
$ENV{MX_DAEMON_STDERR} = catfile($dir, 'Err.txt');

{

    package FileMaker;
    use Moose;
    with qw(MooseX::Daemonize);

    has filename => ( isa => 'Str', is => 'ro' );

    after start => sub {
        my $self = shift;
        if ($self->is_daemon) {
            $self->create_file( $self->filename );
        }
    };

    sub create_file {
        my ( $self, $file ) = @_;
        open( my $FILE, ">$file" ) || die $!;
        close($FILE);
        sleep 1 while 1;
    }
}

my $app = FileMaker->new(
    pidbase  => "$dir/subdir",
    filename => $FILENAME,
);
isa_ok($app, 'FileMaker');
does_ok($app, 'MooseX::Daemonize');
does_ok($app, 'MooseX::Daemonize::WithPidFile');
does_ok($app, 'MooseX::Daemonize::Core');

isa_ok($app->pidfile, 'MooseX::Daemonize::Pid::File');

is($app->pidfile->file, catfile("$dir/subdir", "filemaker.pid"), '... got the right PID file path');
ok(not(-e $app->pidfile->file), '... our pidfile does not exist');

ok(!$app->status, '... the daemon is running');
is($app->exit_code, MooseX::Daemonize->ERROR, '... got the right error code');

ok($app->stop, '... the app will stop cause its not running');
is($app->status_message, "Not running", '... got the correct status message');
is($app->exit_code, MooseX::Daemonize->OK, '... got the right error code');

diag $$ if DEBUG;

ok($app->start, '... daemon started');
is($app->status_message, "Start succeeded", '... got the correct status message');
is($app->exit_code, MooseX::Daemonize->OK, '... got the right error code');

sleep(1); # give it a second ...

ok(-e $app->pidfile->file, '... our pidfile exists' );

my $pid = $app->pidfile->pid;
isnt($pid, $$, '... the pid in our pidfile is correct (and not us)');

ok($app->status, '... the daemon is running');
is($app->status_message, "Daemon is running with pid ($pid)", '... got the correct status message');
is($app->exit_code, MooseX::Daemonize->OK, '... got the right error code');

if (DEBUG) {
    diag `ps $pid`;
    diag "Status is: " . $app->status_message;
}

ok( -e $app->filename, "file exists" );

if (DEBUG) {
    diag `ps $pid`;
    diag "Status is: " . $app->status_message;
}

ok( $app->stop, '... app stopped' );
is($app->status_message, "Stop succeeded", '... got the correct status message');
is($app->exit_code, MooseX::Daemonize->OK, '... got the right error code');

ok(!$app->status, '... the daemon is no longer running');
is($app->status_message, "Daemon is not running with pid ($pid)", '... got the correct status message');
is($app->exit_code, MooseX::Daemonize->ERROR, '... got the right error code');

if (DEBUG) {
    diag `ps $pid`;
    diag "Status is: " . $app->status_message;
}

ok( not(-e $app->pidfile->file) , '... pidfile gone' );

unlink $FILENAME;
unlink $ENV{MX_DAEMON_STDOUT};
unlink $ENV{MX_DAEMON_STDERR};
