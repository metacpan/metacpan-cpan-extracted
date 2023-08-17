#!/usr/bin/perl

use strict;
use warnings;
use 5.14.0;

use Data::Dumper;

use IO::Async::Loop;
use Log::Any::Adapter ('Stdout', log_level => 'info' );
use Log::Any '$log', default_adapter => 'Stdout';

use Sys::Virt;
use Sys::Virt::Event;
use Sys::Virt::IO::Async;
use Sys::Virt::IO::Async::EventImpl;

my $impl = Sys::Virt::IO::Async::EventImpl->new;
Sys::Virt::Event::register($impl);

my $loop = IO::Async::Loop->new;
$loop->add( $impl );

my $conn = Sys::Virt::IO::Async->new(
    virt => Sys::Virt->new( uri => 'qemu:///system' ),
    on_domain_change => sub {
        my ($conn, $dom, @args) = @_;
        say "State change for " . $dom->get_name . ": " . Dumper(\@args);
    });
$impl->add_child( $conn );


$log->info( 'Initialized, starting loop' );
IO::Async::Loop->new->run;

# now, start or stop a VM to see the callback receiving updates.
