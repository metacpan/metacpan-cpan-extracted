package Statistics::Benford;

use strict;
use warnings;
use List::Util qw(sum);

our $VERSION = '0.08';
$VERSION = eval $VERSION;

use constant _BASE => 0;
use constant _N    => 1;
use constant _LEN  => 2;
use constant _DIST => 3;

sub new {
    my ($class, $base, $n, $len) = @_;

    $base ||= 10;
    $n = 0 unless defined $n;
    $len ||= 1;

    my ($k_start, $k_end, $d_start);
    if (0 == $n) {
        ($k_start, $k_end) = (0, 0);
        $d_start = $base ** ($len - 1);
    }
    else {
        ($k_start, $k_end) = ($base ** ($n - 1), $base ** $n - 1);
        $d_start = (1 == $len) ? 0 : $base ** ($len - 1);
    }
    my $d_end = $base ** $len - 1;

    my %dist;
    for my $digit ($d_start .. $d_end) {
        my $sum = 0;
        for my $k ($k_start .. $k_end) {
            $sum += log(1 + 1 / ($k * $base + $digit));
        }
        $dist{$digit} = (1 / log($base)) * $sum;
    }

    return bless [$base, $n, $len, \%dist], $class;
}

sub distribution {
    return %{ $_[0]->[_DIST] };
}

*dist = \&distribution;

sub difference {
    my ($self, %freq) = @_;
    my ($diff, %diff) = 0;

    my $count = sum values %freq;
    return 0 unless $count;

    while (my ($num, $percent) = each %{ $self->[_DIST] }) {
        my $delta = ($freq{$num} ? $freq{$num} / $count : 0) - $percent;
        $diff += abs($diff{$num} = $delta);
    }

    return wantarray ? %diff : $diff;
}

*diff = \&difference;

sub signif {
    my ($self, %freq) = @_;
    my ($diff, %diff) = 0;

    my $count = sum values %freq;
    return 0 unless $count;

    while (my ($num, $percent) = each %{ $self->[_DIST] }) {
        my $delta = ($freq{$num} ? $freq{$num} / $count : 0) - $percent;
        my $fix = abs $delta > (1 / (2 * $count)) ? (1 / (2 * $count)) : 0;
        my $z = (abs($delta) - $fix) /
                sqrt($percent * (1 - $percent) / $count);
        $diff += $diff{ $num } = $z ;
    }

    return wantarray ? %diff : $diff / keys %{ $self->[_DIST] };
}

*z = \&signif;

1;

__END__

=head1 NAME

Statistics::Benford - calculate the deviation from Benford's Law

=head1 SYNOPSIS

    my $stats = Statistics::Benford->new;
    my $diff = $stats->diff(%freq);
    my %diff = $stats->diff(%freq);
    my $signif = $stats->signif(%freq);
    my %signif = $stats->signif(%freq);

=head1 DESCRIPTION

The C<Statistics::Benford> module calculates the deviation from Benford's law,
also known as the first-digit law. The law states that for many sources of
real-life data, the leading digit follows a logarithmic, not uniform,
distribution. This fact can be used to audit data for signs of fraud by
comparing the expected frequency of the digits to the actual frequency in the
data.

=head1 METHODS

=over

=item $stats = Statistics::Benford->B<new>

=item $stats = Statistics::Benford->B<new>($base, $pos, $len)

Creates a new Statistics::Benford object. The constructor will accept the
number base, the position of the significant digit in the number to examine,
and the number of digits starting from that position.

The default values are: (10, 0, 1).

=item %dist = $stats->B<dist>($bool)

=item %dist = $stats->B<distribution>($bool)

Returns a hash of the expected percentages.

=item $diff = $stats->B<diff>(%freq)

=item $diff = $stats->B<difference>(%freq)

=item %diff = $stats->B<diff>(%freq);

=item %diff = $stats->B<difference>(%freq)

Given a hash representing the frequency count of the digits in the data to
examine, returns the percentage differences of each digit in list context, and
the sum of the differences in scalar context.

=item $diff = $stats->B<signif>(%freq)

=item $diff = $stats->B<z>(%freq)

=item %diff = $stats->B<signif>(%freq);

=item %diff = $stats->B<z>(%freq)

Given a hash representing the frequency count of the digits in the data to
examine, returns the z-statistic of each digit in list context, and the
average of the z-statistics for all the digits in scalar context.

The z-statistic shows the statistical significance of the difference between
the two proportions. Significance takes into account the size of the
difference, the expected proportion, and the sample size.  Scores above 1.96
are significant at the 0.05 level, and above 2.57 are significant at the 0.01
level.

=back

=head1 EXAMPLE

    # Generate a list of numbers approximating a Benford distribution.
    my $max = 10;  # numbers range from 0 to 10
    my @nums = map { ($max / rand($max)) - 1 } (1 .. 1_000);
    my %freq;
    for my $num (@nums) {
        my ($digit) = $num =~ /([1-9])/;  # find first non-zero digit
        $freq{$digit}++;
    }
    my $stats = Statistics::Benford->new(10, 0, 1);
    my $diff = $stats->diff(%freq);
    my $signif = $stats->signif(%freq);

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Benford's_law>

L<http://www.mathpages.com/home/kmath302/kmath302.htm>

=head1 NOTES

When counting the first digit, make sure it is non-zero. For example the
first non-zero digit of 0.038 is 3.

Convert non-decimal base digits to decimal representations. For example,
to examine the first two digits of a hexadecimal number, like A1B2, take the
first two digits 'A1', and convert them to decimal- 161.

The law becomes less accurate when the data set is small.

The law does not apply to data sets which have imposed limitations (e.g.
max or min values) or where the numbers are assigned (e.g. ids and phone
numbers).

The distribution becomes uniform at the 5th significant digit, i.e. all
digits will have the same expected frequency.

It can help to partition the data into subsets for testing, e.g. testing
negative and positive values separately.

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report?Queue=Statistics-Benford>. I will
be notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Benford

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/statistics-benford>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-Benford>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-Benford>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Statistics-Benford>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-Benford>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
