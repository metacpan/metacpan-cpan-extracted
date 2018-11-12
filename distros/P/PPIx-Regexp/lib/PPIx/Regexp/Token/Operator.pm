=head1 NAME

PPIx::Regexp::Token::Operator - Represent an operator.

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{foo|bar}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::Operator> is a
L<PPIx::Regexp::Token|PPIx::Regexp::Token>.

C<PPIx::Regexp::Token::Operator> has no descendants.

=head1 DESCRIPTION

This class represents an operator. In a character class, it represents
the negation (C<^>) and range (C<->) operators. Outside a character
class, it represents the alternation (C<|>) operator.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Token::Operator;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

use PPIx::Regexp::Constant qw{
    COOKIE_CLASS COOKIE_REGEX_SET
    LITERAL_LEFT_CURLY_ALLOWED
    TOKEN_LITERAL
    @CARP_NOT
};
use PPIx::Regexp::Util qw{ __instance };

our $VERSION = '0.063';

use constant TOKENIZER_ARGUMENT_REQUIRED => 1;

sub __new {
    my ( $class, $content, %arg ) = @_;

    my $self = $class->SUPER::__new( $content, %arg )
	or return;

    $self->{operation} = $self->_compute_operation_name(
	$arg{tokenizer} ) || 'unknown';

    return $self;
}

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

sub explain {
    my ( $self ) = @_;
    my $expl = ucfirst "$self->{operation} operator";
    $expl =~ s/ _ / /smxg;
    return $expl;
}

=head2 operation

This method returns the name of the operation performed by the operator.
This depends not only on the operator itself but its context:

=over

=item In a bracketed character class

    '-' => 'range',
    '^' => 'inversion',

=item In an extended bracketed character class

    '&' => 'intersection',
    '+' => 'union',
    '|' => 'union',
    '-' => 'subtraction',
    '^' => 'symmetric_difference',
    '!' => 'complement',

=item Outside any sort of bracketed character class

    '|' => 'alternation',

=back

=cut

sub operation {
    my ( $self ) = @_;
    return $self->{operation};
}

# These will be intercepted by PPIx::Regexp::Token::Literal if they are
# really literals, so here we may process them unconditionally.

# Note that if we receive a '-' we unconditionally make it an operator,
# relying on the lexer to turn it back into a literal if necessary.

my %operator = map { $_ => 1 } qw{ | - };

sub _treat_as_literal {
    my ( $token ) = @_;
    return __instance( $token, 'PPIx::Regexp::Token::Literal' ) ||
	__instance( $token, 'PPIx::Regexp::Token::Interpolation' );
}

{

    my %operation = (
	COOKIE_CLASS()	=> {
	    '-'	=> 'range',
	    '^'	=> 'inversion',
	},
	COOKIE_REGEX_SET()		=> {
	    '&'	=> 'intersection',
	    '+'	=> 'union',
	    '|'	=> 'union',
	    '-'	=> 'subtraction',
	    '^'	=> 'symmetric_difference',
	    '!'	=> 'complement',
	},
	''	=> {
	    '|'	=> 'alternation',
	},
    );

    sub _compute_operation_name {
	my ( $self, $tokenizer ) = @_;

	my $content = $self->content();

	if ( $tokenizer->cookie( COOKIE_CLASS ) ) {
	    return $operation{ COOKIE_CLASS() }{$content};
	} elsif ( $tokenizer->cookie( COOKIE_REGEX_SET ) ) {
	    return $operation{ COOKIE_REGEX_SET() }{$content};
	} else {
	    return $operation{''}{$content};
	}
    }


}

{
    my $removed_in = {
	'|'	=> LITERAL_LEFT_CURLY_ALLOWED,	# Allowed after alternation
    };

    sub __following_literal_left_curly_disallowed_in {
	my ( $self ) = @_;
	my $content = $self->content();
	exists $removed_in->{$content}
	    and return $removed_in->{$content};
	return $self->SUPER::__following_literal_left_curly_disallowed_in();
    }
}

sub __PPIX_TOKENIZER__regexp {
    my ( undef, $tokenizer, $character ) = @_;

    # We only receive the '-' if we are inside a character class. But it
    # is only an operator if it is preceded and followed by literals. We
    # can use prior() because there are no insignificant tokens inside a
    # character class.
    if ( $character eq '-' ) {

	_treat_as_literal( $tokenizer->prior_significant_token() )
	    or return $tokenizer->make_token( 1, TOKEN_LITERAL );
	
	my @tokens = ( $tokenizer->make_token( 1 ) );
	push @tokens, $tokenizer->get_token();
	
	_treat_as_literal( $tokens[1] )
	    or bless $tokens[0], TOKEN_LITERAL;
	
	return ( @tokens );
    }

    return $operator{$character};
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
