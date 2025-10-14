#!/usr/bin/perl

use v5.20;
use warnings;
use experimental 'signatures';
use Future::AsyncAwait;
use Feature::Compat::Try;
use Scalar::Util qw(blessed reftype);

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
