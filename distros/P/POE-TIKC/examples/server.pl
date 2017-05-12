#!/usr/bin/perl

use lib qw(../lib);

use strict;
#use warnings FATAL => "all";

use POE qw(TIKC);

$|++;

POE::TIKC->create_server();

POE::Session->create(
	inline_states => {
	    _start => sub {
			my ($kernel, $heap) = @_[KERNEL, HEAP];
	
			$kernel->alias_set("server");
			$kernel->delay_set(alias_list => 5);
			$kernel->yield('do_test');	
		},
		_default => sub {
			my ($kernel, $heap, $event) = @_[KERNEL, HEAP, ARG0];
			return undef if ($event =~ m/^_/);
			require Data::Dumper;
			print "server: ".Data::Dumper->Dump([\@{splice(@_,ARG1)}]);
			return undef;
		},
		do_test => sub {
			my ($kernel, $heap) = @_[KERNEL, HEAP];
			$kernel->delay_set(do_test => 5);
			return unless ($POE::TIKC::connected);
			print "Asking client for the time\n";
			$kernel->post(client => 'what_time');
		},
		add_values => sub {
			my ($kernel, $heap, $value) = @_[KERNEL, HEAP, ARG0];
			$kernel->post(client => add_results => ($value+$value) => { extra => 1, data => 2 });
		},
		time_results => sub {
			print "The time is $_[ARG0]\n";
		},
		alias_list => sub {
			my ($kernel, $heap) = @_[KERNEL, HEAP];
			
			my @aliases;
			my $kr_sessions = $POE::Kernel::poe_kernel->[POE::Kernel::KR_SESSIONS];
			foreach my $key ( keys %$kr_sessions ) {
				next if $key =~ /POE::Kernel/;
				foreach my $a ($kernel->alias_list($kr_sessions->{$key}->[0])) {
					next if ($a =~ m/^_tikc/);
					push(@aliases,$a);
				}
			}
			print "(s) aliases: ".join(',',@aliases)."\n";
			$kernel->delay_set(alias_list => 5);
		},
	}
);

$poe_kernel->run();

1;
