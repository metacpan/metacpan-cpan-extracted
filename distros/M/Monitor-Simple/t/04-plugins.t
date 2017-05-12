#!perl -w

BEGIN {
    # skip all these tests if the default perl is not the same as the
    # perl used to start this test (because in such cases there may be
    # missing Perl modules during invocation the external plugins)
    use File::Which;
    use File::Spec;
    my $default_perl = which ('perl');
    my $test_perl    = $^X;
    if (File::Spec->case_tolerant()) {
      $default_perl  = lc($default_perl);
      $test_perl     = lc($test_perl);
    }
    unless ($default_perl and $default_perl eq $test_perl) {
        require Test::More;
        Test::More::plan (skip_all => 'default perl differs from the one used for testing');
    }
}

#use Test::More qw(no_plan);
use Test::More tests => 23;

use File::Slurp;
use File::Temp qw/ tempfile /;

#-----------------------------------------------------------------
# Return a fully qualified name of the given file in the test
# directory "t/data" - if such file really exists. With no arguments,
# it returns the path of the test directory itself.
# -----------------------------------------------------------------
use FindBin qw( $Bin );
use File::Spec;
sub test_file {
    my $file = File::Spec->catfile ('t', 'data', @_);
    return $file if -e $file;
    $file = File::Spec->catfile ($Bin, 'data', @_);
    return $file if -e $file;
    return File::Spec->catfile (@_);
}

#-----------------------------------------------------------------
# Return a configuration extracted from the given file.
# -----------------------------------------------------------------
sub get_config {
    my $filename = shift;
    my $config_file = test_file ($filename);
    my $config = Monitor::Simple::Config->get_config ($config_file);
    ok ($config, "Failed configuration taken from '$config_file'");
    return $config;
}

# -----------------------------------------------------------------
# Tests start here...
# -----------------------------------------------------------------
ok(1);
use Monitor::Simple;
diag( "Testing external plugins" );

my $config = get_config ('plugins.xml');
my $config_file = test_file ('plugins.xml');

sub do_checking {
    my ($title, $args, $filename, $expected_lines) = @_;
    Monitor::Simple->check_services ($args);
    my @lines = read_file ($filename);
#    diag ($title);
#    diag (join ("\n", map { chomp; $_ } @lines));
    is (scalar @lines, $expected_lines, "Number of parallel service checks [$title]");
    foreach my $line (@lines) {
        my @fields = split (/\t/, $line, 4);
        is (scalar @fields, 4, "Found only partional line [$title]: $line");
    }
}

# report and exit (one by one); filter as SCALAR
{
    my $report_tests = {
        ok       => 0,
        warning  => 1,
        critical => 2,
        unknown  => 3,
    };

    foreach my $service (keys %$report_tests) {
        my ($fh, $filename) = tempfile();
        my $args = {
            config_file => $config_file,
            filter      => $service,
            outputter   => Monitor::Simple::Output->new (outfile  => $filename,
                                                         'format' => 'tsv',
                                                         config   => $config),
        };
        do_checking ("In SCALAR [$service]:", $args, $filename, 1);
        unlink $filename;
    }
}

# report and exit (in parallel); filters as HASH
{
    my ($fh, $filename) = tempfile();
    my $filters = {
        ok       => 0,
        warning  => 1,
        critical => 2,
        unknown  => 3,
    };
    my $args = {
        config_file => $config_file,
        filter      => $filters,
        outputter   => Monitor::Simple::Output->new (outfile  => $filename,
                                                     'format' => 'tsv',
                                                     config   => $config),
    };
    do_checking ('In HASH:', $args, $filename, 4);
    unlink $filename;
}

# report and exit (in parallel); filters as ARRAY
{
    my ($fh, $filename) = tempfile();
    my $filters = ['ok', 'warning', 'critical', 'unknown'];
    my $args = {
        config_file => $config_file,
        filter      => $filters,
        outputter   => Monitor::Simple::Output->new (outfile  => $filename,
                                                     'format' => 'tsv',
                                                     config   => $config),
    };
    do_checking ('In ARRAY:', $args, $filename, 4);
    unlink $filename;
}

# plugin: check-prg.pl
{
    my ($fh, $filename) = tempfile();
    my $filters = {
        prg     => 0,
        prgbad  => 3,
    };
    my $outputter = Monitor::Simple::Output->new (outfile  => $filename,
                                                  'format' => 'tsv',
                                                  config   => $config);
    my $args = {
        config_file => $config_file,
        filter      => $filters,
        outputter   => $outputter,
    };
    do_checking ('In PRG:', $args, $filename, 2);
    unlink $filename;
}

__END__
