package Seis::Autobox;
use strict;
use warnings;
use utf8;
use 5.010_001;
use parent qw(autobox);

sub import {
    my $class = shift;
    $class->SUPER::import(
        ARRAY   => 'Array',
        INTEGER => 'Int',
        FLOAT   => 'Real',
        STRING  => 'Str',
        CODE    => 'Sub',
        HASH    => 'Seis::Hash',
        UNDEF   => 'Seis::Undef',
    );
}

1;
