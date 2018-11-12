=head1 NAME

PPIx::Regexp::Token::Backreference - Represent a back reference

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{(foo|bar)baz\1}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::Backreference> is a
L<PPIx::Regexp::Token::Reference|PPIx::Regexp::Token::Reference>.

C<PPIx::Regexp::Token::Backreference> has no descendants.

=head1 DESCRIPTION

This class represents back references of all sorts, both the traditional
numbered variety and the Perl 5.010 named kind.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Token::Backreference;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::Reference };

use Carp qw{ confess };
use PPIx::Regexp::Constant qw{
    MINIMUM_PERL
    RE_CAPTURE_NAME
    TOKEN_LITERAL
    TOKEN_UNKNOWN
    @CARP_NOT
};
use PPIx::Regexp::Util qw{ __to_ordinal_en };

our $VERSION = '0.063';

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

sub explain {
    my ( $self ) = @_;
    $self->is_named()
	and return sprintf q<Back reference to capture group '%s'>,
	    $self->name();
    $self->is_relative()
	and return sprintf
	    q<Back reference to %s previous capture group (%d in this regexp)>,
	    __to_ordinal_en( - $self->number() ),
	    $self->absolute();
    return sprintf q<Back reference to capture group %d>,
	$self->absolute();
}

{

    my %perl_version_introduced = (
	g => '5.009005',	# \g1 \g-1 \g{1} \g{-1}
	k => '5.009005',	# \k<name> \k'name'
	'?' => '5.009005',	# (?P=name)	(PCRE/Python)
    );

    sub perl_version_introduced {
	my ( $self ) = @_;
	return $perl_version_introduced{substr( $self->content(), 1, 1 )} ||
	    MINIMUM_PERL;
    }

}

my @external = (	# Recognition used externally
    [ qr{ \A \( \? P = ( @{[ RE_CAPTURE_NAME ]} ) \) }smxo,
	{ is_named => 1 },
	],
);

my @recognize_regexp = (	# recognition used internally
    [
	qr{ \A \\ (?:		# numbered (including relative)
	    ( [0-9]+ )	|
	    g (?: ( -? [0-9]+ ) | \{ ( -? [0-9]+ ) \} )
	)
	}smx, { is_named => 0 }, ],
    [
	qr{ \A \\ (?:		# named
	    g [{] ( @{[ RE_CAPTURE_NAME ]} ) [}] |
	    k (?: \< ( @{[ RE_CAPTURE_NAME ]} ) \> |	# named with angles
		' ( @{[ RE_CAPTURE_NAME ]} ) ' )	#   or quotes
	)
	}smxo, { is_named => 1 }, ],
);

my %recognize = (
    regexp	=> \@recognize_regexp,
    repl	=> [
	[ qr{ \A \\ ( [0-9]+ ) }smx, { is_named => 0 } ],
    ],
);

# This must be implemented by tokens which do not recognize themselves.
# The return is a list of list references. Each list reference must
# contain a regular expression that recognizes the token, and optionally
# a reference to a hash to pass to make_token as the class-specific
# arguments. The regular expression MUST be anchored to the beginning of
# the string.
sub __PPIX_TOKEN__recognize {
    return __PACKAGE__->isa( scalar caller ) ?
	( @external, @recognize_regexp ) :
	( @external );
}

sub __PPIX_TOKENIZER__regexp {
    my ( undef, $tokenizer, $character ) = @_;

    # PCRE/Python back references are handled in
    # PPIx::Regexp::Token::Structure, because they are parenthesized.

    # All the other styles are escaped.
    $character eq '\\'
	or return;

    foreach ( @{ $recognize{$tokenizer->get_mode()} } ) {
	my ( $re, $arg ) = @{ $_ };
	my $accept = $tokenizer->find_regexp( $re ) or next;
	my %arg = ( %{ $arg }, tokenizer => $tokenizer );
	return $tokenizer->make_token( $accept, __PACKAGE__, \%arg );
    }

    return;
}

sub __PPIX_TOKENIZER__repl {
    my ( undef, $tokenizer ) = @_;	# Invocant, $character unused

    $tokenizer->interpolates()
	or return;

    goto &__PPIX_TOKENIZER__regexp;
}

# Called by the lexer to disambiguate between captures, literals, and
# whatever. We have to return the number of tokens reblessed to
# TOKEN_UNKNOWN (i.e. either 0 or 1) because we get called after the
# parse is finalized.
sub __PPIX_LEXER__rebless {
    my ( $self, %arg ) = @_;

    # Handle named back references
    if ( $self->is_named() ) {
	$arg{capture_name}{$self->name()}
	    and return 0;
	return $self->__error();
    }

    # Get the absolute capture group number.
    my $absolute = $self->absolute();

    # If it is zero or negative, we have a relateive reference to a
    # non-existent capture group.
    $absolute <= 0
	and return $self->__error();

    # If the absolute number is less than or equal to the maximum
    # capture group number, we are good.
    $absolute <= $arg{max_capture}
	and return 0;

    # It's not a valid capture. If it's an octal literal, rebless it so.
    # Note that we can't rebless single-digit numbers, since they can't
    # be octal literals.
    my $content = $self->content();
    if ( $content =~ m/ \A \\ [0-7]{2,} \z /smx ) {
	bless $self, TOKEN_LITERAL;
	return 0;
    }

    # Anything else is an error.
    return $self->__error();
}

sub __error {
    my ( $self, $msg ) = @_;
    defined $msg
	or $msg = 'No corresponding capture group';
    $self->{error} = $msg;
    bless $self, TOKEN_UNKNOWN;
    return 1;
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
