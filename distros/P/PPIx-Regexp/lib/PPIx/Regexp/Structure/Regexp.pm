=head1 NAME

PPIx::Regexp::Structure::Regexp - Represent the top-level regular expression

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{foo}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Structure::Regexp> is a
L<PPIx::Regexp::Structure::Main|PPIx::Regexp::Structure::Main>.

C<PPIx::Regexp::Structure::Regexp> has no descendants.

=head1 DESCRIPTION

This class represents the top-level regular expression. In the example
given in the L</SYNOPSIS>, the C<{foo}> will be represented by this
class.

=head1 METHODS

This class provides the following public methods. Methods not documented
here are private, and unsupported in the sense that the author reserves
the right to change or remove them without notice.

=cut

package PPIx::Regexp::Structure::Regexp;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Structure::Main };

use PPIx::Regexp::Constant qw{ @CARP_NOT };

our $VERSION = '0.063';

sub can_be_quantified { return; }

=head2 capture_names

 foreach my $name ( $re->capture_names() ) {
     print "Capture name '$name'\n";
 }

This method returns the capture names found in the regular expression.

=cut

sub capture_names {
    my ( $self ) = @_;
    my %name;
    my $captures = $self->find(
	'PPIx::Regexp::Structure::NamedCapture')
	or return;
    foreach my $grab ( @{ $captures } ) {
	$name{$grab->name()}++;
    }
    return ( sort keys %name );
}

sub explain {
    return 'Regular expression';
}

=head2 max_capture_number

 print "Highest used capture number ",
     $re->max_capture_number(), "\n";

This method returns the highest capture number used by the regular
expression. If there are no captures, the return will be 0.

=cut

sub max_capture_number {
    my ( $self ) = @_;
    return $self->{max_capture_number};
}

# Called by the lexer once it has done its worst to all the tokens.
# Called as a method with the lexer as argument. The return is the
# number of parse failures discovered when finalizing.
sub __PPIX_LEXER__finalize {
    my ( $self, $lexer ) = @_;
    my $rslt = 0;
    foreach my $elem ( $self->elements() ) {
	$rslt += $elem->__PPIX_LEXER__finalize( $lexer );
    }

    # Calculate the maximum capture group, and number all the other
    # capture groups along the way.
    $self->{max_capture_number} =
	$self->__PPIX_LEXER__record_capture_number( 1 ) - 1;

    return $rslt;
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
