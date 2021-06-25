use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Ryu::Async;

use IO::Async::Loop;
use Future::AsyncAwait;

use Myriad::Service::Implementation;

my $loop = IO::Async::Loop->new();

$loop->add(my $ryu = Ryu::Async->new);

subtest 'batch should work fine' => sub {
    my $fake_service = Myriad::Service::Implementation->new(
        name => 'fake_instance',
    );
    $loop->add($fake_service);

    my $sink = $ryu->sink;
    $fake_service->process_batch('fake_batch', async sub {
        return [{key => 1}];
    }, $sink)->retain;

    (async sub {
        $loop->delay_future(after => 0.001)->then(sub {
            $sink->source->finish;
        })->retain;

        my @batch = await $sink->source->as_list;

        cmp_ok(@batch, '>=', 1, 'batch working correctly');

    })->()->get()

};


subtest 'batch should through if output is wrong' => sub {
    my $fake_service = Myriad::Service::Implementation->new(
        name => 'fake_instance',
    );

    $loop->add($fake_service);

    my $sink = $ryu->sink;
    like(
        exception { $fake_service->process_batch('fake_batch', async sub {
            return {key => 1};
        }, $sink)->get},
    qr/Batch should return an arrayref/, 'Batch should throw if single hash returned');

    like(
        exception { $fake_service->process_batch('fake_batch', async sub {
            return 1;
        }, $sink)->get},
    qr/Batch should return an arrayref/, 'Batch should throw if a scalar returned');
};

subtest 'batch should still work if empty array returned' => sub {
    my $fake_service = Myriad::Service::Implementation->new(
        name => 'fake_instance',
    );

    $loop->add($fake_service);

    my $sink = $ryu->sink;
    $fake_service->process_batch('fake_batch', async sub {
            return [];
    }, $sink)->retain();

    (async sub {
        $loop->delay_future(after => 0.001)->then(sub {
            $sink->source->finish;
        })->retain;

        my @batch = await $sink->source->as_list;

        cmp_ok(@batch, '==', 0, 'batch did not die');
    })->()->get();
};

done_testing;

