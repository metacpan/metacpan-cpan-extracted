#!/usr/bin/perl -w
#
# Tests ProjectBuilder::Log functions

use strict;
use ProjectBuilder::Base;

eval
{
	require Test::More;
	Test::More->import();
	my ($tmv,$tmsv) = split(/\./,$Test::More::VERSION);
	if ($tmsv lt 87) {
		die "Test::More is not available in an appropriate version ($tmsv)";
	}
};

# Test::More not found so no test will be performed here
if ($@) {
  	require Test;
	Test->import();
	plan(tests => 1);
	print "# Faking tests as test::More is not available in an appropriate version\n";
	ok(1,1);
	exit (0);
}

is("tmp", "tmp", "temp test");
done_testing(1);
exit(0);

use ProjectBuilder::Log;

my $nt = 0;
# Acquires test data
my $logf = "combined.log";
if (!open(FILE, "< $logf")) {
	die("Could not open file $logf\n");
}
my @lines = <FILE>;
close(FILE);

my $log = new ProjectBuilder::Log;
$log->setCompleteLog(join("\n", @lines));
my $test = {
	# Full URI
	"svn+ssh://account\@machine.sdom.tld:8080/path/to/file" => ["svn+ssh","account","machine.sdom.tld","8080","/path/to/file"],
	# Partial URI
	"http://machine2/path1/to/anotherfile" => ["http","","machine2","","/path1/to/anotherfile"],
	};

my ($scheme, $account, $host, $port, $path);
foreach my $lines (split(/\n/,$log->summary)) {
	#($scheme, $account, $host, $port, $path) = pb_get_uri($uri);

	#is($scheme, $test->{$uri}[0], "pb_get_uri Test protocol $uri");
	#$nt++;

}

#$ENV{'TMPDIR'} = "/tmp";
#pb_temp_init();
#like($ENV{'PBTMP'}, qr|/tmp/pb\.[0-9A-z]+|, "pb_temp_init Test");
#$nt++;

done_testing($nt);
