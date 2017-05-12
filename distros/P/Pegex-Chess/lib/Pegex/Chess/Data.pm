package Pegex::Chess::Data;
use Pegex::Base;
extends 'Pegex::Tree';

sub got_row {
    my ($self, $got) = @_;
    [ map { s/ /_/; $_ } @$got ];
}

1;
