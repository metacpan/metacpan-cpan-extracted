package Seis::Exception;
use strict;
use warnings;
use utf8;
use 5.010_001;
use parent qw(Exception::Tiny);

sub WHAT {
    my $self = shift;
    Seis::Class->_new(name => 'Exception');
}

1;

