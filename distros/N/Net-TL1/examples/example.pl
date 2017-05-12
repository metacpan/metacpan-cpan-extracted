#!/usr/bin/perl -w

# This test script will receive statistics on a the  ADSL2+ ports of a
# linecard in an Alcatel ASAM 7301 dslam.

use strict;

use Net::TL1::Alcatel;

# The constants below need to be modified to match your environment
use constant TL1_user => 'user';
use constant TL1_password => 'pwd';
use constant TL1_gateway => '10.0.0.1';

{
	my $dslam = 'PR-DSLAM1';
	my $slot = 2;

	my $tl1 = new Net::TL1::Alcatel ({Host => TL1_gateway, Debug => 0});

	$tl1->Login({Target => $dslam, User => TL1_user, Password => TL1_password});

	# Execute the `reptopstatxline' TL1 command on the DSLAM for ports 1 to 48
	# on the linecard in slot 2
 	my $ctag = $tl1->reptopstatxline({Target => $dslam, Rack => 1,
                Shelf => 1, Slot => $slot, 'FirstCircuit' => 1,
                'LastCircuit' => 48});

	# The reptopstatxline method already parses all the output into a hash
	# so that we don't have to do it
	my $ref = $tl1->get_hashref($ctag);

	# We only want to know about XDSL info from rack 1, shelf 1, slot 2
	$ref = $$ref{XDSL}{1}{1}{$slot};

	# Let's retrieve the info about the ports
	foreach my $circuit (1 .. 48) {
		my $portref = $$ref{$circuit};
		foreach my $key (keys %{$portref}) {
			print "$key: $$portref{$key}\t";
		}
		print "\n";
	}

	# Here we close the TL1 session
	$tl1->Logout({Target => $dslam});
}
