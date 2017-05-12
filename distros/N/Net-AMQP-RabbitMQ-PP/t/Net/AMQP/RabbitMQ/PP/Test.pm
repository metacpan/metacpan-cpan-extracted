package Net::AMQP::RabbitMQ::PP::Test;

use strict;
use warnings;

use Test::Most;

$ENV{'MQHOST'} || plan skip_all => "MQHOST required";

use Test::File::ShareDir::Dist {
	'Net-AMQP-RabbitMQ-PP' => 'share/'
};

1;
