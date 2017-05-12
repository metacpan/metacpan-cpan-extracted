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
				$kernel->post(njb => 'disk_usage');
			} else {
				$kernel->post(njb => 'shutdown');
			}
		},
		njb_disk_usage => sub {
			my ($kernel, $heap, $info) = @_[KERNEL, HEAP, ARG0];
		
			unless (ref($info) eq 'HASH') {
				print "Failed to get disk usage\n";
				return;
			}
			my $used = $info->{TOTAL} - $info->{FREE};
			print "Total:$info->{TOTAL}/Free:$info->{FREE}/Used:$used\n";
			$kernel->post(njb => 'file_list');
			$kernel->post(njb => 'shutdown');
		},
		njb_file_list => sub {
			my ($kernel, $heap, $tracks) = @_[KERNEL, HEAP, ARG0];
	
			unless (ref($tracks) eq 'ARRAY') {
				print "Failed to get files\n";
				return;
			}
			print "Got ".scalar(@$tracks)." files\n";
			require Data::Dumper;
			print Data::Dumper->Dump([$tracks]);
			$kernel->post(njb => 'shutdown');
			return;
		},
		njb_closed => sub {
			my ($kernel, $heap) = @_[KERNEL, HEAP];
			
			print "closed\n";
		},
	}
);

$poe_kernel->run();
