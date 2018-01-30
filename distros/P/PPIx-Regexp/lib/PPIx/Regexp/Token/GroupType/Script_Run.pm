# Cargo cult to try to prevent CPAN from indexing
package
PPIx::Regexp::Token::GroupType::Script_Run;

use 5.006;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::GroupType };

use Carp;

our $VERSION = '0.054';

sub __explanation {
    return {
	'+script_run:'	=> 'All characters must be in same script',
    };
}

sub perl_version_introduced {
    return '5.027008';
}

sub __defining_string {
    return '+script_run:';
}

1;

__END__

=head1 NAME

PPIx::Regexp::Token::GroupType::Script_Run - Represent a script run specifier

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{(+script_run:\d)}' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::GroupType::Script_Run> is a
L<PPIx::Regexp::Token::GroupType|PPIx::Regexp::Token::GroupType>.

C<PPIx::Regexp::Token::GroupType::Script_Run> has no descendants.

=head1 DESCRIPTION

This token represents the specifier for a script run - namely the
C<'+script_run:'> that comes after the left parenthesis. This is new
with Perl 5.27.8.

If this construction does not make it into Perl 5.28, this class will be
retracted.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
