#!/usr/bin/perl

use lib qw(../lib);

use strict;
#use warnings FATAL => "all";

use POE qw(TIKC);

$|++;

POE::TIKC->create_client();

POE::Session->create(
	inline_states => {
	    _start => sub {
			my ($kernel, $heap) = @_[KERNEL, HEAP];
	
			$kernel->alias_set("client");
			$kernel->yield('do_test');	
	    },
		_default => sub {
			my ($kernel, $heap, $event, $arg) = @_[KERNEL, HEAP, ARG0, ARG1];
			return undef if ($event =~ m/^_/);
			require Data::Dumper;
			print "client: ".Data::Dumper->Dump([\@{splice(@_,ARG1)}]);
			return undef;
		},
		do_test => sub {
			my ($kernel, $heap) = @_[KERNEL, HEAP];
			$kernel->delay_set(do_test => 6);
			return unless ($POE::TIKC::connected);
			$heap->{count}++;
			print "Asking server to solve $heap->{count} + $heap->{count}\n";
			$kernel->post(server => add_values => $heap->{count} => $heap->{count});
		},
		what_time => sub {
			$_[KERNEL]->post(server => time_results => scalar(localtime()));
		},
		add_results => sub {
			print "result $_[ARG0]\n";
		},
	}
);

$poe_kernel->run();

1;
