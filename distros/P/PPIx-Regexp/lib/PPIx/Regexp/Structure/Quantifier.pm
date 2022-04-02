=head1 NAME

PPIx::Regexp::Structure::Quantifier - Represent curly bracket quantifiers

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{fo{2,}}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Structure::Quantifier> is a
L<PPIx::Regexp::Structure|PPIx::Regexp::Structure>.

C<PPIx::Regexp::Structure::Quantifier> has no descendants.

=head1 DESCRIPTION

This class represents curly bracket quantifiers such as C<{3}>, C<{3,}>
and C<{3,5}>. The contents are left as literals or interpolations.

B<Note> that if they occur inside a variable-length look-behind,
quantifiers with different low and high limits (such as C<'{1,3}'> imply
a minimum Perl version of C<5.29.9>. Quantifiers specifying more than
255 characters are regarded as parse errors and reblessed into the
unknown structure.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Structure::Quantifier;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Structure };

use PPIx::Regexp::Constant qw{
    LITERAL_LEFT_CURLY_ALLOWED
    MINIMUM_PERL
    MSG_LOOK_BEHIND_TOO_LONG
    STRUCTURE_UNKNOWN
    VARIABLE_LENGTH_LOOK_BEHIND_INTRODUCED
    @CARP_NOT
};

our $VERSION = '0.084';

sub can_be_quantified {
    return;
}

sub explain {
    my ( $self ) = @_;
    my $content = $self->content();
    if ( $content =~ m/ \A [{] ( .*? ) [}] \z /smx ) {
	my $quant = $1;
	my ( $lo, $hi ) = split qr{ , }smx, $quant;
	foreach ( $lo, $hi ) {
	    defined
		or next;
	    s/ \A \s+ //smx;
	    s/ \s+ \z //smx;
	}
	defined $lo
	    and '' ne $lo
	    or $lo = '0';
	defined $hi
	    and '' ne $hi
	    and return "match $lo to $hi times";
	$quant =~ m/ , \z /smx
	    and return "match $lo or more times";
	$lo =~ m/ [^0-9] /smx
	    and return "match $lo times";
	return "match exactly $lo times";
    }
    return $self->SUPER::explain();
}

sub is_quantifier {
    return 1;
}

sub __following_literal_left_curly_disallowed_in {
    return LITERAL_LEFT_CURLY_ALLOWED;
}

sub _too_big {
    my ( $self ) = @_;
    STRUCTURE_UNKNOWN->__PPIX_ELEM__rebless( $self,
	error	=> MSG_LOOK_BEHIND_TOO_LONG,
    );
    return 1;
}

sub __PPIX_LEXER__finalize {
    my ( $self ) = @_;

    my $content = $self->content();

    if ( $self->__in_look_behind() ) {
	if ( $content =~ m/ \A [{] ( .*? ) [}] \z /smx ) {
	    my $quant = $1;

	    $quant =~ m/ , \z /smx
		and return $self->_too_big();

	    my ( $lo, $hi ) = split qr{ , }smx, $quant;

	    defined $hi
		or $hi = $lo;

	    my $numeric = 1;
	    foreach ( $lo, $hi ) {
		if ( m/ \A [0-9]+ \z /smx ) {
		    $_ >= 256
			and return $self->_too_big();
		} else {
		    $numeric = 0;
		}
	    }

	    if ( $numeric && $lo != $hi ) {

		if ( my $finish = $self->finish() ) {
		    $finish->perl_version_introduced() lt
		    VARIABLE_LENGTH_LOOK_BEHIND_INTRODUCED
			and $finish->{perl_version_introduced} =
		    VARIABLE_LENGTH_LOOK_BEHIND_INTRODUCED;
		}

	    }

	    # The problem I am having is that the dumper uses
	    # __structured_requirements_for_perl(), which is not
	    # sensitive to the minimum perl of structures, only
	    # elements. But there is no logical element to hang the
	    # minimum version on. Maybe the opening bracket is less bad
	    # than the other choices?

	}
    }

    ( $content =~ m/ \s /smx or $content =~ m/ \A \{ , /smx )
	and $self->finish()->{perl_version_introduced} = '5.033006';

    return 0;
}

# Called by the lexer to record the capture number.
sub __PPIX_LEXER__record_capture_number {
    my ( undef, $number ) = @_;		# Invocant unused
    return $number;
}

1;

__END__

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=PPIx-Regexp>,
L<https://github.com/trwyant/perl-PPIx-Regexp/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2022 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
