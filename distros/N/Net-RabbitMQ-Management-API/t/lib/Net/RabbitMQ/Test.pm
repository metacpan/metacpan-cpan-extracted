package    # hide from PAUSE
  Net::RabbitMQ::Test;

use strict;
use warnings;
use Net::RabbitMQ::Test::UA;

sub create {
    my ( $self, $class, %args ) = @_;
    return $class->new(
        ua  => Net::RabbitMQ::Test::UA->new,
        url => $ENV{TEST_URI} || 'http://localhost:55672/api',
        %args
    );
}

1;
