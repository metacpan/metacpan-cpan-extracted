=head1 NAME

PPIx::Regexp::Token::Greediness - Represent a greediness qualifier.

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{foo*+}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::Greediness> is a
L<PPIx::Regexp::Token|PPIx::Regexp::Token>.

C<PPIx::Regexp::Token::Greediness> has no descendants.

=head1 DESCRIPTION

This class represents a greediness qualifier for the preceding
quantifier.

=head1 METHODS

This class provides the following public methods. Methods not documented
here are private, and unsupported in the sense that the author reserves
the right to change or remove them without notice.

=cut

package PPIx::Regexp::Token::Greediness;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

use PPIx::Regexp::Constant qw{ MINIMUM_PERL @CARP_NOT };

our $VERSION = '0.063';

# Return true if the token can be quantified, and false otherwise
sub can_be_quantified { return };

{

    my %explanation = (
	'+'	=> 'match longest string and give nothing back',
	'?'	=> 'match shortest string first',
    );

    sub __explanation {
	return \%explanation;
    }

}

my %greediness = (
    '?' => MINIMUM_PERL,
    '+' => '5.009005',
);

=head2 could_be_greediness

 PPIx::Regexp::Token::Greediness->could_be_greediness( '?' );

This method returns true if the given string could be a greediness
indicator; that is, if it is '+' or '?'.

=cut

sub could_be_greediness {
    my ( undef, $string ) = @_;		# Invocant unused
    return $greediness{$string};
}

sub perl_version_introduced {
    my ( $self ) = @_;
    return $greediness{ $self->content() } || MINIMUM_PERL;
}

sub __PPIX_TOKENIZER__regexp {
    my ( undef, $tokenizer, $character ) = @_;	# Invocant, $char_type unused

    $tokenizer->prior_significant_token( 'is_quantifier' )
	or return;

    $greediness{$character} or return;

    return length $character;
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
