package Seis::Socket;
use strict;
use warnings;
use utf8;
use 5.010_001;

sub getpeername:method {
    CORE::getpeername($_[0]);
}

1;

