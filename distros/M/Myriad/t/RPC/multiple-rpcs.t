use strict;
use warnings;

use Test::More;

use Future;
use Future::AsyncAwait;
use Future::Utils qw(fmap_void);

use Myriad;

package Service::RPC {
    use Myriad::Service;

    async method echo : RPC (%args) {
        return \%args;
    }

    async method ping : RPC (%args) {
        return {time => time}
    }

    async method reverse : RPC (%args) {
        return {reversed => scalar reverse("$args{v}")};
    }
};


subtest 'RPCs should not block each others in the same service'  => sub {
    (async sub {
        my $myriad = new_ok('Myriad');

        await $myriad->configure_from_argv('--transport', $ENV{MYRIAD_TRANSPORT} // 'memory', '--transport_cluster', $ENV{MYRIAD_TRANSPORT_CLUSTER} // 0);
        await $myriad->add_service('Service::RPC');

        # Run the service
        $myriad->run->retain->on_fail(sub {
            die shift;
        });
        await $myriad->loop->delay_future(after => 0.25);

        # if one RPC doesn't have messages it should not block the others
        for my $i (0..10) {
            await Future->needs_any(
                fmap_void(async sub {
                    my $rpc = shift;
                    my $response = await $myriad->rpc_client->call_rpc('service.rpc', $rpc)->catch(sub {warn shift});
                    if ( $rpc eq 'ping' ) {
                         cmp_ok $response->{time}, '==', time, 'Ping Matching Time';
                    } elsif ( $rpc eq 'echo' ) {
                        like $response, qr//, 'Got echo response';
                    }
                }, foreach => ['echo', 'ping'], concurrent => 3),
                $myriad->loop->timeout_future(after => 1)
            );
        }
    })->()->get();
};

subtest 'RPCs should not block each others in different services, same Myriad instance'  => sub {
    (async sub {

        package Another::RPC {
            use Myriad::Service;

            async method zero : RPC (%args) {
                return 0;
            }

            async method five : RPC (%args) {
                return 5;
            }

            async method twenty_five : RPC (%args) {
                return 25;
            }

            async method double : RPC (%args) {
                return $args{v} * 2;
            }
        };

        my $myriad = new_ok('Myriad');

        await $myriad->configure_from_argv('--transport', $ENV{MYRIAD_TRANSPORT} // 'memory', '--transport_cluster', $ENV{MYRIAD_TRANSPORT_CLUSTER} // 0);
        await $myriad->add_service('Service::RPC');
        await $myriad->add_service('Another::RPC');

        # Run the service
        $myriad->run->retain->on_fail(sub {
            die shift;
        });
        await $myriad->loop->delay_future(after => 0.25);

        # if one service's RPC doesn't have messages it should not block the others

        for my $i (0..10) {
            await Future->needs_any(
                fmap_void(async sub {
                    my ($service, $rpc, $args, $res) = shift->@*;
                    my $response = await $myriad->rpc_client->call_rpc($service, $rpc, %$args);
                    is_deeply $response, $res, "Matching response $service:$rpc";
                }, foreach => [
                    ['service.rpc' => 'echo'   , { hi => 'echo' }    , { hi => 'echo' } ],
                    ['service.rpc' => 'reverse', { v => 'reverseme' }, { reversed => 'emesrever' } ],
                    ['another.rpc' => 'double' , { v => 4 }          , 8 ],
                    ['another.rpc' => 'five'   , {}                  , 5 ],
                ], concurrent => 6),
                $myriad->loop->timeout_future(after => 1),
            );
            # Calling ping RPC here where it return time is inefficient as we might go to the next second.
        }
    })->()->get();
};

done_testing();
