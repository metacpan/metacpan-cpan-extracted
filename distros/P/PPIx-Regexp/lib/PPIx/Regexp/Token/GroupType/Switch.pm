=head1 NAME

PPIx::Regexp::Token::GroupType::Switch - Represent the introducing characters for a switch

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{(?(1)foo|bar)}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::GroupType::Switch> is a
L<PPIx::Regexp::Token::GroupType|PPIx::Regexp::Token::GroupType>.

C<PPIx::Regexp::Token::GroupType::Switch> has no descendants.

=head1 DESCRIPTION

This class represents the characters right after a left parenthesis that
introduce a switch. Strictly speaking these characters are '?(', but
this class only takes the '?'.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Token::GroupType::Switch;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::GroupType };

use PPIx::Regexp::Constant qw{ @CARP_NOT };

our $VERSION = '0.063';

sub __match_setup {
    my ( undef, $tokenizer ) = @_;	# Invocant unused
    $tokenizer->expect( qw{ PPIx::Regexp::Token::Condition } );
    return;
}

__PACKAGE__->__setup_class(
    {
	'?'	=> {
	    expl	=> q<Match one of the following '|'-delimited alternatives>,
	    intro	=> '5.005',
	},
    },
    {
	suffix	=> '(',
    },
);


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
