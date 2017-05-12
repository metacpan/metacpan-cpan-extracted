package Set::Similarity::Dice;

use strict;
use warnings;

use parent 'Set::Similarity';

our $VERSION = '0.026';

sub from_sets {
  my ($self, $set1, $set2) = @_;

  # $dice = ($intersection * 2 / $combined_length);
  return (
    $self->intersection($set1,$set2) * 2 / $self->combined_length($set1,$set2)
  );
}

1;

__END__

=head1 NAME

Set::Similarity::Dice - Dice coefficent for sets

=head1 SYNOPSIS

 use Set::Similarity::Dice;
 
 my $dice = Set::Similarity::Dice->new;
 my $similarity = $dice->similarity('Photographer','Fotograf');
 
 
=head1 DESCRIPTION

=head2 Dice coefficient

The Dice coefficient is the number of elements in common to both sets relative to the 
average size of the total number of elements present, i.e.

( A intersect B ) / 0.5 ( A + B ) # the same as sorensen

The weighting factor comes from the 0.5 in the denominator. The range is 0 to 1.

=head1 METHODS

L<Set::Similarity::Dice> inherits all methods from L<Set::Similarity> and implements the
following new ones.

=head2 from_sets

  my $similarity = $object->from_sets(['a'],['b']);
 
This method expects two arrayrefs of strings as parameters. The parameters are not checked, thus can lead to funny results or uncatched divisions by zero.
 
If you want to use this method directly, you should take care that the elements are unique. Also you should catch the situation where one of the arrayrefs is empty (similarity is 0), or both are empty (similarity is 1).

=head1 SOURCE REPOSITORY

L<http://github.com/wollmers/Set-Similarity>

=head1 AUTHOR

Helmut Wollmersdorfer, E<lt>helmut.wollmersdorfer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2014 by Helmut Wollmersdorfer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


