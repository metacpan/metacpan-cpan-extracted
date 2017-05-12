use FindBin;
use lib "$FindBin::Bin/lib";
use Net::RabbitMQ::Test;
use Net::RabbitMQ::Test::UA;
use Test::Most;

BEGIN {
    use_ok('Net::RabbitMQ::Management::API');
    use_ok('Net::RabbitMQ::Management::API::Result');
}

done_testing;
