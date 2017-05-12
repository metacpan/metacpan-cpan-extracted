# $Id: PrimitiveFixture.pm,v 1.6 2006/06/16 15:20:56 tonyb Exp $
#
# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Dave W. Smith <dws@postcognitive.com>
# Modified by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::PrimitiveFixture;

use base 'Test::C2FIT::Fixture';
use strict;
use Test::C2FIT::TypeAdapter;

sub checkValue {
    my $self = shift;
    my ( $cell, $value ) = @_;

    if ( Test::C2FIT::TypeAdapter->equals( $cell->text(), $value ) ) {
        $self->right($cell);
    }
    else {
        $self->wrong( $cell, $value );
    }
}

1;

__END__


=pod

=head1 NAME

Test::C2FIT::PrimitiveFixture

=head1 SYNOPSIS

Normally, you subclass PrimitiveFixture.

	sub doCell
	{
		my $self = shift;
		my($cell, $column) = @_;

		if ( $column == 0 ) {
			$self->{'x'} = int($cell->text());
		} elsif ( $column == 2 ) {
			$self->checkValue($cell, $self->{'x'} * $self->{'x'};
		}
	}


=head1 DESCRIPTION

PrimitiveFixture offers a C<checkValue> method. Binding of columns to values is the programmer's job with
this fixture.


=head1 METHODS

=over 4

=item B<checkValue($cell,$value)>

Checks if the given cell contains something which equals to value. If so, the cell gets annotated as "right",
else as "wrong".

=back

=head1 SEE ALSO

Extensive and up-to-date documentation on FIT can be found at:
http://fit.c2.com/

=cut
