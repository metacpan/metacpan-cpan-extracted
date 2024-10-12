#!/usr/bin/perl

use v5.26;
use warnings;
use experimental 'signatures';
use Future::AsyncAwait;
use Feature::Compat::Try;

use Getopt::Long;
use IO::Async::Loop;
use Log::Any qw($log);
use Log::Any::Adapter;
use Log::Any::Adapter::Stdout;
use Scalar::Util qw( blessed );
use Sys::Async::Virt;

use Carp::Always;
use Data::Dumper;

my $url;
my $domain;
my $target_state_name;

sub help {
    say <<~'HELP';
      Usage: wait-domain-state [-c URI] domain state
      Waits for the domain to reach the given state.

      State values:
         none
         running
         blocked
         paused
         shutdown
         shutoff
         crashed
         suspended

      Falls back to the LIBVIRT_DEFAULT_URI environment variable
      when no URI is given.
      HELP
}

Log::Any::Adapter->set('Stdout', log_level => 'error');
GetOptions('c=s' => \$url);

unless (@ARGV == 2) {
    help();
    exit 1;
}

$domain = shift @ARGV;
$target_state_name = shift @ARGV;


my $loop = IO::Async::Loop->new;
my $virt = Sys::Async::Virt->new(
    url => $url // 'qemu:///system',
    );
$loop->add( $virt );
$log->trace( 'Created libvirt client application layer' );

my %states = (
    Sys::Async::Virt::Domain->NOSTATE     => 'no state',
    Sys::Async::Virt::Domain->RUNNING     => 'running',
    Sys::Async::Virt::Domain->BLOCKED     => 'blocked',
    Sys::Async::Virt::Domain->PAUSED      => 'paused',
    Sys::Async::Virt::Domain->SHUTDOWN    => 'shutting down',
    Sys::Async::Virt::Domain->SHUTOFF     => 'shut off',
    Sys::Async::Virt::Domain->CRASHED     => 'crashed',
    Sys::Async::Virt::Domain->PMSUSPENDED => 'suspended',
);

my %state_args = (
    'none'       => Sys::Async::Virt::Domain->NOSTATE,
    'running'    => Sys::Async::Virt::Domain->RUNNING,
    'blocked'    => Sys::Async::Virt::Domain->BLOCKED,
    'paused'     => Sys::Async::Virt::Domain->PAUSED,
    'shutdown'   => Sys::Async::Virt::Domain->SHUTDOWN,
    'shutoff'    => Sys::Async::Virt::Domain->SHUTOFF,
    'crashed'    => Sys::Async::Virt::Domain->CRASHED,
    'suspended'  => Sys::Async::Virt::Domain->PMSUSPENDED,
);


my $target_state = $state_args{$target_state_name};
try {
    await $virt->connect;
    my $dom = await $virt->domain_lookup_by_name( 'releaser' );
    my $cb = await $virt->domain_event_register_any(
        $virt->DOMAIN_EVENT_ID_LIFECYCLE, $dom );

    my $event_f;
    my $state;
    do {
        $event_f = $cb->next_event;
        $state   = await $dom->get_state;
    } while ($event_f->is_ready); # get stable state (i.e. without mixed events)

    say "Current state: $states{$state->{state}}";
    if ($state->{state} != $target_state) {
        while (my $event_data = await $event_f) {
            $state = await $dom->get_state;
            say "Lifecycle event; current state: $states{$state->{state}}";
            if ($state->{state} == $target_state) {
                await $cb->cancel;
            }
            $event_f = $cb->next_event;
        }
    }

    await $virt->close;
}
catch ($e) {
    say "Error: $e";
    exit 1;
}
