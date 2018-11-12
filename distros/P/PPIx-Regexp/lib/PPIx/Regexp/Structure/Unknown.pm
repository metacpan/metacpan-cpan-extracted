=head1 NAME

PPIx::Regexp::Structure::Unknown - Represent an unknown structure.

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{(?(foo)bar|baz|burfle)}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Structure::Unknown> is a
L<PPIx::Regexp::Structure|PPIx::Regexp::Structure>.

C<PPIx::Regexp::Structure::Unknown> has no descendants.

=head1 DESCRIPTION

This class is used for a structure which the lexer recognizes as being
improperly constructed.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Structure::Unknown;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Structure };

use PPIx::Regexp::Constant qw{ @CARP_NOT };

our $VERSION = '0.063';

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
