package Sash::Timer;

use strict;
use warnings;

use Time::HiRes qw( gettimeofday tv_interval );

my $_start;
my $_stop;

sub start {
    my $self = shift;
    $_start = [ gettimeofday ];
    $_stop = undef;
}

sub stop {
    my $self = shift;
    $_stop = [ gettimeofday ];
}

sub elapsed {
    my $self = shift;
    return undef unless ( $_start && $_stop );
    return sprintf( "(%.2f sec)", tv_interval( $_start, $_stop ) );
}

sub reset {
    my $self = shift;
    $_start = undef;
    $_stop = undef;
}


1;
