use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Myriad;

use Future;
use Future::AsyncAwait;

my ($ping_service, $pong_service);

package Test::Ping {
    use Myriad::Service;
    async method ping : RPC (%args) {
        return await $api->service_by_name('Test::Pong')->call_rpc('pong');
    }
}

package Test::Pong {
   use Myriad::Service;
   async method pong : RPC (%args) {
        return {pong => 1};
   }
}

BEGIN {
   $ping_service = Test::Myriad->add_service(service => 'Test::Ping');
   $pong_service = Test::Myriad->add_service(service => 'Test::Pong');
}


await Test::Myriad->ready();

subtest 'RPC should return a response to caller' => sub {
    my $resposne = $pong_service->call_rpc('pong')->get;
    cmp_deeply($resposne, {pong => 1});
};

subtest 'RPC client should receive a response' => sub {
    my $response = $ping_service->call_rpc('ping')->get();
    cmp_deeply($response, {pong => 1});
};

done_testing();

