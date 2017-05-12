use strict;
use warnings;

use Test::Most;

use FindBin qw/ $Bin /;
use lib $Bin;
use Net::AMQP::RabbitMQ::PP::Test;

use_ok( 'Net::AMQP::RabbitMQ::PP' );

isa_ok( my $object = Net::AMQP::RabbitMQ::PP->new (), 'Net::AMQP::RabbitMQ::PP');

done_testing();
