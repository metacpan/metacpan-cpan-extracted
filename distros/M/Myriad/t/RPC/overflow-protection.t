use strict;
use warnings;

use Test::More;
use Test::MockModule;

use Future;
use Future::AsyncAwait;
use Future::Utils qw(fmap_void);
use IO::Async::Loop;
use Myriad::Transport::Memory;
use Myriad::Transport::Redis;
use Myriad::RPC::Message;
use Sys::Hostname qw(hostname);
use Object::Pad qw(:experimental);

use Myriad;

my $processed = 0;

package Service::RPC {
    use Myriad::Service;
    has $count;

    async method startup () {
        # Zero our counter on startup
        $count = 0;
    }

    async method never_ending_rpc : RPC (%args) {
        ++$count;

        $args{internal_count} = $count;
        $log->tracef('DOING %s', \%args);
        $processed++;
        await $self->loop->delay_future(after => 1000);
        return \%args;
    }
};

my $loop = IO::Async::Loop->new;
# Only used for in memory tests
my $transport;
async sub myriad_instance {
    my $service = shift // '';

    my $myriad = new_ok('Myriad');

    # Only in case of memory transport, we want to share the same transport instance.
    if (!$ENV{MYRIAD_TRANSPORT} || $ENV{MYRIAD_TRANSPORT} eq 'memory' ) {
        my $metaclass = Object::Pad::MOP::Class->for_class('Myriad');
        $metaclass->get_field('$memory_transport')->value($myriad) = $transport;
    }

    my @config = ('--transport', $ENV{MYRIAD_TRANSPORT} // 'memory', '--transport_cluster', $ENV{MYRIAD_TRANSPORT_CLUSTER} // 0);
    push @config, qw(--log_level warn);
    await $myriad->configure_from_argv(@config, $service);
    $myriad->run->retain->on_fail(sub { fail(shift); });

    return $myriad;

}

my $whoami = Myriad::Util::UUID::uuid();
sub generate_requests {
    my ($rpc, $count, $expiry) = @_;
    my $id = 1;
    my @req;
    for (1..$count) {
        push @req, Myriad::RPC::Message->new(
            rpc        => $rpc,
            who        => $whoami,
            deadline   => time + $expiry,
            message_id => $id,
            args       => {
                test => $id++,
                who  => $whoami
            }
        );
    }
    return @req;
}

subtest 'RPCs should not consume more than it can process'  => sub {
    (async sub {

        my $message_count = 55;
        my @requests = generate_requests('never_ending_rpc', $message_count, 1000);
        my $stream_name = 'service.service.rpc.rpc/never_ending_rpc';

        # Add messages to stream then read them without acknowleging to make them go into pending state
        if (!$ENV{MYRIAD_TRANSPORT} || $ENV{MYRIAD_TRANSPORT} eq 'memory' ) {
            $transport = Myriad::Transport::Memory->new;
            $loop->add($transport);
            foreach my $req (@requests) {
                await $transport->add_to_stream($stream_name, $req->as_hash->%*);
            }
            await $transport->create_consumer_group($stream_name, 'processors');
            await $transport->read_from_stream_by_consumer($stream_name, 'processors', hostname());
        } else {
            $loop->add( my $redis = Myriad::Transport::Redis->new(
                redis_uri => $ENV{MYRIAD_TRANSPORT},
                cluster => $ENV{MYRIAD_TRANSPORT_CLUSTER} // 0,
            ));
            await $redis->start;
            foreach my $req (@requests) {
                await $redis->xadd($stream_name => '*', $req->as_hash->%*);
            }
            await $redis->create_group($stream_name, 'processors');
            await $redis->read_from_stream(client => hostname(), group => 'processors', stream => $stream_name);
        }


        note "starting service";
        my $rpc_myriad = await myriad_instance('Service::RPC');
        await $loop->delay_future(after => 0.4);

        is $processed, 50, 'Have tried to process only what it can take';
        isnt $processed, $message_count, 'messages sent count is not matching messages tried to process count';
    })->()->get();
};


done_testing();
