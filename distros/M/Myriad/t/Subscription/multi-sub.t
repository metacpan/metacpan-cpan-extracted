use strict;
use warnings;

use Future::AsyncAwait;
use Test::More;
use Log::Any::Adapter qw(TAP);
use Myriad;

package Example::Sender {
    use Myriad::Service;

    async method fast_e : Emitter() ($sink) {
        my $count = 1;
        while (1) {
            await $self->loop->delay_future(after => 0.2);
            $sink->emit({event => $count++});
        }
    }

    async method med_e : Emitter() ($sink) {
        my $count = 1;
        while (1) {
            await $self->loop->delay_future(after => 1 * $count);
            $sink->emit({event => $count++});
        }
    }

    async method slow_e : Emitter() ($sink) {
        my $count = 1;
        while (1) {
            await $self->loop->delay_future(after => 1 * 3 * $count);
            $sink->emit({event => $count++});
        }
    }

    async method fast_e2 : Emitter() ($sink) {
        my $count = 1;
        while (1) {
            await $self->loop->delay_future(after => 0.2);
            $sink->emit({event => $count++});
        }
    }
}

package Example::Sender2 {

    use Myriad::Service;

    async method em : Emitter() ($sink) {
        my $count = 1;
        while (1) {
            await $self->loop->delay_future(after => 1 * 0.5 * $count);
            $sink->emit({event => $count++});
        }
    }

    async method never_e : Emitter() ($sink) {
        my $count = 1;
        while (1) {
            await $self->loop->delay_future(after => 10);
            #
        }
    }
}
my %received;

package Example::Receiver {
    use Myriad::Service;
    async method zreceiver_from_emitter2 : Receiver(
        service => 'Example::Sender',
        channel => 'fast_e'
    ) ($src) {
        return $src->map(sub {
            push @{$received{fast_e}}, shift
        });
    }

    async method receiver_from_emitter : Receiver(
        service => 'Example::Sender',
        channel => 'med_e'
    ) ($src) {
        return $src->map(sub {
            push @{$received{med_e}}, shift
        });
    }

    async method hreceiver_from_emitter : Receiver(
        service => 'Example::Sender2',
        channel => 'em'
    ) ($src) {
        return $src->map(sub {
            push @{$received{em}}, shift
        });
    }

    async method receiver_from_emitter3 : Receiver(
        service => 'Example::Sender',
        channel => 'slow_e'
    ) ($src) {
        return $src->map(sub {
            push @{$received{slow_e}}, shift
        });
    }

    async method receiver_from_emitter4 : Receiver(
        service => 'Example::Sender',
        channel => 'fast_e2'
    ) ($src) {
        return $src->map(sub {
            push @{$received{fast_e2}}, shift
        });
    }

    async method never_receive : Receiver(
        service => 'Example::Sender2',
        channel => 'never_e'
    ) ($src) {
        return $src->map(sub {
            push @{$received{never_e}}, shift
        });
    }
}

my $myriad = new_ok('Myriad');
my @arg;
my $empty_stream_name;
if (my $t = $ENV{MYRIAD_TEST_TRANSPORT}) {
    @arg = qw(--transport redis://redis-node-0:6379 --transport_cluster 1 --log_level warn service);
    $empty_stream_name = 'service.subscriptions.example.sender2/never_e';
} else {
    @arg = qw(--transport memory --log_level warn service);
    $empty_stream_name = 'example.sender2.never_e';
}

await $myriad->configure_from_argv(@arg);

await $myriad->add_service('Example::Receiver');
await $myriad->add_service('Example::Sender2');
await $myriad->add_service('Example::Sender');

$myriad->run->retain;

ok($myriad->subscription, 'subscription is initiated');

my $loop = IO::Async::Loop->new;
await $loop->delay_future(after => 3.2);
my $transport = $myriad->transport('subscription');

is scalar $received{fast_e}->@*, 15, 'Got the right number of events from fast_emitter';
is scalar $received{med_e}->@*, 2, 'Got the right number of events from medium_emitter';
is scalar $received{slow_e}->@*, 1, 'Got the right number of events from slow_emitter';
is scalar $received{fast_e2}->@*, 15, 'Got the right number of events from fast_emitter2';
is scalar $received{em}->@*, 3, 'Got the right number of events from secondary medium_emitter';
is scalar $received{never_e}->@*, 0, 'Got no events from never_emit';

my $info = await $transport->stream_info($empty_stream_name);
ok($info, 'Stream has been created for the never-published emitter');

# Give any pending events a chance to complete, e.g. metrics
await $loop->later;

done_testing;

