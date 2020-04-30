package Test::Class::Simple::Module;
use strict;
use warnings;

sub check_reference {
    my $value = shift;

    return ( ref $value ) ? 1 : 0;
}

1;
