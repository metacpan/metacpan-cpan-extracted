use strict;
use warnings;

use Test::More;
use Sensu::API::Client;

SKIP: {
    skip '$ENV{SENSU_API_URL} not set', 5 unless $ENV{SENSU_API_URL};

    my $api = Sensu::API::Client->new(
        url => $ENV{SENSU_API_URL},
    );

    my $r = $api->info;
    ok($r->{sensu},    'Got info about Sensu');
    ok($r->{rabbitmq}, 'Got info about RabbitMQ');
    ok($r->{redis},    'Got info about Redis');
}

done_testing();
