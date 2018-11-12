=head1 NAME

PPIx::Regexp::Token::CharClass::POSIX - Represent a POSIX character class

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{ [[:alpha:]] }smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::CharClass::POSIX> is a
L<PPIx::Regexp::Token::CharClass|PPIx::Regexp::Token::CharClass>.

C<PPIx::Regexp::Token::CharClass::POSIX> is the parent of
L<PPIx::Regexp::Token::CharClass::POSIX::Unknown|PPIx::Regexp::Token::CharClass::POSIX::Unknown>.

=head1 DESCRIPTION

This class represents a POSIX character class. It will only be
recognized within a character class.

Note that collating symbols (e.g. C<[.ch.]>) and equivalence classes
(e.g. C<[=a=]>) are valid in the POSIX standard, but are not valid in
Perl regular expressions. These end up being represented by
L<PPIx::Regexp::Token::CharClass::POSIX::Unknown|PPIx::Regexp::Token::CharClass::POSIX::Unknown>,
and are considered a parse failure.

=head1 METHODS

This class provides the following public methods beyond those provided
by its superclass.

=cut

package PPIx::Regexp::Token::CharClass::POSIX;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::CharClass };

use PPIx::Regexp::Constant qw{
    COOKIE_CLASS
    COOKIE_REGEX_SET
    MINIMUM_PERL
    @CARP_NOT
};

our $VERSION = '0.063';

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

##=head2 is_case_sensitive
##
##This override of the superclass method of the same name returns true if
##the character class is C<[:lower:]> or C<[:upper:]>, and false (but
##defined) for all other POSIX character classes.
##
##=cut
##
##{
##    my %case_sensitive = map { $_ => 1 } qw{ [:lower:] [:upper:] };
##
##    sub is_case_sensitive {
##	my ( $self ) = @_;
##	return $case_sensitive{ $self->content() } || 0;
##    }
##}

sub perl_version_introduced {
#   my ( $self ) = @_;
    return '5.006';
}

{

    my %explanation = (
	'[:alnum:]'	=> 'Any alphanumeric character',
	'[:^alnum:]'	=> 'Anything but an alphanumeric character',
	'[:alpha:]'	=> 'Any alphabetic',
	'[:^alpha:]'	=> 'Anything but an alphabetic',
	'[:ascii:]'	=> 'Any character in the ASCII character set',
	'[:^ascii:]'	=> 'Anything but a character in the ASCII character set',
	'[:blank:]'	=> 'A GNU extension, equal to a space or a horizontal tab ("\\t")',
	'[:^blank:]'	=> 'A GNU extension, anything but a space or a horizontal tab ("\\t")',
	'[:cntrl:]'	=> 'Any control character',
	'[:^cntrl:]'	=> 'Anything but a control character',
	'[:digit:]'	=> 'Any decimal digit',
	'[:^digit:]'	=> 'Anything but a decimal digit',
	'[:graph:]'	=> 'Any non-space printable character',
	'[:^graph:]'	=> 'Anything but a non-space printable character',
	'[:lower:]'	=> 'Any lowercase character',
	'[:^lower:]'	=> 'Anything but a lowercase character',
	'[:print:]'	=> 'Any printable character',
	'[:^print:]'	=> 'Anything but a printable character',
	'[:punct:]'	=> 'Any graphical character excluding "word" characters',
	'[:^punct:]'	=> 'Anything but a graphical character excluding "word" characters',
	'[:space:]'	=> 'Any whitespace character',
	'[:^space:]'	=> 'Anything but a whitespace character',
	'[:upper:]'	=> 'Any uppercase character',
	'[:^upper:]'	=> 'Anything but an uppercase character',
	'[:word:]'	=> 'A Perl extension, equivalent to "\\w"',
	'[:^word:]'	=> 'A Perl extension, equivalent to "\\W"',
	'[:xdigit:]'	=> 'Any hexadecimal digit',
	'[:^xdigit:]'	=> 'Anything but a hexadecimal digit',
    );

    sub __explanation {
	return \%explanation;
    }

    sub __no_explanation {
##	my ( $self ) = @_;		# Invocant unused
	my $msg = sprintf q<Unknown POSIX character class>;
	return $msg;
    }

}

{

    my %class = (
	':' => __PACKAGE__,
    );

    sub __PPIX_TOKENIZER__regexp {
	my ( undef, $tokenizer ) = @_;	# Invocant, $character unused

	$tokenizer->cookie( COOKIE_CLASS )
	    or $tokenizer->cookie( COOKIE_REGEX_SET )
	    or return;

	if ( my $accept = $tokenizer->find_regexp(
		qr{ \A [[] ( [.=:] ) \^? .*? \1 []] }smx ) ) {
	    my ( $punc ) = $tokenizer->capture();
	    return $tokenizer->make_token( $accept,
		$class{$punc} || __PACKAGE__ . '::Unknown' );
	}

	return;

    }

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
