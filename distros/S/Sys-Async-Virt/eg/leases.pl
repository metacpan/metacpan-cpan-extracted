#!/usr/bin/perl

use v5.20;
use warnings;
use experimental 'signatures';
use Future::AsyncAwait;
use Feature::Compat::Try;

use Future::IO;
use Log::Any qw($log);
use Log::Any::Adapter;
use Log::Any::Adapter::Stdout;
use Sys::Async::Virt;

Log::Any::Adapter->set('Stdout', log_level => 'trace');

my $virt = Sys::Async::Virt->new(
    url => 'qemu:///system'
    );
$log->trace( 'Created libvirt client application layer' );

async sub main() {
    await $virt->connect;

    use Data::Dumper;
    try {
        my $nets = await $virt->list_networks;
        my $net_name = $nets && $nets->@* && $nets->[0];

        if ($net_name) {
            my $net = await $virt->network_lookup_by_name( $net_name );
            my $rv = await $net->get_dhcp_leases( undef );
            say '';
            say '';
            say Dumper($rv);
        }
    }
    catch ($e) {
        say 'Exception: ' . Dumper($e);
    }

    await $virt->close;
    $virt->stop;
}

await Future->needs_all(
    Future::IO->sleep(1), # work around some futures not having ->await()
    $virt->run,
    main()
    );
