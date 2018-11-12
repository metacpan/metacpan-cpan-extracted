=head1 NAME

PPIx::Regexp::Token::Structure - Represent structural elements.

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{(foo)}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::Structure> is a
L<PPIx::Regexp::Token|PPIx::Regexp::Token>.

C<PPIx::Regexp::Token::Structure> is the parent of
L<PPIx::Regexp::Token::Delimiter|PPIx::Regexp::Token::Delimiter>.

=head1 DESCRIPTION

This class represents things that define the structure of the regular
expression. This typically means brackets of various sorts, but to
prevent proliferation of token classes the type of the regular
expression is stored here.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Token::Structure;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

use PPIx::Regexp::Constant qw{
    COOKIE_CLASS
    COOKIE_QUANT
    COOKIE_REGEX_SET
    MINIMUM_PERL
    TOKEN_LITERAL
    @CARP_NOT
};

# Tokens we are responsible for making, under at least some
# circumstances.
use PPIx::Regexp::Token::Comment	();
use PPIx::Regexp::Token::Modifier	();
use PPIx::Regexp::Token::Backreference	();
use PPIx::Regexp::Token::Backtrack	();
use PPIx::Regexp::Token::Recursion	();

our $VERSION = '0.063';

# Return true if the token can be quantified, and false otherwise

my %quant = map { $_ => 1 } ')', ']';
sub can_be_quantified {
    my ( $self ) = @_;
    ref $self or return;
    return $quant{ $self->content() };
};

{

    my %explanation = (
	''		=> 'Match regexp',
	'('		=> 'Capture or grouping',
	'(?['	=> 'Extended character class',
	')'		=> 'End capture or grouping',
	'['		=> 'Character class',
	']'		=> 'End character class',
	'])'	=> 'End extended character class',
	'm'		=> 'Match regexp',
	'qr'	=> 'Regexp object definition',
	's'	=> 'Replace regexp with string or expression',
	'{'		=> 'Explicit quantifier',
	'}'		=> 'End explicit quantifier',
    );

    sub __explanation {
	return \%explanation;
    }

}

sub is_quantifier {
    my ( $self ) = @_;
    ref $self or return;
    return $self->{is_quantifier};
}

{

    # Note that the implementation equivocates on the ::Token::Structure
    # class, using it both for the initial token that determines the
    # type of the regex and things like parentheses internal to the
    # regex. Rather than sort out this equivocation, I have relied on
    # the currently-true assumption that 'qr' will not satisfy the
    # ::Token::Structure recognition logic, and the only way this class
    # can acquire this content is by the brute-force approach used to
    # generate the initial token object.

    my %perl_version_introduced = (
	qr	=> '5.005',
	'(?['	=> '5.017008',
    );

    sub perl_version_introduced {
	my ( $self ) = @_;
	return $perl_version_introduced{ $self->content() } || MINIMUM_PERL;
    }
}

{

    my %delim = map { $_ => 1 } qw/ ( ) { } [ ] /;

    # Regular expressions to match various parenthesized tokens, and the
    # classes to make them into.

    my @paren_token = map {
	[ $_ => $_->__PPIX_TOKEN__recognize() ]
    }
	'PPIx::Regexp::Token::Comment',
	'PPIx::Regexp::Token::Modifier',
	'PPIx::Regexp::Token::Backreference',
	'PPIx::Regexp::Token::Backtrack',
	'PPIx::Regexp::Token::Recursion',
    ;

    sub __PPIX_TOKENIZER__regexp {
	my ( undef, $tokenizer, $character ) = @_;

	# We are not interested in anything but delimiters.
	$delim{$character} or return;

	# Inside a character class, all the delimiters are normal characters
	# except for the close square bracket.
	if ( $tokenizer->cookie( COOKIE_CLASS ) ) {
	    $character eq ']'
		or return $tokenizer->make_token( 1, TOKEN_LITERAL );
	    $tokenizer->cookie( COOKIE_CLASS, undef );
	    return 1;
	}

	# Open parentheses have various interesting possibilities ...
	if ( $character eq '(' ) {

	    # Sometimes the whole bunch of parenthesized characters seems
	    # naturally to be a token.
	    foreach ( @paren_token ) {
		my ( $class, @recognize ) = @{ $_ };
		foreach ( @recognize ) {
		    my ( $regexp, $arg ) = @{ $_ };
		    my $accept = $tokenizer->find_regexp( $regexp ) or next;
		    return $tokenizer->make_token( $accept, $class, $arg );
		}
	    }

	    # Modifier changes are local to this parenthesis group
	    $tokenizer->modifier_duplicate();

	    # The regex-set functionality introduced with 5.17.8 is most
	    # conveniently handled by treating the initial '(?[' and
	    # final '])' as ::Structure tokens. Fortunately for us,
	    # perl5178delta documents that these may not have interior
	    # spaces.

	    if ( my $accept = $tokenizer->find_regexp(
		    qr{ \A [(] [?] [[] }smx	# ] ) - help for vim
		)
	    ) {
		$tokenizer->cookie( COOKIE_REGEX_SET, sub { return 1 } );
		$tokenizer->modifier_modify( x => 1 );	# Implicitly /x
		return $accept;
	    }

	    # We expect certain tokens only after a left paren.
	    $tokenizer->expect(
		'PPIx::Regexp::Token::GroupType::Modifier',
		'PPIx::Regexp::Token::GroupType::NamedCapture',
		'PPIx::Regexp::Token::GroupType::Assertion',
		'PPIx::Regexp::Token::GroupType::Code',
		'PPIx::Regexp::Token::GroupType::BranchReset',
		'PPIx::Regexp::Token::GroupType::Subexpression',
		'PPIx::Regexp::Token::GroupType::Switch',
		'PPIx::Regexp::Token::GroupType::Script_Run',
		'PPIx::Regexp::Token::GroupType::Atomic_Script_Run',
	    );

	    # Accept the parenthesis.
	    return 1;
	}

	# Close parentheses end modifier localization
	if ( $character eq ')' ) {
	    $tokenizer->modifier_pop();
	    return 1;
	}

	# Open curlys are complicated because they may or may not represent
	# the beginning of a quantifier, depending on what comes before the
	# close curly. So we set a cookie to monitor the token stream for
	# interlopers. If all goes well, the right curly will find the
	# cookie and know it is supposed to be a quantifier.
	if ( $character eq '{' ) {

	    # If the prior token can not be quantified, all this is
	    # unnecessary.
	    $tokenizer->prior_significant_token( 'can_be_quantified' )
		or return 1;

	    # We make our token now, before setting the cookie. Otherwise
	    # the cookie has to deal with this token.
	    my $token = $tokenizer->make_token( 1 );

	    # A cookie for the next '}'.
	    my $commas = 0;
	    $tokenizer->cookie( COOKIE_QUANT, sub {
		    my ( $tokenizer, $token ) = @_;
		    $token or return 1;

		    # Of literals, we accept exactly one comma provided it
		    # is not immediately after a '{'. We also accept
		    # anything that matches '[0-9]';
		    if ( $token->isa( TOKEN_LITERAL ) ) {
			my $character = $token->content();
			if ( $character eq ',' ) {
			    $commas++ and return;
			    return $tokenizer->prior_significant_token(
				'content' ) ne '{';
			}
			return $character =~ m/ \A [0-9] \z /smx;
		    }

		    # Since we do not know what is in an interpolation, we
		    # trustingly accept it.
		    if ( $token->isa( 'PPIx::Regexp::Token::Interpolation' )
		    ) {
			return 1;
		    }

		    return;
		},
	    );

	    return $token;
	}

	# The close curly bracket is a little complicated because if the
	# cookie posted by the left curly bracket is still around, we are a
	# quantifier, otherwise not.
	if ( $character eq '}' ) {
	    $tokenizer->cookie( COOKIE_QUANT, undef )
		or return 1;
	    $tokenizer->prior_significant_token( 'class' )->isa( __PACKAGE__ )
		and return 1;
	    my $token = $tokenizer->make_token( 1 );
	    $token->{is_quantifier} = 1;
	    return $token;
	}

	# The parse rules are different inside a character class, so we set
	# another cookie. Sigh. If your tool is a hammer ...
	if ( $character eq '[' ) {

	    # Set our cookie. Since it always returns 1, it does not matter
	    # where in the following mess we set it.
	    $tokenizer->cookie( COOKIE_CLASS, sub { return 1 } );

	    # Make our token now, since the easiest place to deal with the
	    # beginning-of-character-class strangeness seems to be right
	    # here.
	    my @tokens = $tokenizer->make_token( 1 );

	    # Get the next character, returning tokens if there is none.
	    defined ( $character = $tokenizer->peek() )
		or return @tokens;

	    # If we have a caret, it is a negation operator. Make its token
	    # and fetch the next character, returning if none.
	    if ( $character eq '^' ) {
		push @tokens, $tokenizer->make_token(
		    1, 'PPIx::Regexp::Token::Operator' );
		defined ( $character = $tokenizer->peek() )
		    or return @tokens;
	    }

	    # If we have a close square at this point, it is not the end of
	    # the class, but just a literal. Make its token.
	    $character eq ']'
		and push @tokens, $tokenizer->make_token( 1, TOKEN_LITERAL );

	    # Return all tokens made.
	    return @tokens;
	}
	# per perlop, the metas inside a [] are -]\^$.
	# per perlop, the metas outside a [] are {}[]()^$.|*+?\
	# The difference is that {}[().|*+? are not metas in [], but - is.

	# Close bracket is complicated by the addition of regex sets.
	# And more complicated by the fact that you can have an
	# old-style character class inside a regex set. Fortunately they
	# have not (yet!) permitted nested regex sets.
	if ( $character eq ']' ) {

	    # If we find '])' and COOKIE_REGEX_SET is present, we have a
	    # regex set. We need to delete the cookie and accept both
	    # characters.
	    if ( ( my $accept = $tokenizer->find_regexp(
		    # help vim - ( [
		    qr{ \A []] [)] }smx
		) )
		&& $tokenizer->cookie( COOKIE_REGEX_SET )

	    ) {
		$tokenizer->cookie( COOKIE_REGEX_SET, undef );
		return $accept;
	    }

	    # Otherwise we assume we're in a bracketed character class,
	    # delete the cookie, and accept the close bracket.
	    $tokenizer->cookie( COOKIE_CLASS, undef );
	    return 1;
	}

	return 1;
    }

}

# Called by the lexer once it has done its worst to all the tokens.
# Called as a method with no arguments. The return is the number of
# parse failures discovered when finalizing.
sub __PPIX_LEXER__finalize {
    my ( $self ) = @_;
    delete $self->{is_quantifier};
    return 0;
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
