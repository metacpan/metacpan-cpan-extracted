#
# This file is part of Moo-Lax
#
# This software is Copyright (c) 2014 by Damien Krotkine.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
package Moo::Lax;

#ABSTRACT: Loads Moo without turning warnings to fatal.


our $VERSION = 2;
use Moo 2 ();
use Import::Into;

sub import { Moo->import::into(caller, @_); return }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Moo::Lax - Loads Moo without turning warnings to fatal.

=head1 VERSION

version 2.00

=head1 SYNOPSIS

  # instead of use Moo;
  use Moo::Lax;

=head1 DESCRIPTION

By default Moo turns all warnings to fatal warnings. C<Moo::Lax> is exactly the
same as C<Moo>, except that it doesn't turn all warnings to fatal warnings in
the calling module.

=head1 DEPRECATED

With the release of L<Moo> version 2, C<use Moo> no longer imports
L<strictures> by default and therefore warnings are not fatalised unless
an explicit C<use strictures> is added to the code.

As such, this module is no longer required - simply update your dependency
on Moo to version 2 and switch back to plain C<use Moo> in your classes.

Thus, as per version 2.00, this module simply requires L<Moo> version 2.

=head1 CONTRIBUTORS

=over

=item *

Leon Timmermans

=item *

Olivier MenguÃ©

=back

=head1 AUTHOR

Damien Krotkine <dams@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Damien Krotkine.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
