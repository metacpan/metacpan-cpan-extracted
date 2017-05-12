#!/usr/bin/perl

use POE qw(Component::NomadJukebox);

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
			my ($kernel, $heap, $dev, $names) = @_[KERNEL, HEAP, ARG0, ARG1];

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
				$kernel->post(njb => 'track_list' => $ARGV[0]);
			} else {
				$kernel->post(njb => 'shutdown');
			}
		},
		njb_track_list => sub {
			my ($kernel, $heap, $tracks) = @_[KERNEL, HEAP, ARG0];
	
			unless (ref($tracks) eq 'ARRAY') {
				print "Failed to get tracks\n";
				return;
			}
			print "Got ".scalar(@$tracks)." tracks\n";
			require Data::Dumper;
			print Data::Dumper->Dump([$tracks]);
			$kernel->post(njb => 'shutdown');
		},
		njb_closed => sub {
			my ($kernel, $heap) = @_[KERNEL, HEAP];
			
			print "closed\n";
		},
	}
);

$poe_kernel->run();
