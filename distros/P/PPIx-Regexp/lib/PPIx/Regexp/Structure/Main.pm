=head1 NAME

PPIx::Regexp::Structure::Main - Represent a regular expression proper, or a substitution

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{foo}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Structure::Main> is a
L<PPIx::Regexp::Structure|PPIx::Regexp::Structure>.

C<PPIx::Regexp::Structure::Main> is the parent of
L<PPIx::Regexp::Structure::Regexp|PPIx::Regexp::Structure::Regexp> and
L<PPIx::Regexp::Structure::Replacement|PPIx::Regexp::Structure::Replacement>.

=head1 DESCRIPTION

This abstract class represents one of the top-level structures in the
expression. Both
L<PPIx::Regexp::Structure::Regexp|PPIx::Regexp::Structure::Regexp> and
L<PPIx::Regexp::Structure::Replacement|PPIx::Regexp::Structure::Replacement>
are derived from it.

=head1 METHODS

This class provides the following public methods. Methods not documented
here are private, and unsupported in the sense that the author reserves
the right to change or remove them without notice.

=cut

package PPIx::Regexp::Structure::Main;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Structure };

use PPIx::Regexp::Constant qw{ @CARP_NOT };

our $VERSION = '0.063';

=head2 delimiters

This method returns a string representing the delimiters of a regular
expression or substitution string. In the case of something like
C<s/foo/bar/>, it will return '//' for both the regular expression and
the replacement.

=cut

sub delimiters {
    my ( $self ) = @_;
    my @delims;
    foreach my $method ( qw{ start finish } ) {
	push @delims, undef;
	defined ( my $obj = $self->$method() )
	    or next;
	defined ( my $str = $obj->content() )
	    or next;
	$delims[-1] = $str;
    }
    defined ( $delims[0] )
	or $delims[0] = $delims[1];
    return $delims[0] . $delims[1];
}

=head2 interpolates

This method returns true if the regular expression or replacement
interpolates, and false otherwise. All it really does is to check
whether the ending delimiter is a single quote.

=cut

sub interpolates {
    my ( $self ) = @_;
    my $finish = $self->finish( 0 ) or return 1;
    return q<'> ne $finish->content();
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
