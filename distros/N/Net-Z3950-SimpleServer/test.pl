# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Net::Z3950::SimpleServer;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

print "not " if Net::Z3950::SimpleServer::yaz_diag_srw_to_bib1(11) != 107;
print "ok 2\n";

print "not " if Net::Z3950::SimpleServer::yaz_diag_bib1_to_srw(3) != 48;
print "ok 3\n";

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

sub my_init_handler {
	my $href = shift;
	my %log = ();

	$log{"init"} = "Ok";
	$href->{HANDLE} = \%log;
}

sub my_search_handler {
	my $href = shift;
	my %log = %{$href->{HANDLE}};

	$log{"search"} = "Ok";
	$href->{HANDLE} = \%log;
	$href->{HITS} = 1;
}

sub my_fetch_handler {
	my $href = shift;
	my %log = %{$href->{HANDLE}};
	my $record = "<xml><head>Headline</head><body>I am a record</body></xml>";

	$log{"fetch"} = "Ok";
	$href->{HANDLE} = \%log;
	$href->{RECORD} = $record;
	$href->{LEN} = length($record);
	$href->{NUMBER} = 1;
	$href->{BASENAME} = "Test";
}

sub my_close_handler {
	my @services = ("init", "search", "fetch", "close");
	my $href = shift;
	my %log = %{$href->{HANDLE}};
	my $status;
	my $service;
	my $error = 0;

	$log{"close"} = "Ok";

	print "\n-----------------------------------------------\n";
	print "Available Z39.50 services:\n\n";

	foreach $service (@services) {
		print "Called $service: ";
		if (defined($status = $log{$service})) {
			print "$status\n";
		} else {
			print "FAILED!!!\n";
			$error = 1;
		}
	}
	if ($error) {
		print "make test: Failed due to lack of required Z39.50 service\n";
	} else {
		print "\nEverything is ok!\n";
	}
	print "-----------------------------------------------\n";
	print "not " if $error;
	print "ok 4\n";
}


my $socketFile = "/tmp/SimpleServer-test-$$";
my $socket = "unix:$socketFile";

if (!defined($pid = fork() )) {
	die "Cannot fork: $!\n";
} elsif ($pid) {                                        ## Parent launches server
	my $handler = Net::Z3950::SimpleServer->new(
		INIT		=>	\&my_init_handler,
		CLOSE		=>	\&my_close_handler,
		SEARCH		=>      \&my_search_handler,
		FETCH		=>	\&my_fetch_handler);

	$handler->launch_server("test.pl", "-1", $socket);
} else {						## Child starts the client
	sleep(1);
	open(CLIENT, "| yaz-client $socket > /dev/null")
		or die "Couldn't fork client: $!\n";
	print CLIENT "f test\n";
	print CLIENT "s\n";
	print CLIENT "close\n";
	print CLIENT "quit\n";
	close(CLIENT) or die "Couldn't close: $!\n";
	unlink($socketFile);
}
