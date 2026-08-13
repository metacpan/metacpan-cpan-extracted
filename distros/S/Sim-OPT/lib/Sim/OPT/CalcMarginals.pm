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

Sim::OPT::CalcMarginals - calculate marginal and level-specific response distributions from Sim::OPT results

=head1 SYNOPSIS

=head2 Using a configuration file from Perl

The normal Perl API is C<run_config>.  The configuration is kept in a separate
Perl file and the module performs the calculation described by that file:

    use Sim::OPT::CalcMarginals qw(run_config);

    my $result = run_config('marginals_config.pl');

C<$result> is a hash reference containing summary information and the paths of
the three files that were created.

=head2 Running from the command line

If Sim::OPT is installed in Perl's normal module search path, the same
configuration file can be run directly from the shell with:

    perl -MSim::OPT::CalcMarginals=run_config \
         -e 'run_config(shift)' marginals_config.pl

If you are running from an unpacked Sim::OPT source tree and the module has not
yet been installed, add that distribution's C<lib> directory to Perl's search
path.  From the top directory of the Sim::OPT distribution, use:

    perl -Ilib -MSim::OPT::CalcMarginals=run_config \
         -e 'run_config(shift)' marginals_config.pl

The last argument is the configuration filename.  Relative input and output
paths in that configuration are interpreted relative to the directory that
contains the configuration file, not relative to the shell's current working
directory.

This module does not itself inspect C<@ARGV>.  A future command-line wrapper
can therefore call C<run_config> without changing the calculation code or the
configuration-file format.

=head2 Calling the calculation directly from Perl

Instead of a configuration file, a Perl program may pass a configuration hash
reference directly to C<run>:

    use Sim::OPT::CalcMarginals qw(run);

    my $result = run({
        file       => 'amtry-0_totres.csv',
        levels     => {
             1 => 5,  2 => 5,  3 => 5,
             4 => 3,  5 => 3,  6 => 3,  7 => 3,
             8 => 3,  9 => 3, 10 => 3, 11 => 3,
            12 => 3, 13 => 3, 14 => 3, 15 => 3,
            16 => 3, 17 => 3, 18 => 3, 19 => 3,
            20 => 3, 21 => 3, 22 => 3,
        },
        column     => 2,
        divisions  => 100,
        best       => 60,
        worst      => 80,
    }, '.');

The optional second argument is the base directory from which relative paths
are resolved.  If it is omitted, the current directory is used.

=head1 DESCRIPTION

C<Sim::OPT::CalcMarginals> analyzes a Sim::OPT-style CSV results file in two
related ways.

Each non-empty input row is expected to encode the state of the discrete
variables in CSV field 0.  A typical field looks like:

    1-5_2-5_3-4_4-1_5-3_..._22-3

Each C<variable-level> token means that the indicated variable took the
indicated discrete level on that row.  The configuration says which variables
are to be considered and how many levels each variable is allowed to have.

The module then calculates:

=over 4

=item 1. Empirical marginal distributions of the discrete variables

For every requested variable, the module counts how often each of its levels
occurs, independently of the levels taken by the other variables.  It also
expresses those counts as percentages of all observations counted for that
variable.

For example, if variable 8 has levels 1, 2, and 3, the marginal result answers:

    How often is variable 8 at level 1?
    How often is variable 8 at level 2?
    How often is variable 8 at level 3?

These are the ordinary empirical marginal distributions of the discrete
variables encoded in field 0.

=item 2. Response distributions conditional on every variable level

The configuration key C<column> selects one numerical CSV field, using
zero-based indexing.  Thus C<column =E<gt> 2> means the third CSV field.

For every requested variable and every one of its levels, the module collects
the selected numerical response values observed while that variable was at that
level.  It divides the interval between C<best> and C<worst> into the requested
number of equal bins and counts how many response values fall into each bin.

Thus a row labelled C<8-2> in a distribution file means:

    the distribution of the selected numerical response among observations
    for which variable 8 was at level 2

It does not mean the marginal distribution of variable 8 itself; that is
reported separately in C<marginals_*.csv>.

=back

=head1 CONFIGURATION FILE

A configuration file is an ordinary Perl file whose final value is a hash
reference.  For example:

    {
        file => 'amtry-0_totres.csv',

        levels => {
             1 => 5,  2 => 5,  3 => 5,
             4 => 3,  5 => 3,  6 => 3,  7 => 3,  8 => 3,  9 => 3,
            10 => 3, 11 => 3, 12 => 3, 13 => 3, 14 => 3, 15 => 3,
            16 => 3, 17 => 3, 18 => 3, 19 => 3, 20 => 3, 21 => 3,
            22 => 3,
        },

        column     => 2,
        divisions  => 100,
        best       => 60,
        worst      => 80,
    };

The terminating semicolon is recommended.  Because the file is loaded as Perl
code, it must evaluate to the hash reference shown above.

=head2 file

The input CSV filename.  An absolute path is used as written.  A relative path
is resolved relative to the directory containing the configuration file when
C<run_config> is used.

=head2 levels

A hash reference mapping each requested variable number to its number of
allowed levels.  For example:

    levels => { 1 => 5, 2 => 5, 3 => 3 }

means that variables 1 and 2 have levels 1 through 5, while variable 3 has
levels 1 through 3.

Every requested variable must be present in field 0 of every processed row.  A
level outside the declared range is treated as a configuration/data mismatch
and causes the calculation to stop with an explanatory error.  This validation
is intentional: it prevents a real level from being silently omitted.

=head2 column

Zero-based index of the CSV field containing the numerical response whose
level-specific distributions are required.

For example:

    column => 2

selects the third comma-separated field.

A non-numeric value in the selected response field is not used in the response
histograms.  The row is still used for the discrete-variable marginal counts,
provided its field-0 variable encoding is valid.

=head2 divisions

The number of equal histogram bins spanning the interval between C<best> and
C<worst>.

For example, with:

    best      => 60,
    worst     => 80,
    divisions => 100,

the numerical interval has width 20 and each bin has width 0.2.  The output
uses bin centres, therefore the centres are 60.1, 60.3, 60.5, and so on up to
79.9 when the objective is minimization.

Each in-range numerical observation is assigned to exactly one integer bin.
The upper numerical endpoint is explicitly assigned to the last internal bin.
This avoids the overlapping-boundary floating-point problem that can occur
when every bin boundary is repeatedly recomputed and compared independently.

=head2 best and worst

These are semantic endpoints of the response interval, not merely names for
its numerical minimum and maximum.

The module infers the optimization direction automatically:

    best < worst    minimization
    best > worst    maximization

For example:

    best  => 60,
    worst => 80,

means that smaller response values are better and the objective is
minimization.  Conversely:

    best  => 80,
    worst => 60,

means that larger response values are better and the objective is
maximization.

Internally, histogram binning is always performed from the numerical lower
endpoint to the numerical upper endpoint.  In the output distribution files,
however, the bins are currently ordered from C<best> toward C<worst>.  Thus a
minimization problem with best 60 and worst 80 is written from low to high,
whereas a maximization problem with best 80 and worst 60 is written from high
to low.

Values numerically outside the interval bounded by C<best> and C<worst> are not
included in the response histograms.  They are counted separately in the
terminal summary as lying on either the better-than-best side or the
worse-than-worst side, according to the inferred objective direction.

=head2 output_dir

Optional directory for the generated CSV files.  If omitted, results are
written next to the configuration file.  A relative C<output_dir> is resolved
relative to the configuration file's directory.

The directory must already exist.

=head1 HOW THE CALCULATIONS WORK

=head2 Discrete marginal distributions

For each non-empty row, the module parses field 0 into a mapping from variable
number to observed level.  For every variable named in C<levels>, it increments
one counter for the observed level.

If variable I<v> has C<L> declared levels, the count for level I<l> is:

    count(v,l) = number of processed rows in which variable v is at level l

The percentage written for that level is:

    100 * count(v,l) / sum_over_all_levels(count(v,*))

Consequently, the level percentages for each variable sum to 100%, apart from
normal floating-point formatting effects.

=head2 Level-specific response histograms

Let the numerical endpoints be C<lower> and C<upper>, irrespective of whether
they correspond to best or worst.  With C<divisions = D>, the bin width is:

    width = (upper - lower) / D

For an in-range response value C<x> below the upper endpoint, its internal bin
index is:

    int((x - lower) / width)

A value exactly equal to C<upper> is assigned to bin C<D - 1>.  The centre of
internal bin C<b> is:

    lower + (b + 0.5) * width

For each requested C<variable-level> combination, the module increments the
appropriate bin whenever the selected response is numeric and lies within the
configured interval.

=head2 Percentage response distributions

The raw count histogram for each variable level is normalized independently.
If C<N(v,l)> is the number of in-range numerical responses observed while
variable C<v> is at level C<l>, each percentage bin is:

    100 * bin_count(v,l,b) / N(v,l)

Therefore each non-empty row of C<distributions_percentages_*.csv> sums to
100%.  This makes curves for levels having different numbers of observations
comparable by shape rather than by sample size.

=head1 OUTPUT FILES

For an input file named C<name.csv>, three files are written.

=head2 marginals_name.csv

Contains the empirical marginal distribution of the discrete variables, with
four columns:

    variable,level,count,percentage

Each row gives one level of one variable.  C<count> is the raw number of
observations at that level and C<percentage> is its share of that variable's
observations.

This file is suitable, for example, for bar plots showing how frequently the
different levels of a variable occur.

=head2 distributions_counts_name.csv

Contains the level-specific response histograms as raw counts.

The first column is labelled C<variable-level>.  The remaining columns are the
histogram bin centres.  Each subsequent row, such as C<8-2>, contains the raw
bin counts for the selected response when variable 8 is at level 2.

This file is useful when absolute sample counts matter.

=head2 distributions_percentages_name.csv

Has the same arrangement as C<distributions_counts_name.csv>, but every
variable-level histogram is normalized independently to percentages.

This is normally the most useful file for comparing distribution shapes.  One
can make one graph per variable and superimpose the rows for all levels of that
variable.  For example, a five-level variable can be shown as five lines on the
same plot, all sharing the bin-centre scale from the first row.

For a line plot in a spreadsheet, the bin-centre row can be used as the
horizontal category labels.  For an XY plot, the same bin-centre row can be
used as the numerical X values.

=head1 TERMINAL SUMMARY

After a run, the module prints a concise diagnostic summary including:

=over 4

=item * inferred objective direction;

=item * configured best and worst values;

=item * number of processed rows;

=item * number of numeric responses in the selected CSV column;

=item * numerical interval and bin width;

=item * counts of responses outside the configured interval on the
better-than-best and worse-than-worst sides; and

=item * paths of the three generated files.

=back

The same information is also available programmatically from the hash reference
returned by C<run> or C<run_config>.

=head1 RETURN VALUE

C<run> and C<run_config> return a hash reference containing:

    objective
    best
    worst
    lower
    upper
    divisions
    bin_width
    processed_rows
    numeric_responses
    outside_better
    outside_worse
    marginal_file
    counts_file
    percentages_file

This allows other Sim::OPT code to use the calculation without parsing the
human-readable terminal messages.

=head1 FUNCTIONS

=head2 run_config($path)

Loads the configuration file at C<$path>, resolves relative paths from the
configuration file's directory, performs the complete calculation, writes the
three output files, prints the diagnostic summary, and returns the result hash
reference described above.

This is the recommended entry point when the run specification is stored in a
separate file.

=head2 run($config, $base_directory)

Runs the calculation directly from a configuration hash reference.

C<$base_directory> determines how relative input and output paths are resolved.
If it is omitted or empty, the current directory is used.

=head2 load_config($path)

Loads a configuration file and verifies that it returns a hash reference.  In
list context it returns the configuration hash reference and the directory
containing the configuration file.

Most callers should use C<run_config> instead of calling C<load_config>
directly.

=head1 INPUT FORMAT NOTES

The current reader deliberately follows the simple format used by the existing
Sim::OPT result files.  It separates CSV fields on literal commas and parses
field 0 as underscore-separated C<variable-level> tokens.

Consequently, this version is intended for simple comma-separated files whose
fields do not themselves contain quoted commas.  If full RFC-style CSV quoting
is required in the future, the input layer should be replaced with a dedicated
CSV parser without changing the marginal or histogram calculations.

=head1 ERRORS AND VALIDATION

The module stops with an explanatory error when, among other things:

=over 4

=item * the configuration is not a hash reference;

=item * the input file is missing;

=item * C<levels> is missing or invalid;

=item * C<column> or C<divisions> is invalid;

=item * C<best> and C<worst> are non-numeric or equal;

=item * a requested variable is absent from field 0 of an input row;

=item * an observed variable level exceeds the declared level range; or

=item * the requested output directory does not exist.

=back

These checks are intended to make configuration mistakes visible rather than
silently producing incomplete distributions.

=head1 AUTHOR

Gian Luca Brunetti, E<lt>gianluca.brunetti@polimi.itE<gt>

=head1 ACKNOWLEDGEMENTS

The initial design and implementation of CalcMarginals were
developed by Gian Luca Brunetti with assistance from AI.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2025 by Gian Luca Brunetti, gianluca.brunetti@gmail.com. This software is distributed under a dual licence, open-source (GPL v3) and proprietary. The present copy is GPL. By consequence, this is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.

=cut# 

# FROM THE COMMAND LINE, LAUNCH IT WITH:
# perl -MSim::OPT::CalcMarginals=run_config -e 'run_config(shift)' marginals_config.pl


