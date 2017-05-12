# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WMIClient.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 2;
use Net::WMIClient qw(wmiclient);
use Socket;

my $DoNetTests = 1;
my $AuthFile = $ENV{'WMICLIENT_AUTHFILE'};
my $TestHost = $ENV{'WMICLIENT_TESTHOST'};

$DoNetTests = 0 unless ($AuthFile && (-f $AuthFile));
$DoNetTests = 0 unless ($TestHost && (defined(gethostbyname($TestHost))));

SKIP: {

	skip "Not doing network tests", 2 unless ($DoNetTests);

	# Test output with a good command:
	my @params = ("-A", $AuthFile, "//$TestHost", "select * from Win32_ComputerSystem");
	my ($rc, $output) = wmiclient(@params);
	like($output, qr/^CLASS: Win32_ComputerSystem/, "Basic WMI command test");

	# Test output with a bad command:
	@params = ("-A", $AuthFile, "//$TestHost", "select * from Win32_ComputerSyst");
	($rc, $output) = wmiclient(@params);
	ok($output eq "NTSTATUS: NT code 0x80041010 - NT code 0x80041010\n", "Bogus WMI command test");

	# Test output without authentication:
	@params = ("//$TestHost", "select * from Win32_ComputerSystem");
	($rc, $output) = wmiclient(@params);
diag($output);
	ok($output eq "NTSTATUS: NT code 0x80041010 - NT code 0x80041010\n", "Bogus WMI command test");

}

