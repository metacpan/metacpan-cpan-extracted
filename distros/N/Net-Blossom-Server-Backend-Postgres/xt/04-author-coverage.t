use strictures 2;

use Config ();
use Cwd qw(getcwd);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use Test::More;

plan skip_all => 'AUTHOR_TESTING is not set'
    unless $ENV{AUTHOR_TESTING};
plan skip_all => 'COVERAGE_TESTING is not set'
    unless $ENV{COVERAGE_TESTING};
plan skip_all => 'coverage author test requires Perl 5.20 or later'
    if $] < 5.020;
plan skip_all => 'NET_BLOSSOM_POSTGRES_DSN is not set'
    unless $ENV{NET_BLOSSOM_POSTGRES_DSN};

my $prove = _which('prove')
    or plan skip_all => 'prove is required for coverage author tests';
my $cover = _which('cover')
    or plan skip_all => 'Devel::Cover is required for coverage author tests';

my ($cover_version_status) = _capture($cover, '-version');
plan skip_all => 'Devel::Cover is required for coverage author tests'
    if $cover_version_status != 0;

my $dist = "$FindBin::Bin/..";
my $db = tempdir('net-blossom-postgres-cover-XXXXXX', TMPDIR => 1, CLEANUP => 1);

my $test_status = _in_dir($dist, sub {
    local $ENV{HARNESS_PERL_SWITCHES} = join ',',
        '-MDevel::Cover=-db',
        $db,
        '-coverage',
        'statement',
        '-coverage',
        'subroutine',
        '+select',
        '^lib/';

    return system $prove, '-l', 't';
});
is($test_status, 0, 'regular test suite passes under Devel::Cover');
done_testing and exit if $test_status != 0;

my ($report_status, $report) = _in_dir($dist, sub {
    return _capture(
        $cover,
        '-report',
        'text',
        '-select_re',
        '^lib/',
        '-coverage',
        'statement',
        '-coverage',
        'subroutine',
        $db,
    );
});
is($report_status, 0, 'coverage report generated');
diag $report if $report_status != 0;

my ($statement, $subroutine, $total) = _total_coverage($report);
if (defined $statement && defined $subroutine && defined $total) {
    diag sprintf 'Coverage totals: statement %.1f%%, subroutine %.1f%%, total %.1f%%',
        $statement,
        $subroutine,
        $total;
    cmp_ok($statement, '>=', 95.0, 'statement coverage is at least 95%');
    cmp_ok($subroutine, '>=', 95.0, 'subroutine coverage is at least 95%');
}
else {
    fail('statement coverage is at least 95%');
    fail('subroutine coverage is at least 95%');
    diag $report;
}

done_testing;

sub _which {
    my ($program) = @_;
    my $exe = $Config::Config{_exe} || '';

    for my $dir (split /\Q$Config::Config{path_sep}\E/, $ENV{PATH} || '') {
        my $path = File::Spec->catfile($dir, $program);
        return $path if -x $path;
        return "$path$exe" if $exe && -x "$path$exe";
    }

    return;
}

sub _capture {
    my (@cmd) = @_;

    open my $fh, '-|', @cmd
        or die "Unable to run $cmd[0]: $!";
    my $output = do { local $/; <$fh> };
    close $fh;

    return ($?, $output);
}

sub _in_dir {
    my ($dir, $code) = @_;
    my $cwd = getcwd();
    my $wantarray = wantarray;
    my (@result, $result);

    chdir $dir
        or die "Unable to chdir to $dir: $!";
    my $ok = eval {
        if ($wantarray) {
            @result = $code->();
        }
        else {
            $result = $code->();
        }
        1;
    };
    my $error = $@;
    chdir $cwd
        or die "Unable to chdir back to $cwd: $!";
    die $error unless $ok;

    return $wantarray ? @result : $result;
}

sub _total_coverage {
    my ($report) = @_;
    return unless $report =~ /^Total\s+([0-9]+(?:\.[0-9]+)?)\s+([0-9]+(?:\.[0-9]+)?)\s+([0-9]+(?:\.[0-9]+)?)/m;
    return ($1, $2, $3);
}
