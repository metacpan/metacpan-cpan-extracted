# t/02-util.t
use 5.014;
use warnings;
use Perl5::TestEachCommit::Util qw(
    process_command_line
    usage
);
use Test::More tests => 14;
use Data::Dump qw(dd pp);
use Capture::Tiny qw(capture_stderr);

my $opts = process_command_line();
is(ref($opts), 'HASH', "process_command_line returned a hashref");

my ($workdir, $branch, $start, $end, $verbose,
    $configure_command, $make_test_prep_command,
    $make_test_harness_command, $skip_test_harness);

{
    $workdir     = '/tmp';
    $branch      = 'blead';
    $start       = '001';
    $end         = '002';
    $verbose     = '';
    $configure_command       = 'sh ./Configure -des -Dusedevel';
    $make_test_prep_command  = 'make test_prep';
    $make_test_harness_command   = 'make test_harness';
    $skip_test_harness = '';

    local @ARGV = (
        workdir     => $workdir,
        branch      => $branch,
        start       => $start,
        end         => $end,
        verbose     => $verbose,
        configure_command       => $configure_command,
        make_test_prep_command  => $make_test_prep_command,
        make_test_harness_command   => $make_test_harness_command,
        skip_test_harness => $skip_test_harness,
    );
    my $opts = process_command_line();
    is(ref($opts), 'HASH', "process_command_line returned a hashref");
    is($opts->{workdir}, $workdir, "Got expected workdir");
    is($opts->{branch}, $branch, "Got expected branch");
    is($opts->{start}, $start, "Got expected start");
    is($opts->{end}, $end, "Got expected end");
    ok(! $opts->{verbose}, "verbose not selected");
    is($opts->{start}, $start, "Got expected start");
    is($opts->{configure_command}, $configure_command, "Got expected configure_command");
    is($opts->{make_test_prep_command}, $make_test_prep_command, "Got expected make_test_prep_command");
    is($opts->{make_test_harness_command}, $make_test_harness_command, "Got expected make_test_harness_command");
    ok(! $opts->{skip_test_harness}, "skip_test_harness not selected");
    #pp $opts;
}

{
    local @ARGV = ( help    => 1 );
    my $opts;
    my $stderr = capture_stderr {
        $opts = process_command_line();
    };
    is(ref($opts), 'HASH', "process_command_line returned a hashref");
    my @lines = split /\n/, $stderr;
    like($lines[0], qr/^Usage:/, "usage statement executed");
}

