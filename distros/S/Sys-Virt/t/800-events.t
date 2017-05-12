# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 23;

my $URI = "test:///default";
my $DOM = "test";

BEGIN {
        use_ok('Sys::Virt');
}


package Sys::Virt::Event::Simple;

use Time::HiRes qw(gettimeofday);

use base qw(Sys::Virt::Event);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

    $self->{nexthandle} = 1;
    $self->{handles} = [];
    $self->{nexttimeout} = 1;
    $self->{timeouts} = [];

    bless $self, $class;

    $self->register;

    return $self;
}

sub _now {
    my $self;
    my @now = gettimeofday;
    return $now[0] * 1000 + (($now[1] - ($now[1] % 1000)) / 1000);
}

sub _bits {
    my $self = shift;
    my $event = shift;
    my $vec = '';

    my $count = 0;
    foreach my $handle (@{$self->{handles}}) {
        next unless $handle->{events} & $event;

        $count++;
        vec($vec, $handle->{fd}, 1) = 1;
    }
    return ($vec, $count);
}


sub run_once {
    my $self = shift;

    my ($ri, $ric) = $self->_bits(Sys::Virt::Event::HANDLE_READABLE);
    my ($wi, $wic) = $self->_bits(Sys::Virt::Event::HANDLE_WRITABLE);
    my ($ei, $eic) = $self->_bits(Sys::Virt::Event::HANDLE_READABLE |
				  Sys::Virt::Event::HANDLE_WRITABLE);
    my $timeout = $self->_timeout($self->_now);

    if (!$ric && !$wic && !$eic && !(defined $timeout)) {
        return;
    }

    my ($ro, $wo, $eo);
    my $n = select($ro=$ri,$wo=$wi,$eo=$ei,
		   (defined $timeout ? ($timeout ? $timeout/1000 : 0) : undef));

    if ($n) {
	$self->_dispatch_handles($ro, $wo, $eo);
    }
    $self->_dispatch_timeouts($self->_now);

    return 1;
}

sub run {
    my $self = shift;

    $self->{shutdown} = 0;
    while (!$self->{shutdown}) {
	$self->_run_once();
    }
}


sub _dispatch_handles {
    my $self = shift;
    my $ro = shift;
    my $wo = shift;
    my $eo = shift;

    foreach my $handle (@{$self->{handles}}) {
	my $events = 0;
	if (vec($ro, $handle->{fd}, 1)) {
	    $events |= Sys::Virt::Event::HANDLE_READABLE;
	}
	if (vec($wo, $handle->{fd}, 1)) {
	    $events |= Sys::Virt::Event::HANDLE_WRITABLE;
	}
	if (vec($eo, $handle->{fd}, 1)) {
	    $events |= Sys::Virt::Event::HANDLE_ERROR;
	}

	if ($events) {
	    $self->_run_handle_callback($handle->{watch},
					$handle->{fd},
					$events,
					$handle->{cb},
					$handle->{opaque});
	}
    }
}

sub _timeout {
    my $self = shift;
    my $now = shift;

    my $ret = undef;
    foreach my $timeout (@{$self->{timeouts}}) {
	if ($timeout->{interval} != -1) {
	    my $wait = $timeout->{expiresAt} - $now;
	    $wait = 0 if $wait < 0;
	    $ret = $wait if !defined($ret)  || $wait < $ret;
	}
    }
    return $ret;
}


sub _dispatch_timeouts {
    my $self = shift;
    my $now = shift;

    foreach my $timeout (@{$self->{timeouts}}) {
	if ($timeout->{interval} != -1 &&
	    $now >= $timeout->{expiresAt}) {

	    $self->_run_timeout_callback($timeout->{timer},
					 $timeout->{cb},
					 $timeout->{opaque});
	    $timeout->{expiresAt} = $now + $timeout->{interval};
	}
    }
}

sub add_handle {
    my $self = shift;
    my $fd = shift;
    my $events = shift;
    my $cb = shift;
    my $opaque = shift;
    my $ff = shift;

    my $handle = {
	fd => $fd,
	events => $events,
	cb => $cb,
	opaque => $opaque,
	ff => $ff,
	watch => $self->{nexthandle}++,
    };

    push @{$self->{handles}}, $handle;

    return $handle->{watch};
}

sub update_handle {
    my $self = shift;
    my $watch = shift;
    my $events = shift;

    my @handle = grep { $_->{watch} == $watch } @{$self->{handles}};

    $handle[0]->{events} = $events;
}

sub remove_handle {
    my $self = shift;
    my $watch = shift;

    my @handle = grep { $_->{watch} == $watch } @{$self->{handles}};
    my @handles = grep { $_->{watch} != $watch } @{$self->{handles}};
    $self->{handles} = \@handles;

    $self->_free_callback_opaque($handle[0]->{ff},
				 $handle[0]->{opaque});
}

sub add_timeout {
    my $self = shift;
    my $interval = shift;
    my $cb = shift;
    my $opaque = shift;
    my $ff = shift;

    my $timeout = {
	interval => $interval,
	cb => $cb,
	opaque => $opaque,
	ff => $ff,
	timer => $self->{nexttimeout}++,
	expiresAt => $self->_now() + $interval,
    };

    push @{$self->{timeouts}}, $timeout;

    return $timeout->{timer};
}

sub update_timeout {
    my $self = shift;
    my $timer = shift;
    my $interval = shift;

    my @timeout = grep { $_->{timer} == $timer } @{$self->{timeouts}};

    $timeout[0]->{interval} = $interval;
    $timeout[0]->{expiresAt} = $self->_now() + $interval;

}

sub remove_timeout {
    my $self = shift;
    my $timer = shift;

    my @timeout = grep { $_->{timer} == $timer } @{$self->{timeouts}};
    my @timeouts = grep { $_->{timer} != $timer } @{$self->{timeouts}};
    $self->{timeouts} = \@timeouts;

    $self->_free_callback_opaque($timeout[0]->{ff},
				 $timeout[0]->{opaque});
}

package main;

my $ev = Sys::Virt::Event::Simple->new();

my $conn = Sys::Virt->new(uri => $URI);

isa_ok($conn, "Sys::Virt");

my $dom = $conn->get_domain_by_name($DOM);

my @events;

$conn->domain_event_register(
    sub {
	my $con = shift;
	my $dom = shift;
	my $event = shift;
	my $detail = shift;

	push @events, [$con, $dom, $event, $detail];
    });

$dom->destroy;

$ev->run_once();

is(int(@events), 1, "got 1st event");
is($events[0]->[0]->get_uri(), $URI, "got URI");
is($events[0]->[1]->get_name(), $DOM, "got name");
is($events[0]->[2], Sys::Virt::Domain::EVENT_STOPPED, "stopped");
is($events[0]->[3], Sys::Virt::Domain::EVENT_STOPPED_DESTROYED, "destroy");


$dom->create;

$ev->run_once();

is(int(@events), 2, "got 2nd event");
is($events[1]->[0]->get_uri(), $URI, "got URI");
is($events[1]->[1]->get_name(), $DOM, "got name");
is($events[1]->[2], Sys::Virt::Domain::EVENT_STARTED, "started");
is($events[1]->[3], Sys::Virt::Domain::EVENT_STARTED_BOOTED, "booted");

$conn->domain_event_deregister;

my $id = $conn->domain_event_register_any(
    undef, Sys::Virt::Domain::EVENT_ID_LIFECYCLE,
    sub {
	my $con = shift;
	my $dom = shift;
	my $event = shift;
	my $detail = shift;

	push @events, [$con, $dom, $event, $detail];
    });

$dom->destroy;

$ev->run_once();

is(int(@events), 3, "got 3rd event");
is($events[2]->[0]->get_uri(), $URI, "got URI");
is($events[2]->[1]->get_name(), $DOM, "got name");
is($events[2]->[2], Sys::Virt::Domain::EVENT_STOPPED, "stopped");
is($events[2]->[3], Sys::Virt::Domain::EVENT_STOPPED_DESTROYED, "destroy");


$dom->create;

$ev->run_once();

is(int(@events), 4, "got 4th event");
is($events[3]->[0]->get_uri(), $URI, "got URI");
is($events[3]->[1]->get_name(), $DOM, "got name");
is($events[3]->[2], Sys::Virt::Domain::EVENT_STARTED, "started");
is($events[3]->[3], Sys::Virt::Domain::EVENT_STARTED_BOOTED, "booted");

$conn->domain_event_deregister_any($id);

$dom->destroy;
$ev->run_once();

is(int(@events), 4, "no more events");

$conn = undef;
