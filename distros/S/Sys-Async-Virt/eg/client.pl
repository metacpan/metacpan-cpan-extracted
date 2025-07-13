#!/usr/bin/perl

use v5.26;
use warnings;
use experimental 'signatures';
use Future::AsyncAwait;
use Feature::Compat::Try;

use Data::Dumper;

use IO::Async::Loop;
use Log::Any qw($log);
use Log::Any::Adapter;
use Log::Any::Adapter::Stdout;
use Sys::Async::Virt;

Log::Any::Adapter->set('Stdout', log_level => 'trace');
my $loop = IO::Async::Loop->new;

my $virt = Sys::Async::Virt->new(url => 'qemu:///system');
$loop->add( $virt );
await $virt->connect;
$log->trace( 'Created libvirt client application layer' );

await $virt->auth();
$log->trace( 'Authenticated' );

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

await $loop->delay_future( after => 8*60 );
await $virt->close;
