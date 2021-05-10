use strict;
use warnings;

use Future::AsyncAwait;
use Test::More;
use Log::Any::Adapter qw(TAP);
use Myriad;

package Example::Sender {
    use Myriad::Service;
    has $sent = 0;

    async method simple_emitter : Emitter() ($sink) {
        my $data = {event => 1};
        $log->infof('emitter emits %s', $data);
        $sink->emit($data);
    }

    async method simple_batch : Batch () {
        my $arr = [];
        $arr =  [{event => 1}, {event => 2}] unless $sent;
        $sent = 1;
        $log->infof('batch emits %s', $arr);
        return $arr;
    }
}

my @received_from_emitter;
my @received_from_batch;

package Example::Receiver {
    use Myriad::Service;
    async method receiver_from_emitter : Receiver(
        service => 'Example::Sender',
        channel => 'simple_emitter'
    ) ($src) {
        return $src->map(sub {
            push @received_from_emitter, shift
        });
    }

    async method receiver_from_batch : Receiver(
        service => 'Example::Sender',
        channel => 'simple_batch'
    ) ($src) {
        return $src->map(sub {
            $log->infof('batch receives %s', $_);
            push @received_from_batch, shift
        });
    }
}

my $myriad = new_ok('Myriad');
await $myriad->configure_from_argv(
    qw(--transport memory --log_level warn service)
);

await $myriad->add_service('Example::Receiver');
await $myriad->add_service('Example::Sender');

$myriad->run->retain;

ok($myriad->subscription, 'subscription is initiated');

is(scalar $myriad->subscription->receivers->@*, 2, 'We have correct number of receivers detected');

# we need 4 steps to publish the events
$myriad->loop->loop_once for 0..4;

is(@received_from_emitter, 1, 'we have received correct number of messages from emitter');
is(@received_from_batch,   2, 'we have received correct number of messages from batch');

done_testing;

