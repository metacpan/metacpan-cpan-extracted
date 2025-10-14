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

await $virt->connect();

use Data::Dumper;
try {
    my $map = await $virt->get_cpu_map();
    say "\n\n" . Dumper( $map );

    my $doms = await $virt->list_domains;
    say "\n\n" . Dumper $doms;

    my $dom_id = $doms && $doms->@* && $doms->[0];
    if ($dom_id) {
        my $dom = await $virt->domain_lookup_by_id( $dom_id );
        my $pins = await $dom->get_vcpus;
        say "\n\n" . Dumper( $pins );
    }
}
catch ($e) {
    say 'Exception: ' . Dumper($e);
}

await $virt->close;
