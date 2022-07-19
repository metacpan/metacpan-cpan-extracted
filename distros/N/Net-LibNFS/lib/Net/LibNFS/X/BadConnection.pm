package Net::LibNFS::X::BadConnection;

use strict;
use warnings;

use parent qw( Net::LibNFS::X::Base );

sub new {
    my ( $class ) = @_;

    return $class->SUPER::new('Connection in unrecoverable state');
}

1;
