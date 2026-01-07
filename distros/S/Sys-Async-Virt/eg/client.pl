#!/usr/bin/perl

use v5.26;
use warnings;
use experimental 'signatures';
use Future::AsyncAwait;
use Feature::Compat::Try;

use Data::Dumper;

use Future::IO;
use Log::Any qw($log);
use Log::Any::Adapter;
use Log::Any::Adapter::Stdout;
use Sys::Async::Virt;

Log::Any::Adapter->set('Stdout', log_level => 'trace');

my $virt = Sys::Async::Virt->new(url => 'qemu:///system');

async sub main {
    await $virt->connect;
    $log->trace( 'Created libvirt client application layer' );

    try {
        my $es = await $virt->domain_event_register_any(
            $virt->DOMAIN_EVENT_ID_LIFECYCLE);
        my $rv = await $virt->node_get_cpu_stats($virt->CPU_STATS_ALL_CPUS);
        say Dumper($rv);
        #$log->trace( 'Listed' );
        $rv = await $virt->list_all_domains;
        say scalar $rv->@*;

        my $p = await $rv->[0]->get_scheduler_parameters;
        say Dumper($p);

    }
    catch ($e) {
        say 'abc: ' . Dumper($e);
    }

    say "\nsleeping for 20 seconds\n";
    await Future::IO->sleep( 20 );

    say "\nclosing connection\n";
    await $virt->close;
    $virt->stop;
}

await Future->wait_all(
    Future::IO->sleep(1), # work around some futures not having ->await()
    $virt->run,
    main() );
