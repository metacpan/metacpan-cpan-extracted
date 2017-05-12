package Sort::Radix;

use 5.008005;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(radix_sort);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Sort::Radix ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our @EXPORT_OK = qw(_internalfunctions);

our %EXPORT_TAGS = (  all  => \@EXPORT,
                      test => \@EXPORT_OK,);

#our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );



our $VERSION = '0.04';




# Preloaded methods go here.

sub radix_sort {
    my $array = shift;

    my $from = $array;
    my $to;

    # All lengths expected equal.
    for ( my $i = length ($array->[ 0 ]) - 1; $i >= 0; $i-- ) {
        # A new sorting bin.
        $to = [ ];
        foreach my $card ( @$from ) {
            # Stability is essential, so we use push().
            push @{ $to->[ ord( substr $card, $i ) ] }, $card;
        }

        # Concatenate the bins.

        $from = [ map { @{ $_ || [ ] } } @$to ];
    }

    # Now copy the elements back into the original array.

    @$array = @$from;
}

1;
__END__


#///////////////////////////////////////////////////////////////////////#
#                                                                       #
#///////////////////////////////////////////////////////////////////////#

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Sort::Radix - A multiple passes distribution sort algorithm

=head1 SYNOPSIS

  use Sort::Radix;
  
  @array = qw(flow loop pool Wolf root sort tour);
  radix_sort(\@array);
  print "@array\n";

=head1 DESCRIPTION

This is an implementation based on Jarkko's Wolf book (Mastering Algorithms with Perl, pp. 145-147).

By definition: radix sort is a multiple pass distribution sort algorithm that distributes each item to a bucket according to part of the item's key beginning with the least significant part of the key. After each pass, items are collected from the buckets, keeping the items in order, then redistribute according to the next most significant part of the key. 

Radix sort is nice as it take N * M passes, where N is the length of the keys. It is very useful for sorting large volumes of keys of the same length, such as postal codes.

The algorithm will only works when the strings to be sorted are of the same length. Variable length strings therefore have to be padded with zeroes (\x00) to equalize the length.

=head1 BUGS

Unknown so far. But please kindly inform if you find one ;-)

=head1 HISTORY

=item v 0.04, Friday, January 21, 2005

Fixed warning caused by operator precedence and undefined error caused by misplacing the routines after __END__ marker.

=head1 SEE ALSO

L<Sort::Merge>, L<Sort::Fields>

=head1 IMPLEMENTOR

Edward Wijaya, E<lt>ewijaya@singnet.com.sgE<gt>

=head1 AUTHOR

Jarkko Hietaniemi, E<lt>jhi@iki.fiE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Edward Wijaya

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
