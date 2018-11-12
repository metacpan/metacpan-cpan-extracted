=head1 NAME

PPIx::Regexp::Support - Basis for the PPIx::Regexp support classes

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{foo}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Support> is not descended from any other class.

C<PPIx::Regexp::Support> is the parent of
L<PPIx::Regexp::Dumper|PPIx::Regexp::Dumper>,
L<PPIx::Regexp::Lexer|PPIx::Regexp::Lexer> and
L<PPIx::Regexp::Tokenizer|PPIx::Regexp::Tokenizer>.

=head1 DESCRIPTION

This abstract class provides methods for the C<PPIx::Regexp> support
classes.

=head1 METHODS

This class provides the following public methods. Methods not documented
here are private, and unsupported in the sense that the author reserves
the right to change or remove them without notice.

=cut

package PPIx::Regexp::Support;

use strict;
use warnings;

use PPIx::Regexp::Constant qw{ @CARP_NOT };
use PPIx::Regexp::Util qw{ __instance };

our $VERSION = '0.063';

=head2 close_bracket

This method takes as its argument a character. If this character is an
open bracket the corresponding close bracket is returned. Otherwise
C<undef> is returned. Only the ASCII bracket characters are considered
brackets: (), {}, [], and <>.

=cut

{
    my %bracket = (
	'(' => ')',
	'{' => '}',
	'<' => '>',
	'[' => ']',
    );

    sub close_bracket {
	my ( undef, $char ) = @_;	# Invocant unused
	defined $char or return;
	__instance( $char, 'PPIx::Regexp::Element' )
	    and $char = $char->content();
	return $bracket{$char};
    }

}

=head2 decode

This method wraps the Encode::decode subroutine. If the object specifies
no encoding or encode_available() returns false, this method simply
returns its input string.

=cut

sub decode {
    my ( $self, $data ) = @_;
    defined $self->{encoding} or return $data;
    encode_available() or return $data;
    return Encode::decode( $self->{encoding}, $data );
}

=head2 encode

This method wraps the Encode::encode subroutine. If the object specifies
no encoding or encode_available() returns false, this method simply
returns its input string.

=cut

sub encode {
    my ( $self, $data ) = @_;
    defined $self->{encoding} or return $data;
    encode_available() or return $data;
    return Encode::encode( $self->{encoding}, $data );
}

=head2 encode_available

This method returns true if the Encode module is available, and false
otherwise. If it returns true, the Encode module has actually been
loaded.

=cut

{

    my $encode_available;

    sub encode_available {
	defined $encode_available and return $encode_available;
	return ( $encode_available = eval {
		require Encode;
		1;
	    } ? 1 : 0
	);
    }

}

# This method is to be used only by the PPIx-Regexp package. It returns
# the first of its arguments which is defined. It will go away when
# (or if!) these modules get 'use 5.010;' at the top.

sub __defined_or {
    my ( undef, @args ) = @_;	# Invocant unused
    foreach my $arg ( @args ) {
	defined $arg and return $arg;
    }
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
