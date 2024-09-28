#!/usr/bin/perl

use v5.20;
use warnings;
use experimental 'signatures';
use Future::AsyncAwait;
use Feature::Compat::Try;

use IO::Async::Loop;
use IO::Async::Stream;
use Log::Any qw($log);
use Log::Any::Adapter;
use Log::Any::Adapter::Stdout;
use Protocol::Sys::Virt::Transport;
use Protocol::Sys::Virt::Remote;
use Sys::Async::Virt;
use Sys::Async::Virt::Connection::Factory;

Log::Any::Adapter->set('Stdout', log_level => 'trace');
my $loop = IO::Async::Loop->new;
my $prot = 'Protocol::Sys::Virt::Remote::XDR';

my $virt = Sys::Async::Virt->new(url => 'qemu:///system');
$loop->add( $virt );
await $virt->connect;
$log->trace( 'Created libvirt client application layer' );

await $virt->auth( $prot->AUTH_NONE );
$log->trace( 'Authenticated' );

await $virt->open( 'qemu:///system' );

use Data::Dumper;
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

await $virt->close;
