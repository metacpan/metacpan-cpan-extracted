=head1 NAME

PPIx::Regexp::Structure::Modifier - Represent modifying parentheses

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{(?i:foo)}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Structure::Modifier> is a
L<PPIx::Regexp::Structure|PPIx::Regexp::Structure>.

C<PPIx::Regexp::Structure::Modifier> has no descendants.

=head1 DESCRIPTION

This class represents parentheses that apply modifiers to their contents
-- even if there are no modifiers. The latter is to say that C<(?:foo)>
also ends up as this class.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Structure::Modifier;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Structure };

use PPIx::Regexp::Constant qw{ @CARP_NOT };

our $VERSION = '0.063';

# This is a kluge for both determining whether the object asserts
# modifiers (hence the 'ductype') and determining whether the given
# modifier is actually asserted. The signature is the invocant and the
# modifier name, which must not be undef. The return is a boolean.
sub __ducktype_modifier_asserted {
    my ( $self, $modifier ) = @_;
    foreach my $type ( reverse $self->type() ) {
	$type->can( '__ducktype_modifier_asserted' )
	    or next;
	defined( my $val = $type->__ducktype_modifier_asserted( $modifier ) )
	    or next;
	return $val;
    }
    return;
}

1;

__END__

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
