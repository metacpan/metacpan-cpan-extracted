package Pangloss::Segment::ShowStore;

use base qw( Pipeline::Segment );

sub dispatch {
    my $self = shift;
    # this will only work for simple stores
    $self->emit( "store contains:" . join( "\n\t", keys %{ $self->store->{storehash} } ) );
}

1;
