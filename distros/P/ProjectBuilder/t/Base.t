#!/usr/bin/perl -w
#
# Tests ProjectBuilder::Base functions

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

# Test::More appropriate version not found so no test will be performed here
if ($@) {
	require Test;
	Test->import();
	plan(tests => 1);
	print "# Faking tests as Test::More is not available in an appropriate version\n";
	ok(1,1);
	exit(0);
}

my $nt = 0;
my $test = {
	# Full URI
	"svn+ssh://account\@machine.sdom.tld:8080/path/to/file" => ["svn+ssh","account","machine.sdom.tld","8080","/path/to/file"],
	# Partial URI
	"http://machine2/path1/to/anotherfile" => ["http","","machine2","","/path1/to/anotherfile"],
	};

my ($scheme, $account, $host, $port, $path);
foreach my $uri (keys %$test) {
	($scheme, $account, $host, $port, $path) = pb_get_uri($uri);

	is($scheme, $test->{$uri}[0], "pb_get_uri Test protocol $uri");
	$nt++;

	is($account, $test->{$uri}[1], "pb_get_uri Test account $uri");
	$nt++;
	
	is($host, $test->{$uri}[2], "pb_get_uri Test host $uri");
	$nt++;
	
	is($port, $test->{$uri}[3], "pb_get_uri Test port $uri");
	$nt++;
	
	is($path, $test->{$uri}[4], "pb_get_uri Test path $uri");
	$nt++;
}

$ENV{'TMPDIR'} = "/tmp";
pb_temp_init();
like($ENV{'PBTMP'}, qr|/tmp/pb\.[0-9A-z]+|, "pb_temp_init Test");
$nt++;

my $content = "This is  content with TABs 	 and spaces and \ncarriage returns\n";
open(FILE,"> $ENV{'PBTMP'}/test") || die "Unable to create temp file";
print FILE $content;
close(FILE);

my $cnt = pb_get_content("$ENV{'PBTMP'}/test");
is($cnt, $content, "pb_get_content Test");
$nt++;

done_testing($nt);
