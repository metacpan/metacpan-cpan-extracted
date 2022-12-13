=head1 NAME

PPIx::Regexp::Structure::Assertion - Represent a parenthesized assertion

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{(?<=foo)bar}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Structure::Assertion> is a
L<PPIx::Regexp::Structure|PPIx::Regexp::Structure>.

C<PPIx::Regexp::Structure::Assertion> has no descendants.

=head1 DESCRIPTION

This class represents one of the parenthesized assertions, either look
ahead or look behind, and either positive or negative.

=head1 METHODS

This class provides the following public methods beyond those provided
by its superclass.

=cut

package PPIx::Regexp::Structure::Assertion;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Structure };

use Carp qw{ confess };
use List::Util qw{ max };

our $VERSION = '0.086';

use PPIx::Regexp::Constant qw{
    LITERAL_LEFT_CURLY_ALLOWED
    VARIABLE_LENGTH_LOOK_BEHIND_INTRODUCED
    @CARP_NOT
};

=head2 is_look_ahead

This method returns a true value if the assertion is a look-ahead
assertion, or a false value if it is a look-behind assertion.

=cut

sub is_look_ahead {
    my ( $self ) = @_;
    return $self->_get_type()->is_look_ahead();
}

=head2 is_positive

This method returns a true value if the assertion is a positive
assertion, or a false value if it is a negative assertion.

=cut

sub is_positive {
    my ( $self ) = @_;
    return $self->_get_type()->is_positive();
}

sub perl_version_introduced {
    my ( $self ) = @_;
    return( $self->{perl_version_introduced} ||=
	$self->_perl_version_introduced() );
}

sub _perl_version_introduced {
    my ( $self ) = @_;
    my $ver = max( map { $_->perl_version_introduced() }
	$self->children() );
    if ( $ver < VARIABLE_LENGTH_LOOK_BEHIND_INTRODUCED &&
	!  $self->is_look_ahead()
    ) {
	my ( $wid_min, $wid_max ) = $self->raw_width();
	defined $wid_min
	    and defined $wid_max
	    and $wid_min < $wid_max
	    and $ver = max( $ver, VARIABLE_LENGTH_LOOK_BEHIND_INTRODUCED );
    }
    return $ver;
}

sub width {
    return ( 0, 0 );
}

# An un-escaped literal left curly bracket can always follow this
# element.
sub __following_literal_left_curly_disallowed_in {
    return LITERAL_LEFT_CURLY_ALLOWED;
}

sub _get_type {
    my ( $self ) = @_;
    my $type = $self->type()
	or confess 'Programming error - no type object';
    $type->isa( 'PPIx::Regexp::Token::GroupType::Assertion' )
	or confess 'Programming error - type object is ', ref $type,
	    ' not PPIx::Regexp::Token::GroupType::Assertion';
    return $type;
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
