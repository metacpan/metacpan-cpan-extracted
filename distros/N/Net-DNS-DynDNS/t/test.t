#! /usr/bin/perl 

use Net::DNS::DynDNS();
use Test::More(tests => 10);
use strict;
use warnings;

eval { require LWP::Protocol::https; };
ok($@ eq '', "Loaded LWP::Protocol::https for secure updates");
SKIP: {
	my $ua = LWP::UserAgent->new( timeout => 10 );
	my $internet_available;
        DOMAIN_NAME: foreach my $domain_name ('google.com', 'yahoo.com', 'duckduckgo.com', 'checkip.dyndns.org', 'search.cpan.org') {
		my $request = HTTP::Request->new('HEAD', 'http://' . $domain_name);
		my $response;
		eval {
			$response = $ua->request($request);
		};
		if ($response) {
			if (($response->is_success()) || ($response->is_redirect())) {
				$internet_available = 1;
				last DOMAIN_NAME;
			}
		}
	}
	if (!$internet_available) {
		skip("No internet connectivity detected", 9);
	}
	my $default_ip;
	eval {
		$default_ip = Net::DNS::DynDNS->default_ip_address();
	} or do {
		chomp $@;
		skip("Failed to get default ip address:$@", 9);
	};
	ok($default_ip, "Discovered current internet address");
	my ($dyn) = new Net::DNS::DynDNS('test', 'test');
	ok($dyn, "Created a new Net::DNS::DynDNS object");
	my ($assigned_ip);
	eval {
		$assigned_ip = Net::DNS::DynDNS->new('test', 'test')->update('test.dyndns.org,test.homeip.net');
	};
	diag($@);
	chomp($@);
	if ($@ =~ /^The hostname specified is blocked for update abuse/) {
		skip("Update abuse has been switched on during initial test", 7);
	} elsif ($@ =~ /^DNS error encountered/) {
		skip("DNS error during initial test", 7);
	} elsif ($@ =~ /^There is a problem or scheduled maintenance on our side/) {
		skip("Server error during initial test", 7);
	} elsif ($@ =~ /^Unknown error/) {
		chomp $@;
		skip("$@", 7);
	}
	ok($assigned_ip, "Assigned new IP address to 'test.dyndns.org' and 'test.homeip.net':$@");
	eval {
		$assigned_ip = $dyn->update('test.homeip.net', $default_ip, { 'wildcard' => 'ON', 'mx' => 'test.homeip.net', 'backmx' => 'YES', 'offline' => 'NO', 'protocol' => 'http' });
	};
	chomp($@);
	if ($@ =~ /^The hostname specified is blocked for update abuse/) {
		skip("Update abuse has been switched on during all options on test", 6);
	} elsif ($@ =~ /^DNS error encountered/) {
		skip("DNS error during all options on test", 6);
	} elsif ($@ =~ /^There is a problem or scheduled maintenance on our side/) {
		skip("Server error during all options on test", 6);
	}
	ok($assigned_ip, "Assigned new IP address to 'test.homeip.net' with every option set, including using the insecure http protocol:$@");
	my $private_ip_address_detected;
	eval {
		$dyn->update('test.homeip.net', '10.1.1.1')
	};
	chomp($@);
	if ($@ =~ /^Bad IP address.  The IP address is in a range that is not publically addressable/) {
		$private_ip_address_detected = 1;
	} elsif ($@ =~ /^The hostname specified is blocked for update abuse/) {
		skip("Update abuse has been switched on during private address update test", 5);
	} elsif ($@ =~ /^DNS error encountered/) {
		skip("DNS error during private address update test", 5);
	} elsif ($@ =~ /^There is a problem or scheduled maintenance on our side/) {
		skip("Server error for private address update test", 5);
	} elsif ($@ =~ /^dyndns.org has forbidden updates until the previous error is corrected/) {
		skip("Server error for private address update test", 5);
	}
	ok($private_ip_address_detected, "Private IP addresses not allowed:$@");
	my $incorrect_password_used;
	eval {
		Net::DNS::DynDNS->new('test', 'wrong_password')->update('test.homeip.net');
	};
	chomp($@);
	if ($@ =~ /^The username and password pair do not match a real user/) {
		$incorrect_password_used = 1;
	} elsif ($@ =~ /^The hostname specified is blocked for update abuse/) {
		skip("Update abuse has been switched on during incorrect password test", 4);
	} elsif ($@ =~ /^DNS error encountered/) {
		skip("DNS error for incorrect password test", 4);
	} elsif ($@ =~ /^There is a problem or scheduled maintenance on our side/) {
		skip("Server error for incorrect password test", 4);
	} elsif ($@ =~ /^dyndns.org has forbidden updates until the previous error is corrected/) {
		skip("Server error for incorrect password test", 4);
	}
	ok ($incorrect_password_used, "Successfully detected that the wrong password has been used:$@");
	$dyn->update_allowed(0); # Fake an error
	eval {
		$dyn->update('test.homeip.net')
	};
	chomp($@);
	ok($@ =~ /^dyndns.org has forbidden updates until the previous error is corrected/, "Do not update after a failure from dyndns.org");
	ok(not($dyn->update_allowed(1)), "Signal that human intervention has allowed the object to make update requests again");
	my $successful_update;
	eval {
		$dyn->update('test.homeip.net');
		$successful_update = 1;
	};
	chomp($@);
	if ($@ =~ /^The hostname specified is blocked for update abuse/) {
		skip("Update abuse has been switched on", 1);
	} elsif ($@ =~ /^DNS error encountered/) {
		skip("DNS error for update of test.homeip.net", 1);
	} elsif ($@ =~ /^There is a problem or scheduled maintenance on our side/) {
		skip("Server error for update of test.homeip.net", 1);
	} elsif ($@ =~ /^dyndns.org has forbidden updates until the previous error is corrected/) {
		skip("Server error for update of test.homeip.net", 1);
	}
	ok($successful_update, "Successful update to dyndns.org");
}
