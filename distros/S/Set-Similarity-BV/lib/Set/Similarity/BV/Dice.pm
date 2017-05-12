package Set::Similarity::BV::Dice;

use strict;
use warnings;

use parent 'Set::Similarity::BV';

our $VERSION = '0.06';

sub from_integers {
  my ($self, $v1, $v2) = @_;

  # $dice = ($intersection * 2 / $combined_length);
  return (
    $self->intersection($v1,$v2) * 2 / $self->combined_length($v1,$v2)
  );
}

1;

__END__

=head1 NAME

Set::Similarity::BV::Dice - Dice coefficent for sets

=head1 SYNOPSIS

 use Set::Similarity::BV::Dice;

 my $dice = Set::Similarity::BV::Dice->new;
 my $similarity = $dice->similarity('af09ff','9c09cc');


=head1 DESCRIPTION

=head2 Dice coefficient

The Dice coefficient is the number of elements in common to both sets relative to the
average size of the total number of elements present, i.e.

( A intersect B ) / 0.5 ( A + B ) # the same as sorensen

The weighting factor comes from the 0.5 in the denominator. The range is 0 to 1.

=head1 METHODS

L<Set::Similarity::BV::Dice> inherits all methods from L<Set::Similarity::BV> and implements the
following new ones.

=head2 from_integers

  my $similarity = $object->from_integers($AoI1,$AoI2);

This method expects two array references of integers as parameters. The parameters are not checked, thus can lead to funny results or uncatched divisions by zero.

If you want to use this method directly, you should catch the situation where one of the parameters is empty (similarity is 0), or both are empty (similarity is 1).

=head1 SOURCE REPOSITORY

L<http://github.com/wollmers/Set-Similarity-BV-BV>

=head1 AUTHOR

Helmut Wollmersdorfer, E<lt>helmut.wollmersdorfer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Helmut Wollmersdorfer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


