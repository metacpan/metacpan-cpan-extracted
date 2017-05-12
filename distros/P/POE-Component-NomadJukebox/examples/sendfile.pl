#!/usr/bin/perl

$|++;

use POE qw(Component::NomadJukebox);

die "$0 <file>\n" unless (-e $ARGV[0]);

POE::Session->create(
	inline_states => {
		_start => sub {
			my ($kernel, $heap) = @_[KERNEL, HEAP];
			
			POE::Component::NomadJukebox->create({ alias => 'njb' });
		},
		njb_started => sub {
			my ($kernel, $heap) = @_[KERNEL, HEAP];
			
			$kernel->post(njb => 'discover');
		},
		njb_discover => sub {
			my ($kernel, $heap, $dev) = @_[KERNEL, HEAP, ARG0];

			unless (ref($dev)) {
				print "failed to find nomad\n";
				$kernel->post(njb => 'shutdown');
				return;
			}
		
			print "opening $dev->[0]->{DEVID}\n";
		
			$kernel->post(njb => 'open' => $dev->[0]->{DEVID});
		},
		njb_opened => sub {
			my ($kernel, $heap) = @_[KERNEL, HEAP];
			
			if ($_[ARG1]) {
				print "opened ".ref($_[ARG1])."\n";
				$kernel->post(njb => send_file => { FILE => $ARGV[0], NAME => $ARGV[0] }) ;
			} else {
				$kernel->post(njb => 'shutdown');
			}
		},
		njb_send_file => sub {
			my ($kernel, $heap) = @_[KERNEL, HEAP];
		
			$kernel->post(njb => 'shutdown');
		
			unless ($_[ARG1]) {
				print "send failed ".$_[ARG2]."\n";
				return;
			}
			
			print "\nsent ok, fileid:$_[ARG1]\n";
		},
		njb_closed => sub {
			print "closed\n";
		},
		njb_progress => sub {
			my ($sofar, $total) = @_[ARG0,ARG1];
			print "[$sofar/$total]\n";
		},
	}
);

$poe_kernel->run();
