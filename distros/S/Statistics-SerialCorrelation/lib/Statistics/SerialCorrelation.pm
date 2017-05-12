package Statistics::SerialCorrelation;

use base 'Exporter';
@EXPORT_OK = qw(serialcorrelation);

$VERSION = '1.1';

use strict;
use warnings;

=head1 NAME

Statistics::SerialCorrelation - calculate the serial correlation
co-efficient for an array

=head1 SYNOPSIS

  use Statistics::SerialCorrelation;

  print Statistics::SerialCorrelation::serialcorrelation(1..6);
  
Or if you don't mind polluting your namespace, you may import the
serialcorrelation function like so:

  use Statistics::SerialCorrelation 'serialcorrelation';

=head1 DESCRIPTION

This module does just one thing, it calculates Serial Correlation
Co-efficients, which are a measure of how predictable a series of
values is.  For example, the sequence:

    1 2 3 4 5 6 7 8 9 10

is very predictable, and will have a high serial correlation
co-efficient.  The sequence

    10 1 3 2 6 7 7 9 2

is less predictable and so has a correlation co-efficient nearer 0.

In general, random data has a co-efficient close to zero, highly-ordered
data doesn't.  Note that the co-efficient may be negative.

There is just one function.

=over 4

=item serialcorrelation

This takes either a list of numbers or an array reference.  If given
an array reference, this is first turned into an array.  It then
calculates the correlation co-efficient and returns it.

See your copy of Knuth for the formula.

=back

=cut

sub serialcorrelation {
    my @U = @_;

    @U = @{$U[0]} if(ref($U[0]) =~ /^ARRAY/);
    my $n = $#U + 1;

    my($sum_of_products_of_pairs, $sum_of_squares, $sum) = (
        $U[$n - 1] * $U[0],
        $U[$n - 1] * $U[$n - 1],
        $U[$n - 1]
    );
    foreach(0 .. $n - 2) {
        $sum_of_products_of_pairs += $U[$_] * $U[$_ + 1];
        $sum_of_squares += $U[$_] * $U[$_];
        $sum += $U[$_]
    }

    return undef if($n * $sum_of_squares == $sum * $sum);
    (($n * $sum_of_products_of_pairs) - ($sum * $sum)) /
        (($n * $sum_of_squares) - ($sum * $sum));
}

=head1 BUGS

To avoid divide-by-zero errors, we return undef if the square of the sum of
your values is equal to the number of values multiplied by the sum of the
squares of the values.  undef was chosen because it will never otherwise be
returned and so you can easily detected.

The results are not particularly meaningful for small data sets.

No other bugs are known, but if you find any please let me know, and send a
test case.

=head1 FEEDBACK

I welcome feedback about my code, including constructive criticism.

=head1 AUTHOR

David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

=head1 COPYRIGHT

Copyright 2003 David Cantrell

This module is free-as-in-speech software, and may be used, distributed,
and modified under the same terms as Perl itself.

=cut

1;
