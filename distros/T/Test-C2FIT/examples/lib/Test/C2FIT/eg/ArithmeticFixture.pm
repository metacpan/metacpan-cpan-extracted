# ArithmeticFixture.pm
#
# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Dave W. Smith <dws@postcognitive.com>
# Modified by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::eg::ArithmeticFixture;

use base 'Test::C2FIT::PrimitiveFixture';

sub new {
    my $pkg = shift;
    return $pkg->SUPER::new( x => 0, y => 0, @_ );
}

sub doRows {
    my $self = shift;
    my ($rows) = @_;

    # skip column heads
    $self->SUPER::doRows( $rows->more() );
}

sub doCell {
    my $self = shift;
    my ( $cell, $column ) = @_;

    if ( $column == 0 ) {
        $self->{'x'} = int( $cell->text() );
    }
    elsif ( $column == 1 ) {
        $self->{'y'} = int( $cell->text() );
    }
    elsif ( $column == 2 ) {
        $self->checkValue( $cell, $self->{'x'} + $self->{'y'} );
    }
    elsif ( $column == 3 ) {
        $self->checkValue( $cell, $self->{'x'} - $self->{'y'} );
    }
    elsif ( $column == 4 ) {
        $self->checkValue( $cell, $self->{'x'} * $self->{'y'} );
    }
    elsif ( $column == 5 ) {
        $self->checkValue( $cell, int( $self->{'x'} / $self->{'y'} ) );
    }
    else {
        $self->ignore($cell);
    }
}

1;
