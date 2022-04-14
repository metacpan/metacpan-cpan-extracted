package Protocol::DBus::X::SurpriseShutdown;

use strict;
use warnings;

use parent qw( Protocol::DBus::X::Base );

sub _new {
    my ($class) = @_;

    return $class->SUPER::_new('The D-Bus connection closed unexpectedly!');
}

1;
