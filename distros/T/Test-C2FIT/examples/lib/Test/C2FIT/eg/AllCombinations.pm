# Copyright (c) 2002 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl port by Martin Busik <martin.busik@busik.de>
#

package Test::C2FIT::eg::AllCombinations;
use base 'Test::C2FIT::eg::AllFiles';

sub new {
    my $pkg = shift;
    my $self = bless $pkg->SUPER::new(), $pkg;
    $self->{lists}      = [];
    $self->{caseNumber} = 1;
    $self->{row}        = undef;
    return $self;
}

sub doTable {
    my ( $self, $table ) = @_;
    $self->{row} = $table->{parts}->last();
    $self->SUPER::doTable($table);
    $self->combinations2();
}

sub doRow2 {
    my ( $self, $row, $files ) = @_;
    push( @{ $self->{lists} }, $files );
}

sub combinations2 {
    my $self = shift;
    $self->combinations( 0, [] );
}

sub combinations {
    my ( $self, $index, $combination ) = @_;
    if ( $index == @{ $self->{lists} } ) {
        $self->doCase($combination);
    }
    else {
        my @files = @{ $self->{lists}->[$index] };
        for ( my $i = 0 ; $i < @files ; $i++ ) {
            $combination->[$index] = $files[$i];
            $self->combinations( $index + 1, $combination );
        }
    }
}

sub doCase {
    my ( $self, $combination ) = @_;
    my $number =
      $self->tr( $self->td( "#" + $self->{caseNumber}++, undef ), undef );
    $number->leaf()->addToTag(" colspan=2");
    $self->{row}->last()->{more} = $number;
    $self->SUPER::doRow2( $number, $combination );
}

1;

