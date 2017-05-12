package Ogre::Degree;

use strict;
use warnings;


# xxx: this should be in XS, but I can't get it to work
use overload
  '==' => \&deg_eq_xs,
  '!=' => \&deg_ne_xs,
  '<' => \&deg_lt_xs,
  '>' => \&deg_gt_xs,
  '<=' => \&deg_le_xs,
  '>=' => \&deg_ge_xs,
  '+' => \&deg_plus_xs,
  '-' => \&deg_minus_xs,
  '*' => \&deg_mult_xs,
  'neg' => \&deg_neg_xs,
  ;


1;

__END__
=head1 NAME

Ogre::Degree

=head1 SYNOPSIS

  use Ogre;
  use Ogre::Degree;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1Degree.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 CLASS METHODS

=head2 Ogre::Degree->new(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item Degree *

=back

=head2 Ogre::Degree->DESTROY()

This method is called automatically; don't call it yourself.

=head2 \&eq_xs

This is an operator overload method; don't call it yourself.

=head1 INSTANCE METHODS

=head2 $obj->valueDegrees()

I<Returns>

=over

=item Real

=back

=head2 $obj->valueRadians()

I<Returns>

=over

=item Real

=back

=head2 $obj->valueAngleUnits()

I<Returns>

=over

=item Real

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
