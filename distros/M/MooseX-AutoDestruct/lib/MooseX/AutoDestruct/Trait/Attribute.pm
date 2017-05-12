#
# This file is part of MooseX-AutoDestruct
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package MooseX::AutoDestruct::Trait::Attribute;
{
  $MooseX::AutoDestruct::Trait::Attribute::VERSION = '0.009';
}

# ABSTRACT: Clear your attributes after a certain time

use Moose::Role;
use namespace::autoclean;

# debugging
#use Smart::Comments '###', '####';

use MooseX::AutoDestruct ();

my $trait = MooseX::AutoDestruct->implementation() . '::Trait::Attribute';

with $trait;

!!42;



=pod

=head1 NAME

MooseX::AutoDestruct::Trait::Attribute - Clear your attributes after a certain time

=head1 VERSION

version 0.009

=head1 DESCRIPTION

Attribute trait for L<MooseX::AutoDestruct>.  This trait will compose itself
with an appropriate version-specific role depending on the version of L<Moose>
you're using.

=head1 SEE ALSO

L<MooseX:AutoDestruct>.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut


__END__

