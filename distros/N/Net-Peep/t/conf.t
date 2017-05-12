#!/usr/bin/perl

# Run with
#
# perl -I../blib/lib -e 'use Test::Harness qw(&runtests $verbose); $verbose=0; runtests @ARGV;' conf.t

# Tests Peep configuration parsing and the client configuration process

BEGIN { $Test::Harness::verbose++; $|++; print "1..3\n"; }
END {print "not ok\n", exit 1 unless $loaded;}

use Net::Peep::Log;
use Net::Peep::Conf;
use Net::Peep::Parser;
use Net::Peep::Client::Logparser;

$loaded = 1;

print "ok\n";

$Net::Peep::Log::debug = 0;

my ($conf,$parser);

eval {

	$conf = new Net::Peep::Conf;
	$parser = new Net::Peep::Parser;

};

if ($@) {
	print "not ok:  $@\n";
	exit 1;
} else {
	print "ok\n";
}

$Test::Harness::verbose += 1;
$Net::Peep::Log::debug = 1;

print STDERR "\nTesting Peep configuration file parser:\n";

eval { 

    my $client = new Net::Peep::Client::Logparser;
    $client->initialize();
    $client->parser(sub { my @text = @_; $client->parse(@text); });
    $conf = $client->configure();
    $client->callback(sub { $client->loop(); });

};

if ($@) {
	print STDERR "not ok:  $@";
	exit 1;
} else {
	print "ok\n";
	exit 0;
}

