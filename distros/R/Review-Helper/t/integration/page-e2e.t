# Test origin: AI
use v5.36;
use Test2::V0;

use File::Spec;
use Time::HiRes qw/time/;

# The driver fails itself after this many seconds, so the TAP names the
# timeout; the alarm here is a safeguard a minute later.
my $limit = $ENV{REVIEW_HELPER_E2E_TIMEOUT} // 180;
$limit =~ m/\A[1-9][0-9]*\z/ or die "REVIEW_HELPER_E2E_TIMEOUT must be a whole number of seconds above 0, not '$limit'\n";

sub find_bin(@names) {
    for my $name (@names) {
        my ($bin) = grep { -x } map { File::Spec->catfile($_, $name) } File::Spec->path;
        return $bin if $bin;
    }
    return;
}

# The page drive is the repository's backend-neutral conformance check; a
# built distribution does not carry it.
my $drive_script = File::Spec->catfile(File::Spec->updir, 'conformance', 'page-drive.mjs');
skip_all "the conformance page drive is not here (run from perl/ in a checkout)" unless -f $drive_script;

my $node   = find_bin('node')                            or skip_all "node is not installed";
my $chrome = find_bin(qw/google-chrome-stable chromium/) or skip_all "neither google-chrome-stable nor chromium is installed";

my ($pid, $server);

sub stop_server() {
    return unless $pid;
    local $?;
    kill TERM => $pid;
    close($server);
    undef $pid;
}

END { stop_server() }

# Serve the setup's review (with @mode, its other fixture) and drive the
# page against it.
sub drive(@mode) {
    $pid = open($server, '-|', $^X, (map { "-I$_" } grep { !ref } @INC), 't/scripts/page-e2e-setup.pl', @mode) // die "Cannot run the setup script: $!";
    my $server_pid = $pid;

    my $url = eval {
        local $SIG{ALRM} = sub { die "timed out\n" };
        alarm 30;
        my $line = <$server>;
        alarm 0;
        $line;
    };
    chomp($url) if defined $url;
    like($url, qr{^http://127\.0\.0\.1:\d+/$}, 'setup serves the review') or bail_out("no server: " . ($@ || 'no URL printed'));

    my $out = '';
    {
        # The drive inherits AUTHOR_TESTING, which turns on its author-only
        # checks.
        local $ENV{CHROME}                    = $chrome;
        local $ENV{REVIEW_HELPER_E2E_TIMEOUT} = $limit;
        my $start = time;
        my $drive = open(my $fh, '-|', $node, $drive_script, @mode, $url) // die "Cannot run node: $!";
        my $ok    = eval {
            local $SIG{ALRM} = sub { die "timed out\n" };
            alarm $limit + 60;
            # Progress notes as the drive goes, so a harness that kills a test
            # gone quiet (yath's event timeout) sees it is still running; the
            # driver prints a line at least every ten seconds.
            my ($checks, $said) = (0, time);
            while (my $line = <$fh>) {
                $out .= $line unless $line eq "# alive\n";
                $checks++                if $line =~ m/^(?:not )?ok /;
                note "page-drive: $line" if $line =~ m/^not ok |# skip /;
                next                     if time - $said < 10;
                note "page-drive: $checks checks so far";
                $said = time;
            }
            alarm 0;
            1;
        };
        diag "page-drive: $@" unless $ok;
        kill TERM => $drive unless $ok;
        close($fh);
        note sprintf('page-drive took %.1fs of its %ds', time - $start, $limit);
        is($?, 0, 'page-drive exits 0') or diag $out;
    }
    like($out, qr/^1\.\.\d+$/m, 'page-drive ran to the end');
    unlike($out, qr/^not ok/m, 'every page check passes');

    stop_server();
    ok(!kill(0 => $server_pid), 'server stopped');
}

subtest 'the history review'                  => sub { drive() };
subtest 'a squashed review split into topics' => sub { drive('--topics') };

done_testing;
