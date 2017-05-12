use Test::Most;
use Parallel::Boss;

use Path::Tiny;
use POSIX ":sys_wait_h";
use Time::HiRes;
my $dir = Path::Tiny->tempdir;

my $worker = sub {
    my ( $boss, @args ) = @_;
    $0 = "parallel-boss test worker";
    $dir->child("$$")->spew( map { "$_\n" } @args );
    while (1) {
        sleep 5;
    }
};

my $pid = fork;
die "Couldn't fork: $!" unless defined $pid;

if ( $pid == 0 ) {
    $0 = "parallel-boss test boss";
    Parallel::Boss->run(
        num_workers => 4,
        args        => [qw(foo bar baz)],
        worker      => $worker,
    );
    exit 0;
}

sub wait4files {
    my $tries = 20;
    my @files;
    while ($tries) {
        Time::HiRes::sleep(0.2);
        @files = $dir->children;
        last if @files >= 4;
        --$tries;
    }

    is @files, 4, "4 files were created";
    for (@files) {
        eq_or_diff [ $_->lines( { chomp => 1 } ) ], [qw(foo bar baz)],
          "expected content in $_";
    }

    return @files;
}

note "boss should start 4 workers";
my @files = wait4files();

note "if worker dies, boss should hire a new one";
$files[0]->remove;
kill KILL => $files[0]->basename;
@files = wait4files();

note "if boss receives SIGHUP it should kill workers and hire new ones";
$_->remove for @files;
kill HUP => $pid;
@files = wait4files();

note "if boss receives SIGTERM it should kill workers and quit";
my %pids = map { $_->basename => 1 } @files;
$_->remove for @files;
kill TERM => $pid;
my $tries = 20;
while ( $tries-- ) {
    Time::HiRes::sleep(0.2);
    my $kid = waitpid -1, WNOHANG;
    last if $kid == $pid;
}

ok !kill( ZERO => $pid ), "boss exited";
ok !kill( ZERO => keys %pids ), "all workers exited";

subtest "Boss killed" => sub {
    my $worker = sub {
        my ( $boss, @args ) = @_;
        my $wpid = $$;
        $dir->child($wpid)->spew( map { "$_\n" } @args );
        $SIG{TERM} = sub {
            $dir->child($wpid)->spew( map { "$_\n" } @args );
        };
        while (1) {
            sleep 5;
        }
    };

    my $pid = fork;
    die "Couldn't fork: $!" unless defined $pid;

    if ( $pid == 0 ) {
        Parallel::Boss->run(
            num_workers  => 4,
            args         => [qw(foo bar baz)],
            exit_timeout => 5,
            worker       => $worker,
        );
        exit 0;
    }

    note "boss should start 4 workers";
    my @files = wait4files();

    note "if boss is killed, workers should notice and quit";
    $_->remove for @files;
    my @pids = sort map { $_->basename } @files;
    kill KILL => $pid;
    my @new_files = wait4files();
    eq_or_diff
      [ sort map { $_->basename } @new_files ], \@pids,
      "workers are still the same, they got SIGTERM";

    my $tries = 50;
    while ( $tries and kill ZERO => @pids ) {
        Time::HiRes::sleep(0.2);
        --$tries;
    }

    ok !kill( ZERO => @pids ), "all workers have exited";
};

done_testing;
