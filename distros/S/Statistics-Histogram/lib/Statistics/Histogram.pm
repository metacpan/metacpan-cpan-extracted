package Statistics::Histogram;
# ABSTRACT: Create a standard histogram for command-line display

use strict;
use warnings;

use Carp;
use Statistics::Descriptive;

use parent qw( Exporter );

our @EXPORT = qw( &get_histogram );
our $VERSION = '0.1';

use constant DEFAULT_BINS => 10;
use constant CHART_WIDTH  => 80;

##############################################################################
# get_histogram( $data, $num_bins, $use_linear_axes )
#
# - $data: Required, arrayref of numbers to chart
# - $num_bins: Optional integer, defaults to 10 bins
# - $use_linear_axes: Optional boolean, defaults to false for logarithmic axes
# - $use_integral_bins: Optional boolean, forces bins to be integers and linear axes
#
# - Returns a multiline string containing user-readable ascii histogram
#

sub get_histogram {
    my ($data, $num_bins, $use_linear_axes, $use_integral_bins) = @_;

    unless ( $use_integral_bins ) {
        $num_bins ||= DEFAULT_BINS;
    }

    croak "Can't create histogram: no data\n" unless @$data;

    my $stats = Statistics::Descriptive::Full->new();
    $stats->add_data(@$data);

    my $return = '';

    # Display some useful statistics at the top of the chart.

    $return .= "Count: " . $stats->count . "\n";
    $return .= sprintf "Range: %6.3f - %6.3f; Mean: %6.3f; Median: %6.3f; Stddev: %6.3f\n",
                $stats->min,
                $stats->max,
                $stats->mean,
                $stats->median,
                $stats->standard_deviation;

    $return .= sprintf "Percentiles:  90th: %6.3f; 95th: %6.3f; 99th: %6.3f\n",
                scalar($stats->percentile(90)),
                scalar($stats->percentile(95)),
                scalar($stats->percentile(99));


    # Calculate the histogram data. If the caller wants logarithmic axes,
    # first calculate the natural log of each value (+1 to work around 
    # zero values.)
    
    my %hist;

    if ( $use_integral_bins ) {
        $use_linear_axes = 1;
        my $min = $stats->min;
        my $max = $stats->max;
        my @bins;
        if ( !defined $num_bins ) {
            @bins = ( $min .. $max );
        }
        else {
            my $step_size = int( ($max-$min+1) / $num_bins );
            for ( my $i=$min; $i<$max; $i += $step_size ) {
                push @bins, $i;
            }
            push @bins, $max;
        }
        %hist = $stats->frequency_distribution(\@bins);
    }
    elsif ( $use_linear_axes ) {
        %hist = $stats->frequency_distribution($num_bins);
    }
    else {
        my $stats_log = Statistics::Descriptive::Full->new();
        $stats_log->add_data(map { log (1+$_) } grep { $_ > 0 } @$data);
        %hist = $stats_log->frequency_distribution($num_bins);
    }

    # Generate the chart
    
    $return .= print_histogram(
        hist  => \%hist, 
        x_min => $stats->min, 
        use_linear_axes => $use_linear_axes, 
        use_integral_bins => $use_integral_bins,
        chart_width => (CHART_WIDTH)[0],
    );

    return $return;
}

##############################################################################
# print_histogram( %args )
#
# - hist: Required hashref of histogram data from frequency_distribution()
# - x_min: Required value of lowest X value in original data, used for label
#           on first bin
# - use_linear_axes: Required boolean to choose linear vs logarithmic axes
# - use_integral_bins: Force bins to be integers and axes to be linear.
# - chart_width: Optional integer for max width of chart in characters, 
#                 defaults to 80.
#

sub print_histogram {
    my %args = (
        use_linear_axes => 0,
        use_integral_bins => 0,
        chart_width => 80,
        @_
    );

    my $hist = $args{hist};

    my @bins = sort { $a <=> $b } keys %$hist;

    my $ymax = 0;
    foreach my $bin (@bins) {
        $ymax = $hist->{$bin} if $ymax < $hist->{$bin};
    }

    if ($ymax == 0) {
        croak "Can't create histogram: no data\n";
    }

    # Max bar width is 27 characters less than chart width, for labels.
    $args{chart_width} = 28 if $args{chart_width} < 28;
    my $y_scale = ($args{chart_width} - 27) / $ymax;

    my $return = '';

    for my $i (0 .. $#bins) {

        my $y = $hist->{$bins[$i]} * $y_scale + 0.5;

        my $bar;
        if ($y < 0.001) {
            $bar = '';
        } elsif ($y < 1) {
            $bar = '|';
        } else {
            $bar = '#' x $y;
        }

        my ($x_low, $x_high);

        if ( $args{use_linear_axes} ) {
            $x_low = ( $i == 0 ? $args{x_min} : $bins[$i-1] );
            $x_high = $bins[$i];
        }
        else {
            # Subtract 1 from each exp() because we added 1 when generating 
            # the logarithmic data
            $x_low = ($i == 0 ? $args{x_min} : (exp $bins[$i-1])-1);
            $x_high = (exp $bins[$i])-1;
        }

        my $num_f = $args{use_integral_bins} ? '%8d' : '%8.3f';
        my $epsilon = $args{use_integral_bins} ? 1.001 : 0.001;

        if ( ( $x_high-$x_low ) < $epsilon ) {
            $return .= sprintf "           $num_f: %5d %s\n",
                        $x_high,
                        $hist->{$bins[$i]},
                        $bar;
        }
        else {
            $return .= sprintf "$num_f - $num_f: %5d %s\n",
                        $x_low,
                        $x_high,
                        $hist->{$bins[$i]},
                        $bar;
        }
    }

    return $return;
}

1;



=pod

=head1 NAME

Statistics::Histogram - Create a standard histogram for command-line display

=head1 VERSION

version 0.2

=head1 SYNOPSIS

  use Statistics::Histogram;

  my @data = <>;
  chomp @data;

  print get_histogram(\@data);

=head1 DESCRIPTION

This module exports a single routine, get_histogram, which expects
an array reference as its only required argument. The array should contain
a sequence of numbers, and the response will be an ascii-formatted
histogram, including some header lines providing statistics.

=head1 METHODS

=head2 get_histogram

  print get_histogram($array_ref);
  print get_histogram($array_ref, $num_bins, $use_linear_axes, $use_integral_bins);

There are three optional arguments: $num_bins, $use_linear_axes, and use_integral_bins.

=over 4

=item num_bins

$num_bins defaults to 10, and controls the maximum number of bins in the chart. Depending on the data, there may be fewer bins if there are fewer than $num_bins unique values.

=item use_linear_axes

$use_linear_axes defaults to false, which will create a chart with logarithmic axes. This is most useful for data derived from software timing metrics, which tend to be non-Normal and biased towards the axes. 

=item use_integral_bins

$use_integral_bins defaults to false. If true it forces use_linear_axes and makes the bins fall on integral values. This is good for plotting time-series data, like the number of events in each hour of the day.

=back

=head1 SEE ALSO

=over 4

=item *

L<Statistics::Descriptive>

=back

=head1 AUTHOR

Douglas Webb <doug.webb@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Douglas Webb.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


