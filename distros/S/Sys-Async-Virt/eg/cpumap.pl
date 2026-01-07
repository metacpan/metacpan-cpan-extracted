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
    $virt->stop;
}


await Future->wait_all(
    Future::IO->sleep(1), # work around some futures not having ->await()
    $virt->run,
    main()
    );
