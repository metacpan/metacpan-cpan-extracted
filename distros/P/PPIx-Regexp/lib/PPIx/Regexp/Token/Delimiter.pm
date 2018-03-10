=head1 NAME

PPIx::Regexp::Token::Delimiter - Represent the delimiters of the regular expression

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{foo}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::Delimiter> is a
L<PPIx::Regexp::Token::Structure|PPIx::Regexp::Token::Structure>.

C<PPIx::Regexp::Token::Delimiter> has no descendants.

=head1 DESCRIPTION

This token represents the delimiters of the regular expression. Since
the tokenizer has to figure out where these are anyway, this class is
used to give the lexer a hint about what is going on.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Token::Delimiter;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::Structure };

our $VERSION = '0.056';

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

sub explain {
    return 'Regular expression or replacement string delimiter';
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
