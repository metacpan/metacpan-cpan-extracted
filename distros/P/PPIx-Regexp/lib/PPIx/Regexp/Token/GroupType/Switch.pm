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

our $VERSION = '0.055';

{

    my %explanation = (
	'?'	=> q<Match one of the following '|'-delimited alternatives>,
    );

    sub __explanation {
	return \%explanation;
    }
}

sub perl_version_introduced {
#   my ( $self ) = @_;
    return '5.005';
}

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

=begin comment

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    # The optional escape is because any non-open-bracket character may
    # appear as the regular expression delimiter.
    if ( my $accept = $tokenizer->find_regexp(
	    qr{ \A \\? \? \( }smx ) ) {

	# Leave the left paren, since it belongs to the condition.
	--$accept;

	$tokenizer->expect( qw{
	    PPIx::Regexp::Token::Condition
	    } );

	return $accept;

    }

    return;

}

=end comment

=cut

sub __defining_string {
    return (
	{ suffix => '(' },
	'?',
    );
}

sub __match_setup {
    my ( undef, $tokenizer ) = @_;	# Invocant unused
    $tokenizer->expect( qw{ PPIx::Regexp::Token::Condition } );
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
