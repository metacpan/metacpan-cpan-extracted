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

use PPIx::Regexp::Constant qw{ MINIMUM_PERL @CARP_NOT };

our $VERSION = '0.063';

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

sub explain {
    return 'Regular expression or replacement string delimiter';
}

=head2 perl_version_introduced

Experimentation with weird delimiters shows that they did not actually
work until Perl 5.8.3, so we return C<'5.008003'> for such delimiters.

=cut

sub perl_version_introduced {
    my ( $self ) = @_;
    $self->content() =~ m/ \A [[:^ascii:]] \z /smx
	and return '5.008003';
    return MINIMUM_PERL;
}

=head2 perl_version_removed

Perl 5.29.0 made fatal the use of non-standalone graphemes as regular
expression delimiters. Because non-characters and permanently unassigned
code points are still allowed per F<perldeprecation>, I take this to
mean characters that match C</\p{Mark}/> (i.e. combining diacritical
marks).  But this regular expression does not compile under Perl 5.6.

So:

This method returns C<'5.029'> for such delimiters B<provided> the
requisite regular expression compiles. Otherwise it return C<undef>.

=cut

# Perl 5.29.0 disallows unassigned code points and combining code points
# as delimiters. Unfortunately for me non-characters and illegal
# characters are explicitly allowed. Still more unfortunately, these
# match /\p{Unassigned}/. So before I match a deprecated characer, I
# have to assert that the character is neither a non-character
# (\p{Noncharacter_code_point}) nor an illegal Unicode character
# (\P{Any}).
use constant WEIRD_CHAR_RE => eval ## no critic (ProhibitStringyEval,RequireCheckingReturnValueOfEval)
'qr<
    (?! [\p{Noncharacter_code_point}\P{Any}] )
    [\p{Unassigned}\p{Mark}]
>smx';

sub perl_version_removed {
    my ( $self ) = @_;
    WEIRD_CHAR_RE
	and $self->content() =~ WEIRD_CHAR_RE
	and return '5.029';
    # I respectfully disagree with Perl Best Practices on the
    # following. When this method is called in list context it MUST
    # return undef if that's the right answer, NOT an empty list.
    # Otherwise hash constructors have the wrong number of elements.
    return undef;	## no critic (ProhibitExplicitReturnUndef)
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
