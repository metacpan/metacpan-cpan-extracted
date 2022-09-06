use strict;
use warnings;

use Future::AsyncAwait;

use Test::More;
use Test::Myriad;

package Test::Emitter {
    use Myriad::Service;
    async method just_emitter :Emitter() ($sink) {
        my $i = 0;
        while (1) {
            $sink->emit({event => $i++});
            await $self->loop->delay_future(after => 0.001);
        }
    }
}

package Test::Receiver {
    use Myriad::Service;
    async method just_receiver :Receiver(
        service => 'Test::Emitter',
        channel => 'just_emitter'
    ) ($src) {
        return $src->map(sub {});
    }
}

BEGIN () {
    Test::Myriad->add_service(service => 'Test::Emitter');
    Test::Myriad->add_service(service => 'Test::Receiver');
}

await Test::Myriad->ready();

my $myriad = Test::Myriad->instance;

subtest 'Consumer groups usage' => sub {
    my $transport = $myriad->transport('subscription');
    my $stream = 'test.emitter.just_emitter';
    ok($transport->exists($stream)->get, 'stream exists');
    my $groups = $transport->stream_groups_info($stream)->get;
    is ($groups->[0]->{name}, 'test.receiver', 'correct group name');
};

done_testing;

