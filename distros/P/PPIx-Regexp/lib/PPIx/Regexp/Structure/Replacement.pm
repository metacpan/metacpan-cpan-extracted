=head1 NAME

PPIx::Regexp::Structure::Replacement - Represent the replacement in s///

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 's{foo}{bar}smxg' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Structure::Replacement> is a
L<PPIx::Regexp::Structure::Main|PPIx::Regexp::Structure::Main>.

C<PPIx::Regexp::Structure::Replacement> has no descendants.

=head1 DESCRIPTION

This class represents the replacement in a substitution operation. In
the example given in the L</SYNOPSIS>, the C<{bar}> will be represented
by this class.

Note that if the substitution is not bracketed (e.g. C<s/foo/bar/g>),
this structure will contain no starting delimiter.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Structure::Replacement;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Structure::Main };

use PPIx::Regexp::Constant qw{ @CARP_NOT };

our $VERSION = '0.063';

sub can_be_quantified { return; }

sub explain {
    return 'Replacement string or expression';
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
