package Net::OICQ::Event;

# $Id: Event.pm,v 1.2 2007/02/01 22:07:16 tans Exp $

# Copyright (c) 2003 - 2006 Shufeng Tan.  All rights reserved.
# 
# This package is free software and is provided "as is" without express
# or implied warranty.  It may be used, redistributed and/or modified
# under the terms of the Perl Artistic License (see
# http://www.perl.com/perl/misc/Artistic.html)

use strict;
use warnings;
use Carp;

eval "no encoding; use bytes;" if $] >= 5.008;

our $AUTOLOAD;

sub client_ver {
	substr(shift->{Header}, 1, 2)
}

sub cmdcode {
	substr(shift->{Header}, 3, 2)
}

sub seq {
	substr(shift->{Header}, 5, 2)
}

sub cmd {
	my $cmdcode = cmdcode(@_);
	$Net::OICQ::Cmd{$cmdcode} or '0x'.unpack('H*', $cmdcode)
}

# $event->process() checks if an event is an ACK to a previous event,
# or a duplicate to be ignored, or a new event to be added to the queue

sub process {
	my ($self) = @_;
	my $oicq = $self->{OICQ};
	my $queue = $oicq->{EventQueue};
	my $seq = $self->seq;
	my $cmdcode = $self->cmdcode;
	my $event;
	foreach my $e (@$queue) {
		if ($e->seq eq $seq and $e->cmdcode eq $cmdcode) {
			return if ref($e) eq ref($event);
			$event = $e;
			last;
		}
	}

	if (defined($event)) {
		my $cmd = $self->cmd;
		my $seq_hex = unpack('H*', $seq);
		if ($event->{Ack}) {
			return unless $oicq->{Debug};
			$oicq->log_t("$cmd seq 0x$seq_hex was ACK'ed at ",
				substr(localtime($event->{Ack}), 4, 16));
			return;
		} elsif (ref($self) eq ref($event)) {
			# Duplicate packet such as recv_msg, recv_service_msg
			return unless $oicq->{Debug};
			$oicq->log_t("$cmd seq 0x$seq_hex is a dupe");
			return;
		} else {
			$event->{Ack} = time;
			if ($oicq->{Debug}) {
				$oicq->log_t("ACK $cmd seq 0x$seq_hex");
			}
		}
	}

	push @$queue, $self;
	shift @$queue if @$queue > $oicq->{EventQueueSize};
	return 1;
}

sub AUTOLOAD {
	my ($self) = @_;
	my $type = ref($self) or croak "$self is not an object";
	my $oicq = $self->{OICQ};
	croak "$self is not a Net::OICQ::Event object\n" unless defined $oicq;
	my $name = $AUTOLOAD;
	$name =~ s/.*://;
	return if $name eq 'DESTROY';
	my $cmdcode = $self->cmdcode;
	my $seq = $self->seq;
	my $cmd = $self->cmd;
	my $text = sprintf("%s %s(0x%s) %s AUTOLOAD $name\n%s",
			substr(localtime($self->{Time}), 4, 15),
			$cmd, unpack('H*', $cmdcode),
			$type =~ /Client/ ? unpack('N', $self->uid) : "",
			$oicq->hexdump($self->{Data}));
	$oicq->log_t($text) if $oicq->{Debug};
	return;
}

# This method should never croak now that we have AUTOLOAD

sub parse {
	my ($self) = @_;
	my $cmd = $self->cmd;
	return unless defined $cmd;
	$self->$cmd;
}

sub dump {
	my ($self) = @_;
	my $ref = ref($self);
	my $res = sprintf "%s $ref %s 0x%s\n", substr(localtime($self->{Time}), 4, 15),
			$self->cmd, unpack("H*", $self->seq);
	foreach my $attr (keys %$self) {
		next if $attr =~ /^(?:Data|Time|Header|OICQ)$/;
		$res .= "  $attr: ";
		my $value = $self->{$attr};
		if (ref($value) eq 'ARRAY') {
			$res .= '[' . join(', ', @$value) . "]\n";
		} elsif (ref($value) eq 'HASH') {
			foreach my $k (keys %$value) {
				$res .= "    $k: $value->{$k}\n";
			}
		} else {
			$res .= "$value\n";
		}
	}
	return $res;
}

1
