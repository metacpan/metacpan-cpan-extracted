#!/usr/bin/perl

use v5.20;
use warnings;
use experimental 'signatures';
use Future::AsyncAwait;
use Feature::Compat::Try;

use IO::Async::Loop;
use Log::Any qw($log);
use Log::Any::Adapter;
use Log::Any::Adapter::Stdout;
use Sys::Async::Virt;

Log::Any::Adapter->set('Stdout', log_level => 'trace');
my $loop = IO::Async::Loop->new;


my $virt = Sys::Async::Virt->new(
    url => 'qemu:///system'
    );
$loop->add( $virt );
$log->trace( 'Created libvirt client application layer' );

my %states = (
   Sys::Async::Virt::Domain->NOSTATE => 'no state',
   Sys::Async::Virt::Domain->RUNNING => 'running',
   Sys::Async::Virt::Domain->BLOCKED => 'blocked',
   Sys::Async::Virt::Domain->PAUSED  => 'paused',
   Sys::Async::Virt::Domain->SHUTDOWN => 'shut down',
);

await $virt->connect;

use Data::Dumper;
try {
    my $doms = await $virt->list_domains;

    my $dom_id = $doms && $doms->@* && $doms->[0];
    if ($dom_id) {
        my $dom = await $virt->domain_lookup_by_id( $dom_id );
        my $state = await $dom->get_state;
        say Dumper($state);
        say $states{$state->{state}};

        say Dumper(await $dom->memory_stats);
        say Dumper(await $dom->get_disk_errors);
    }
    else {
        say 'There are no active domains';
    }
}
catch ($e) {
    say 'Exception: ' . Dumper($e);
}

await $virt->close;

