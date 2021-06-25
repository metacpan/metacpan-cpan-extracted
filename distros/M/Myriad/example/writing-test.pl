use strict;
use warnings;

use Future::AsyncAwait;

use Test::More;
use Test::Myriad;

my ($mocked_service, $developer_service);

package Test::Service::Real {
    use Myriad::Service;
    use Test::More;

    async method say_hi : RPC {
        return {mocked => 0};
    }

    async method say_bye : RPC {
        return {bye => 1};
    }

    async method get_event : Receiver(service => 'Test::Service::Mocked', channel => 'weekends') ($source) {
        await $source->each(sub {
            my $event = shift;
            like($event->{name}, qr{Saturday|Sunday},'We are getting data correctly');
        })->completed();
    }
}

BEGIN {
    $mocked_service = Test::Myriad->add_service(name => "Test::Service::Mocked")
                        ->add_rpc('say_hi', hello => 'other service!')
                        ->add_subscription('weekends', array => [{ name => 'Saturday' }, {name => 'Sunday' }]);

    $developer_service = Test::Myriad->add_service(service => 'Test::Service::Real');
}

await Test::Myriad->ready;

subtest 'it should respond to RPC' => sub {
    (async sub {
        my $response = await $mocked_service->call_rpc('say_hi');
        ok($response->{response}->{hello}, 'rpc message has been received');
    })->()->get();
}; 

subtest 'it can mock developer rpc' => sub {
    (async sub {
        $developer_service->mock_rpc('say_hi', mocked => 1);
        my $response = await $developer_service->call_rpc('say_hi');
        ok($response->{response}->{mocked}, 'it can mock rpc provided by other services');
    })->()->get();
};

done_testing();

