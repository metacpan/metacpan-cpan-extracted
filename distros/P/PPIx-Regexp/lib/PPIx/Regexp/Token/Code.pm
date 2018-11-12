=head1 NAME

PPIx::Regexp::Token::Code - Represent a chunk of Perl embedded in a regular expression.

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new(
     'qr{(?{print "hello sailor\n"})}smx')->print;

=head1 INHERITANCE

C<PPIx::Regexp::Token::Code> is a
L<PPIx::Regexp::Token|PPIx::Regexp::Token>.

C<PPIx::Regexp::Token::Code> is the parent of
L<PPIx::Regexp::Token::Interpolation|PPIx::Regexp::Token::Interpolation>.

=head1 DESCRIPTION

This class represents a chunk of Perl code embedded in a regular
expression. Specifically, it results from parsing things like

 (?{ code })
 (??{ code })

or from the replacement side of an s///e. Technically, interpolations
are also code, but they parse differently and therefore end up in a
different token.

This token may not appear inside a regex set (i.e. C<(?[ ... ])>. If
found, it will become a C<PPIx::Regexp::Token::Unknown>.

=head1 METHODS

This class provides the following public methods. Methods not documented
here are private, and unsupported in the sense that the author reserves
the right to change or remove them without notice.

=cut

package PPIx::Regexp::Token::Code;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

use PPI::Document;
use PPIx::Regexp::Constant qw{ COOKIE_REGEX_SET @CARP_NOT };
use PPIx::Regexp::Util qw{ __instance };

our $VERSION = '0.063';

use constant TOKENIZER_ARGUMENT_REQUIRED => 1;
use constant VERSION_WHEN_IN_REGEX_SET => undef;

sub __new {
    my ( $class, $content, %arg ) = @_;

    defined $arg{perl_version_introduced}
	or $arg{perl_version_introduced} = '5.005';

    my $self = $class->SUPER::__new( $content, %arg );

    # TODO sort this out, since Token::Interpolation is a subclass, and
    # those are legal in regex sets
    if ( $arg{tokenizer}->cookie( COOKIE_REGEX_SET ) ) {
	my $ver = $self->VERSION_WHEN_IN_REGEX_SET()
	    or return $self->__error( 'Code token not valid in Regex set' );
	$self->{perl_version_introduced} < $ver
	    and $self->{perl_version_introduced} = $ver;
    }

    $arg{tokenizer}->__recognize_postderef( $self )
	and $self->{perl_version_introduced} < 5.019005
	and $self->{perl_version_introduced} = '5.019005';

    return $self;
}

sub content {
    my ( $self ) = @_;
    if ( exists $self->{content} ) {
	return $self->{content};
    } elsif ( exists $self->{ppi} ) {
	return ( $self->{content} = $self->{ppi}->content() );
    } else {
	return;
    }
}

sub explain {
    return 'Perl expression';
}

=head2 ppi

This convenience method returns the L<PPI::Document|PPI::Document>
representing the content. This document should be considered read only.

=cut

sub ppi {
    my ( $self ) = @_;
    if ( exists $self->{ppi} ) {
	return $self->{ppi};
    } elsif ( exists $self->{content} ) {
	return ( $self->{ppi} = PPI::Document->new(
		\($self->{content}), readonly => 1 ) );
    } else {
	return;
    }
}

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

{
    no warnings qw{ qw };	## no critic (ProhibitNoWarnings)

    my %accept = map { $_ => 1 } qw{ $ $# @ % & * };

    # Say what casts are accepted, since not all are in am
    # interpolation.
    sub __postderef_accept_cast {
	return \%accept;
    }
}

sub __PPIX_TOKENIZER__regexp {
    my ( undef, $tokenizer, $character ) = @_;

    $character eq '{' or return;

    my $offset = $tokenizer->find_matching_delimiter()
	or return;

    return $offset + 1;	# to include the closing delimiter.
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
