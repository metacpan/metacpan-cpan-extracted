package Search::Binary;

use strict;
use warnings;
use Carp;
use parent 'Exporter';
our @EXPORT = qw(binary_search);

our $VERSION = '0.99';

sub binary_search {
    my ($posmin, $posmax, $target, $readfn, $handle, $smallblock) = @_;
    $smallblock ||= 0;
    if ($posmin > $posmax) {
        carp 'First argument must be less then or equal to second argument'
            . " (min: $posmin, max: $posmax)";
        return 0; # some libraries rely on this behavior
    }

    my ($x, $compare, $mid);

    # assert $posmin <= $posmax

    my $lastmid = int($posmin + (($posmax - $posmin) / 2)) - 1;
    while ($posmax - $posmin > $smallblock) {

        # assert: $posmin is the beginning of a record
        # and $target >= index value for that record

        $x = int($posmin + (($posmax - $posmin) / 2));
        ($compare, $mid) = $readfn->($handle, $target, $x);

        unless (defined($compare)) {
            $posmax = $mid;
            next;
        }
        last if ($mid == $lastmid);
        if ($compare > 0) {
            $posmin = $mid;
        } else {
            $posmax = $mid;
        }
        $lastmid = $mid;
    }

    # Switch to sequential search.

    $x = $posmin;
    while ($posmin <= $posmax) {

        # same loop invarient as above applies here

        ($compare, $posmin) = $readfn->($handle, $target, $x);
        last unless (defined($compare) && $compare > 0);
        $x = undef;
    }
    return $posmin;
}

1;
__END__

=head1 NAME

Search::Binary - generic binary search (DEPRECATED)

=head1 SYNOPSIS

  use Search::Binary;
  my $pos = binary_search($min, $max, $val, $read, $handle, [$size]);

=head1 DESCRIPTION

Instead of using C<Search:Binary>, for most cases L<List::BinarySearch> offers
same functionality with simpler, more robust API and thus the latter should be
preferred and B<this module should be considered deprecated>.

C<binary_search> subroutine (which is exported by default) implements a generic
binary search algorithm returning the I<position> of the first I<record> which
I<index value> is greater than or equal to C<$val>. The search routine does not
define any of the terms I<position>, I<record> or I<index value>, but leaves
their interpretation and implementation to the user supplied function
C<&$read()>. The only restriction is that positions must be integer scalars.

During the search the read function will be called with three arguments:
the input parameters C<$handle> and C<$val>, and a position.  If the position
is not C<undef>, the read function should read the first whole record starting
at or after the position; otherwise, the read function should read the record
immediately following the last record it read.  The search algorithm will
guarantee that the first call to the read function will not be with a position
of C<undef>.  The read function needs to return a two element array consisting
of the result of comparing C<$val> with the index value of the read record and
the position of the read record. The comparison value must be positive if
C<$val> is strictly greater than the index value of the read record, C<0>
if equal, and negative if strictly less. Furthermore, the returned position
value must be greater than or equal to the position the read function was
called with.

The input parameters C<$min> and C<$max> are positions and represents the
extent of the search. Only records which begin at positions within this range
(inclusive) will be searched. Moreover, C<$min> must be the starting position
of a record. If present C<$size> is a difference between positions and
determines when the algorithms switches to a sequential search. C<$val> is
an index value. The value of C<$handle> is of no consequence to the binary
search algorithm; it is merely passed as a convenience to the read function.

=head1 USAGE

For simple case of binary search in array of numbers, one can use
C<Search::Binary> with following closure accepting array reference and
returning reader function:

  sub make_numeric_array_reader {
      my ( $array ) = @_;
      my $current_pos = 0;
      return sub {
          my ( $self, $value, $pos ) = @_;
          $pos = $current_pos + 1 unless defined $pos;
          $current_pos = $pos;
          return ( $pos < scalar @{$array}
                   ? $value <=> $array->[$pos]
                   : -1, # see RT #52326
                   $pos );
      };
  }
  # search $value position in non-empty @array of numbers
  binary_search 0, @array - 1, $value, make_numeric_array_reader(\@array);

Using L<List::BinarySearch>, equivaluent of above code would be:

  binsearch_pos { $a <=> $b } $value, @array;

so unless one wants to use more generic algorithm, L<List::BinarySearch>
functions should be preferred. There's also L<List::BinarySearch::XS> which
is faster alternative to pure Perl solutions, if C compiler is available.

=head1 WARNINGS

Prior to version 0.98, C<binary_search> returned array of three elements in
list context, but it was undocumented and in newer versions this behavior was
removed.

=head1 SEE ALSO

=over 4

=item * L<List::BinarySearch>

=item * L<List::BinarySearch::XS>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 1998, Erik Rantapaa

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
