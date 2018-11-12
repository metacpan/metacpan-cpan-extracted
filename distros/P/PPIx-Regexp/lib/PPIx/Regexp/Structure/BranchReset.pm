=head1 NAME

PPIx::Regexp::Structure::BranchReset - Represent a branch reset group

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{(?|(foo)|(bar))}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Structure::BranchReset> is a
L<PPIx::Regexp::Structure|PPIx::Regexp::Structure>.

C<PPIx::Regexp::Structure::BranchReset> has no descendants.

=head1 DESCRIPTION

This class represents a branch reset group. That is, the construction
C<(?|(...)|(...)|...)>. This is new with Perl 5.010.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Structure::BranchReset;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Structure };

use Carp qw{ confess };
use PPIx::Regexp::Constant qw{ @CARP_NOT };

our $VERSION = '0.063';

# Called by the lexer to record the capture number.
sub __PPIX_LEXER__record_capture_number {
    my ( $self, $number ) = @_;
    defined $number
	or confess 'Programming error - initial $number is undef';
    my $original = $number;
    my $hiwater = $number;
    foreach my $kid ( $self->children() ) {
	if ( $kid->isa( 'PPIx::Regexp::Token::Operator' )
	    && $kid->content() eq '|' ) {
	    $number > $hiwater and $hiwater = $number;
	    $number = $original;
	} else {
	    $number = $kid->__PPIX_LEXER__record_capture_number( $number );
	}
    }
    return $number > $hiwater ? $number : $hiwater;
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
