use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use IO::Async::Process;
use FindBin;

plan skip_all => "Server integration tests not supported on Windows" if $^O eq 'MSWin32';

# When every worker fails lifespan startup in multi-worker mode, the master must
# not become a zombie (holding the listening socket with zero workers serving
# and never exiting). It must terminate with a non-zero exit code so a process
# supervisor (systemd/docker/k8s) detects the failure and can restart it.

my $lib     = "$FindBin::Bin/../lib";
my $server  = "$FindBin::Bin/../bin/pagi-server";
my $appfile = "$FindBin::Bin/_zombie-master-app-$$.pl";

open my $fh, '>', $appfile or die "cannot write $appfile: $!";
print $fh <<'APP';
use strict; use warnings; use Future::AsyncAwait;
my $app = async sub {
    my ($scope, $receive, $send) = @_;
    if ($scope->{type} eq 'lifespan') {
        await $receive->();
        await $send->({ type => 'lifespan.startup.failed', message => 'cannot start' });
        return;
    }
    die "Unsupported scope type: $scope->{type}";
};
$app;
APP
close $fh;

subtest 'master exits non-zero when all workers fail startup (does not hang)' => sub {
    my $loop = IO::Async::Loop->new;

    my $exitcode;
    my $proc = IO::Async::Process->new(
        command => [ $^X, "-I$lib", $server,
                     '--app', $appfile, '--port', 0, '--workers', 2 ],
        setup => [
            stdout => [ 'open', '>', '/dev/null' ],
            stderr => [ 'open', '>', '/dev/null' ],
        ],
        on_finish => sub { (undef, $exitcode) = @_ },
    );
    $loop->add($proc);

    my $timeout  = $loop->delay_future(after => 15)->then(sub { Future->done('timeout') });
    my $finished = $proc->finish_future->then(sub { Future->done('finished') });
    my $which    = Future->wait_any($finished, $timeout)->get;

    is($which, 'finished', 'master terminated instead of hanging as a zombie');

    if ($which eq 'finished') {
        isnt($exitcode >> 8, 0, 'master exited non-zero so a supervisor will restart it')
            or diag("raw wstatus: $exitcode");
    }
    else {
        $proc->kill('KILL');
    }
};

unlink $appfile;
done_testing;
