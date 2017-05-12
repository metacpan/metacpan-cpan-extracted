package Set::Similarity::BV::Jaccard;

use strict;
use warnings;

use parent 'Set::Similarity::BV';

our $VERSION = '0.06';

sub from_integers {
  my ($self, $v1, $v2) = @_;

  my $intersection = $self->intersection($v1,$v2);
  my $union = $self->combined_length($v1,$v2) - $intersection;
  # ( A intersect B ) / (A union B)
  return ($intersection / $union);
}

1;

__END__

=head1 NAME

Set::Similarity::BV::Jaccard - Jaccard coefficent for sets

=head1 SYNOPSIS

 use Set::Similarity::BV::Jaccard;

 my $jaccard = Set::Similarity::BV::Jaccard->new;
 my $similarity = $jaccard->similarity('af09ff','9c09cc');


=head1 DESCRIPTION

=head2 Jaccard Index

The Jaccard coefficient measures similarity between sample sets, and is defined as the
size of the intersection divided by the size of the union of the sample sets

( A intersect B ) / (A union B)

The Tanimoto coefficient is the ratio of the number of elements common to both sets to
the total number of elements, i.e.

( A intersect B ) / ( A + B - ( A intersect B ) ) # the same as Jaccard

The range is 0 to 1 inclusive.

=head1 METHODS

L<Set::Similarity::BV::Jaccard> inherits all methods from L<Set::Similarity::BV> and implements the
following new ones.

=head2 from_integers

  my $similarity = $object->from_integers($AoI1,$AoI2);

This method expects two array references of integers as parameters. The parameters are not checked, thus can lead to funny results or uncatched divisions by zero.

If you want to use this method directly, you should catch the situation where one of the parameters is empty (similarity is 0), or both are empty (similarity is 1).

=head1 SOURCE REPOSITORY

L<http://github.com/wollmers/Set-Similarity-BV>

=head1 AUTHOR

Helmut Wollmersdorfer, E<lt>helmut.wollmersdorfer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Helmut Wollmersdorfer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

