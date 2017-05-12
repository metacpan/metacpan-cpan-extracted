package Ogre::ColourValue;

use strict;
use warnings;

# xxx: this should be in XS, but I can't get it to work
use overload
  '==' => \&eq_xs,
  '!=' => \&ne_xs,
  ;


1;

__END__
=head1 NAME

Ogre::ColourValue

=head1 SYNOPSIS

  use Ogre;
  use Ogre::ColourValue;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1ColourValue.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 CLASS METHODS

=head2 Ogre::ColourValue->new($red=1, $green=1, $blue=1, $alpha=1)

I<Parameter types>

=over

=item $red=1 : Real

=item $green=1 : Real

=item $blue=1 : Real

=item $alpha=1 : Real

=back

I<Returns>

=over

=item ColourValue *

=back

=head2 Ogre::ColourValue->DESTROY()

This method is called automatically; don't call it yourself.

=head2 \&eq_xs

This is an operator overload method; don't call it yourself.

=head1 INSTANCE METHODS

=head2 $obj->saturate()

I<Returns>

=over

=item void

=back

=head2 $obj->setHSB($hue, $saturation, $brightness)

I<Parameter types>

=over

=item $hue : Real

=item $saturation : Real

=item $brightness : Real

=back

I<Returns>

=over

=item void

=back

=head2 $obj->r()

I<Returns>

=over

=item Real

=back

=head2 $obj->g()

I<Returns>

=over

=item Real

=back

=head2 $obj->b()

I<Returns>

=over

=item Real

=back

=head2 $obj->a()

I<Returns>

=over

=item Real

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
