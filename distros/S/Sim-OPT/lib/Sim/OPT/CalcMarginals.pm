package Sim::OPT::CalcMarginals;

# This is the module Sim::OPT::CalcMarginals of Sim::OPT.
# It calculates empirical marginal distributions of discrete variables and
# level-specific distributions of a selected numerical response.

use strict;
use warnings;
use Exporter qw(import);
use Scalar::Util qw(looks_like_number);
use File::Basename qw(dirname basename);
use File::Spec;

our $VERSION = '0.001';
our $ABSTRACT = 'Calculate marginal and level-specific response distributions for Sim::OPT results.';
our @EXPORT_OK = qw(run run_config load_config);

sub _fmt_num {
    my ($x) = @_;
    my $s = sprintf('%.12f', $x);
    $s =~ s/0+$//;
    $s =~ s/\.$//;
    return $s;
}

sub run {
    my ($cfg, $config_dir) = @_;

    die "Configuration must be a hash reference\n" unless ref($cfg) eq 'HASH';

    # When run() is called directly, relative paths are resolved from the
    # supplied base directory, or from the current directory if none is given.
    $config_dir = '.' unless defined($config_dir) && length($config_dir);
    $config_dir = File::Spec->rel2abs($config_dir);

    my $file       = $cfg->{file};
    my $levels_ref = $cfg->{levels};
    my $colind     = $cfg->{column};
    my $divisions  = $cfg->{divisions};
    my $best       = $cfg->{best};
    my $worst      = $cfg->{worst};

    die "No input file specified (key: file)\n"
        unless defined($file) && length($file);
    die "The variable-level structure (key: levels) must be a hash reference\n"
        unless ref($levels_ref) eq 'HASH';
    die "CSV column index (key: column) must be a non-negative integer\n"
        unless defined($colind) && $colind =~ /^\d+$/;
    die "Number of bins (key: divisions) must be a positive integer\n"
        unless defined($divisions) && $divisions =~ /^\d+$/ && $divisions > 0;
    die "'best' and 'worst' must both be numeric\n"
        unless looks_like_number($best) && looks_like_number($worst);
    die "'best' and 'worst' must be different values\n" if $best == $worst;

    my $objective = ($best < $worst) ? 'minimization' : 'maximization';
    my ($lower, $upper) = ($best < $worst) ? ($best, $worst) : ($worst, $best);

    my @factors = sort { $a <=> $b } keys %{$levels_ref};
    die "No variables requested\n" unless @factors;

    foreach my $factor (@factors) {
        die "Invalid number of levels for variable $factor\n"
            unless defined($levels_ref->{$factor})
                && $levels_ref->{$factor} =~ /^\d+$/
                && $levels_ref->{$factor} > 0;
    }

    # Relative input paths are interpreted relative to the configuration file
    # (or to $config_dir when run() is called directly).
    my $input_path = File::Spec->file_name_is_absolute($file)
        ? $file
        : File::Spec->catfile($config_dir, $file);

    my $output_dir = defined($cfg->{output_dir}) ? $cfg->{output_dir} : $config_dir;
    $output_dir = File::Spec->catdir($config_dir, $output_dir)
        unless File::Spec->file_name_is_absolute($output_dir);
    die "Output directory '$output_dir' does not exist\n" unless -d $output_dir;

    open my $in, '<', $input_path
        or die "Cannot open '$input_path': $!\n";

    my $width = ($upper - $lower) / $divisions;
    my %marginal_count;
    my %hist;
    my %in_range_count;
    my $row_count = 0;
    my $numeric_response_count = 0;
    my $outside_better = 0;
    my $outside_worse = 0;

    while (my $line = <$in>) {
        chomp $line;
        $line =~ s/\r$//;
        next if $line eq '';
        $row_count++;

        my @fields = split /,/, $line, -1;
        die "Row $row_count has no CSV column $colind\n" if $colind > $#fields;

        my %state;
        foreach my $token (split /_/, $fields[0]) {
            if ($token =~ /^(\d+)-(\d+)$/) {
                $state{$1} = $2;
            }
        }

        foreach my $factor (@factors) {
            die "Row $row_count does not contain variable $factor in field 0\n"
                unless exists $state{$factor};

            my $level = $state{$factor};
            my $declared_levels = $levels_ref->{$factor};
            if ($level < 1 || $level > $declared_levels) {
                die "Row $row_count contains variable $factor at level $level, "
                  . "but the configuration declares only levels 1..$declared_levels\n";
            }
            $marginal_count{$factor}{$level}++;
        }

        my $x = $fields[$colind];
        next unless looks_like_number($x);
        $numeric_response_count++;
        $x += 0;

        if ($x < $lower || $x > $upper) {
            # Report out-of-range values semantically, relative to the objective.
            if (($objective eq 'minimization' && $x < $best)
                || ($objective eq 'maximization' && $x > $best)) {
                $outside_better++;
            }
            else {
                $outside_worse++;
            }
            next;
        }

        # One integer bin index per observation avoids overlapping floating-point
        # boundaries. Internal bins are indexed from numerical lower to upper.
        my $bin;
        if ($x == $upper) {
            $bin = $divisions - 1;
        }
        else {
            $bin = int(($x - $lower) / $width);
        }
        $bin = 0 if $bin < 0;
        $bin = $divisions - 1 if $bin >= $divisions;

        foreach my $factor (@factors) {
            my $level = $state{$factor};
            $hist{$factor}{$level}[$bin]++;
            $in_range_count{$factor}{$level}++;
        }
    }
    close $in;

    my $stem = basename($file);
    $stem =~ s/\.csv$//i;

    my $marginal_file = File::Spec->catfile($output_dir, "marginals_${stem}.csv");
    my $counts_file   = File::Spec->catfile($output_dir, "distributions_counts_${stem}.csv");
    my $pct_file      = File::Spec->catfile($output_dir, "distributions_percentages_${stem}.csv");

    # Raw marginal distribution of each discrete variable.
    open my $mout, '>', $marginal_file
        or die "Cannot create '$marginal_file': $!\n";
    print {$mout} "variable,level,count,percentage\n";
    foreach my $factor (@factors) {
        my $factor_total = 0;
        for my $level (1 .. $levels_ref->{$factor}) {
            $factor_total += $marginal_count{$factor}{$level} // 0;
        }
        for my $level (1 .. $levels_ref->{$factor}) {
            my $count = $marginal_count{$factor}{$level} // 0;
            my $pct = $factor_total ? 100 * $count / $factor_total : 0;
            print {$mout} join(',', $factor, $level, $count, _fmt_num($pct)), "\n";
        }
    }
    close $mout;

    # Internally centres are numerical low -> high. For output, order them
    # best -> worst so that the plot direction follows the optimization goal.
    my @centres_low_to_high;
    for my $bin (0 .. $divisions - 1) {
        push @centres_low_to_high, $lower + ($bin + 0.5) * $width;
    }
    my @output_bins = ($objective eq 'minimization')
        ? (0 .. $divisions - 1)
        : reverse(0 .. $divisions - 1);
    my @output_centres = map { $centres_low_to_high[$_] } @output_bins;

    # Conditional histograms as raw counts.
    open my $cout, '>', $counts_file
        or die "Cannot create '$counts_file': $!\n";
    print {$cout} "variable-level," . join(',', map { _fmt_num($_) } @output_centres) . "\n";
    foreach my $factor (@factors) {
        for my $level (1 .. $levels_ref->{$factor}) {
            my @vals = map { $hist{$factor}{$level}[$_] // 0 } @output_bins;
            print {$cout} "$factor-$level," . join(',', @vals) . "\n";
        }
    }
    close $cout;

    # Same histograms normalized separately within every variable level.
    open my $pout, '>', $pct_file
        or die "Cannot create '$pct_file': $!\n";
    print {$pout} "variable-level," . join(',', map { _fmt_num($_) } @output_centres) . "\n";
    foreach my $factor (@factors) {
        for my $level (1 .. $levels_ref->{$factor}) {
            my $den = $in_range_count{$factor}{$level} // 0;
            my @vals;
            foreach my $bin (@output_bins) {
                my $count = $hist{$factor}{$level}[$bin] // 0;
                my $pct = $den ? 100 * $count / $den : 0;
                push @vals, _fmt_num($pct);
            }
            print {$pout} "$factor-$level," . join(',', @vals) . "\n";
        }
    }
    close $pout;

    print "Objective inferred from best/worst: $objective\n";
    print "Best: " . _fmt_num($best) . "\n";
    print "Worst: " . _fmt_num($worst) . "\n";
    print "Processed rows: $row_count\n";
    print "Numeric responses in CSV column $colind: $numeric_response_count\n";
    print "Numerical interval: [" . _fmt_num($lower) . ", " . _fmt_num($upper) . "]\n";
    print "Output direction: best -> worst\n";
    print "Bins: $divisions (width " . _fmt_num($width) . ")\n";
    print "Values outside interval on better-than-best side: $outside_better\n";
    print "Values outside interval on worse-than-worst side: $outside_worse\n";
    print "Created: $marginal_file\n";
    print "Created: $counts_file\n";
    print "Created: $pct_file\n";

    # Returning structured information makes the module convenient to call from
    # other Sim::OPT code without having to parse the diagnostic text.
    return {
        objective              => $objective,
        best                   => 0 + $best,
        worst                  => 0 + $worst,
        lower                  => 0 + $lower,
        upper                  => 0 + $upper,
        divisions              => 0 + $divisions,
        bin_width              => 0 + $width,
        processed_rows         => $row_count,
        numeric_responses      => $numeric_response_count,
        outside_better         => $outside_better,
        outside_worse          => $outside_worse,
        marginal_file          => $marginal_file,
        counts_file            => $counts_file,
        percentages_file       => $pct_file,
    };
}

sub load_config {
    my ($path) = @_;
    die "No configuration file specified\n" unless defined($path) && length($path);

    my $abs = File::Spec->rel2abs($path);
    die "Configuration file '$path' does not exist\n" unless -f $abs;

    my $cfg = do $abs;
    if (!defined $cfg) {
        die "Could not read configuration file '$path': $!\n" if $!;
        die "Could not compile configuration file '$path': $@\n" if $@;
        die "Configuration file '$path' did not return a configuration\n";
    }
    die "Configuration file '$path' must return a hash reference\n"
        unless ref($cfg) eq 'HASH';

    return ($cfg, dirname($abs));
}

sub run_config {
    my ($path) = @_;
    my ($cfg, $config_dir) = load_config($path);
    return run($cfg, $config_dir);
}

1;

__END__

=head1 NAME

Sim::OPT::CalcMarginals - calculate marginal and level-specific response distributions

=head1 SYNOPSIS

    use Sim::OPT::CalcMarginals qw(run_config);

    run_config('marginals_config.pl');

Or call it directly with a configuration hash reference:

    use Sim::OPT::CalcMarginals qw(run);

    my $result = run({
        file      => 'amtry-0_totres.csv',
        levels    => { 1 => 5, 2 => 5, 3 => 5, 4 => 3 },
        column    => 2,
        divisions => 100,
        best      => 60,
        worst     => 80,
    }, '.');

=head1 DESCRIPTION

The module calculates two related kinds of distributions from a Sim::OPT-style
CSV results file.

First, it calculates the empirical marginal distribution of each discrete
variable encoded in CSV field 0 as C<variable-level> tokens separated by
underscores.

Second, for every level of every requested variable, it calculates a histogram
of the numerical response selected by C<column>.  The histogram is written both
as raw counts and as percentages normalized independently within each level.

The optimization direction is inferred from C<best> and C<worst>:
C<best < worst> means minimization; C<best > worst> means maximization.

=head1 CONFIGURATION

A configuration file is an ordinary Perl file that returns a hash reference.
Recognized keys are:

=over 4

=item * C<file>

Input CSV filename.

=item * C<levels>

Hash reference mapping variable numbers to their declared number of levels.

=item * C<column>

Zero-based CSV column containing the numerical response.

=item * C<divisions>

Number of histogram bins.

=item * C<best>, C<worst>

Response values defining the optimization direction and histogram interval.

=item * C<output_dir>

Optional output directory.  Relative paths are resolved relative to the
configuration file.  By default, outputs are written next to that file.

=back

=head1 OUTPUT FILES

For an input named C<name.csv>, the module writes:

    marginals_name.csv
    distributions_counts_name.csv
    distributions_percentages_name.csv

=head1 FUNCTIONS

=head2 run_config($path)

Loads a configuration file and runs the calculation.  Returns a hash reference
containing summary information and the three generated output paths.

=head2 run($config, $base_directory)

Runs the calculation from a configuration hash reference.  Relative paths are
resolved from C<$base_directory>, or from the current directory if omitted.

=head2 load_config($path)

Loads and validates the configuration container itself.  In list context it
returns the configuration hash reference and the directory containing the file.

=cut
