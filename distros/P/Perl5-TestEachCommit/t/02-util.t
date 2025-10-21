# t/02-util.t
use 5.014;
use warnings;
use Perl5::TestEachCommit::Util qw(
    process_command_line
);
use Test::More tests => 35;

my ($workdir, $branch, $start, $end, $verbose,
    $configure_command, $make_test_prep_command,
    $make_test_harness_command, $skip_test_harness,
    $make_minitest_prep_command, $make_minitest_command);

$workdir     = '/tmp';
$branch      = 'blead';
$start       = '001';
$end         = '002';
$verbose     = '';
$configure_command       = 'sh ./Configure -des -Dusedevel';
$make_test_prep_command     = 'make test_prep';
$make_test_harness_command  = 'make test_harness';
$skip_test_harness = '';
$make_minitest_prep_command = 'make minitest_prep';
$make_minitest_command      = 'make minitest';

note("Typical case: make test_prep and make harness");

{
    note("Calling neither 'verbose' nor 'skip_test_harness'");
    local @ARGV = (
        '--workdir'     => $workdir,
        '--branch'      => $branch,
        '--start'       => $start,
        '--end'         => $end,
        #    '--verbose'     => $verbose,
        '--configure_command'       => $configure_command,
        '--make_test_prep_command'  => $make_test_prep_command,
        '--make_test_harness_command'   => $make_test_harness_command,
        #'--skip_test_harness' => $skip_test_harness,
    );

    my $opts = process_command_line();
    is(ref($opts), 'HASH', "process_command_line returned a hashref");
    is($opts->{workdir}, $workdir, "Got expected workdir");
    is($opts->{branch}, $branch, "Got expected branch");
    is($opts->{start}, $start, "Got expected start");
    is($opts->{end}, $end, "Got expected end");
    ok(! $opts->{verbose}, "verbose not selected");
    is($opts->{start}, $start, "Got expected start");
    is($opts->{configure_command}, $configure_command,
        "Got expected configure_command");
    is($opts->{make_test_prep_command}, $make_test_prep_command,
        "Got expected make_test_prep_command");
    is($opts->{make_test_harness_command}, $make_test_harness_command,
        "Got expected make_test_harness_command");
    ok(! $opts->{skip_test_harness}, "skip_test_harness not selected");
}

{
    note("Calling both 'verbose' and 'skip_test_harness'");
    my ($skip_test_harness, $verbose) = (undef) x 2;
    local @ARGV = (
        '--workdir'     => $workdir,
        '--branch'      => $branch,
        '--start'       => $start,
        '--end'         => $end,
        '--verbose'     => $verbose,
        '--configure_command'       => $configure_command,
        '--make_test_prep_command'  => $make_test_prep_command,
        '--make_test_harness_command'   => $make_test_harness_command,
        '--skip_test_harness' => $skip_test_harness,
    );

    my $opts = process_command_line();
    is(ref($opts), 'HASH', "process_command_line returned a hashref");
    is($opts->{workdir}, $workdir, "Got expected workdir");
    is($opts->{branch}, $branch, "Got expected branch");
    is($opts->{start}, $start, "Got expected start");
    is($opts->{end}, $end, "Got expected end");
    ok($opts->{verbose}, "verbose selected");
    is($opts->{start}, $start, "Got expected start");
    is($opts->{configure_command}, $configure_command,
        "Got expected configure_command");
    is($opts->{make_test_prep_command}, $make_test_prep_command,
        "Got expected make_test_prep_command");
    is($opts->{make_test_harness_command}, $make_test_harness_command,
        "Got expected make_test_harness_command");
    ok($opts->{skip_test_harness}, "skip_test_harness selected");
}

note("Mini case: make minitest_prep and make minitest");

{
    local @ARGV = (
        '--workdir'     => $workdir,
        '--branch'      => $branch,
        '--start'       => $start,
        '--end'         => $end,
        #    '--verbose'     => $verbose,
        '--configure_command'           => $configure_command,
        '--make_minitest_prep_command'  => $make_minitest_prep_command,
        '--make_minitest_command'       => $make_minitest_command,
    );

    my $opts = process_command_line();
    is(ref($opts), 'HASH', "process_command_line returned a hashref");
    is($opts->{workdir}, $workdir, "Got expected workdir");
    is($opts->{branch}, $branch, "Got expected branch");
    is($opts->{start}, $start, "Got expected start");
    is($opts->{end}, $end, "Got expected end");
    ok(! $opts->{verbose}, "verbose not selected");
    is($opts->{start}, $start, "Got expected start");
    is($opts->{configure_command}, $configure_command,
        "Got expected configure_command");
    ok(! $opts->{make_test_prep_command}, "make test_prep not selected");
    ok(! $opts->{make_test_harness_command}, "make test_harness not selected");
    ok(! $opts->{skip_test_harness}, "skip_test_harness not selected");
    is($opts->{make_minitest_prep_command}, $make_minitest_prep_command,
        "Got expected make_minitest_prep_command");
    is($opts->{make_minitest_command}, $make_minitest_command,
        "Got expected make_minitest_command");
}

