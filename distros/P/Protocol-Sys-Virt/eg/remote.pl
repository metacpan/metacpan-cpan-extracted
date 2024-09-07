#!/usr/bin/env perl

use v5.14;
use warnings;

use lib 'lib';
use Protocol::Sys::Virt::Remote;
use Protocol::Sys::Virt::Transport;

my $protocol = 'Protocol::Sys::Virt::Remote::XDR';
my $transport_xdr = 'Protocol::Sys::Virt::Transport::XDR';

use Carp qw(croak cluck);
use Carp::Always;
use IO::Async::Loop;
use IO::Async::Stream;
use Future::AsyncAwait;
use Log::Any qw($log);
use Log::Any::Adapter;
use Log::Any::Adapter::Stdout;

Log::Any::Adapter->set('Stdout', log_level => 'trace');

my $loop = IO::Async::Loop->new;

my $transport;
my $remote;
my $prot = 'Protocol::Sys::Virt::Remote::XDR';

use JSON::PP;
my $json = JSON::PP->new->canonical(1);
sub handle_reply {
    my (%args) = @_;
    my $proc = $args{header}->{proc};

    say 'header: ' . $json->encode( $args{header} );
    say $json->encode( $args{error} ) if $args{error};
#    say Dumper( $args{data} );
    if ($proc == $prot->PROC_CONNECT_OPEN) {
#        $remote->call( $prot->PROC_CONNECT_LIST_ALL_DOMAINS,
#                       { need_results => 99, flags => 0 } );
        $remote->call( $prot->PROC_CONNECT_LIST_ALL_STORAGE_POOLS,
                       { need_results => 99, flags => 0 } );
        return;
    }
    if ($proc == $prot->PROC_CONNECT_LIST_ALL_DOMAINS) {
#        $remote->call( $prot->PROC_DOMAIN_CREATE,
#                       { dom => $args{data}->{domains}->[1] } );
        return;
    }
    if ($proc == $prot->PROC_CONNECT_LIST_ALL_STORAGE_POOLS) {
        my $pool = ${ $args{data}->{pools} }[0];
        $remote->call( $prot->PROC_STORAGE_POOL_LIST_ALL_VOLUMES,
                       { pool => $pool, need_results => 99, flags => 0 } );
    }
    if ($proc == $prot->PROC_STORAGE_POOL_LIST_ALL_VOLUMES) {
        # my $dl;
        # for my $v ( @{ $args{data}->{vols} } ) {
        #     $dl = $v if $v->{name} eq 'releaser.qcow2';
        # }
        # say 'reading: ' . Dumper( $dl );
        # $remote->call( $prot->PROC_STORAGE_VOL_DOWNLOAD,
        #                { vol => $dl, offset => 0, length => 0, flags => 0 } );
    }
    if ($proc == $prot->PROC_STORAGE_VOL_DOWNLOAD) {
        say "Starting download!";
    }
}

sub handle_stream {
    my (%args) = @_;

    say 'header(stream): ' . $json->encode( $args{header} );
    say $json->encode( $args{error} ) if $args{error};

    my $len = length( $args{data} // '' );
    say 'length: ' . $len;
    if ($len == 0) {
        $remote->stream( $args{header}->{proc},
                         $args{header}->{serial},
                         #                     $transport_xdr->CONTINUE);
                         ($len>0) ? $transport_xdr->CONTINUE : $transport_xdr->OK );
    }
}

sub start_transport {
    my ($stream) = @_;
    $transport = Protocol::Sys::Virt::Transport->new(
        role => 'client',
        on_send => sub {
            my $opaque = shift;
            while (my $data = shift) {
                $log->trace("Writing data... " . length($data));
                $log->trace(unpack("H*", $data));
                $stream->write($data);
            }
            $log->trace("Writing data (finished)");

            return $opaque;
        });
}

sub start_remote {
    $remote = Protocol::Sys::Virt::Remote->new(
        role => 'client',
        on_reply => \&handle_reply,
        on_stream => \&handle_stream,
        );
    $remote->register($transport);
}

sub auth_complete {
    say "Authenticated!";
    $remote->call( $prot->PROC_CONNECT_OPEN,
                   { name => 'qemu:///system', flags => 0 } );
}

my $sock = await $loop->connect(
    addr => {
        family => 'unix',
        socktype => 'stream',
        path => '/run/libvirt/libvirt-sock'
    });
my $stream = IO::Async::Stream->new(
    handle => $sock,
    on_read => sub { 0 } # don't consume data; we'll use 'read_exactly'
    );
$loop->add( $stream );
start_transport($stream);
start_remote;

do {
    my $data;
    my $eof;

    $remote->start_auth($protocol->AUTH_NONE, on_complete => \&auth_complete);
    while (not $eof) {
        $transport->receive($data);
        my ($len, $type) = $transport->need;
        die "Unexpected type $type" unless $type eq 'data';
        $log->trace("Starting socket read... $len");
        ($data, $eof) = await $stream->read_exactly( $len );
        $log->trace("Socket read (finished)");
    }
};

close $sock;
