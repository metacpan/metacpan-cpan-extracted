use strict;
use Test::More;

plan tests => 4;

use constant TMPFILE => "./blib/amazon.credentials";

diag("\n".
     "The Amazon web service requires that you create an\nAccount and obtain a license key and access id\n".
     "This key is then passed with each request you make to the Amazon servers.\n".
     "If you do not already have an Amazon Web Service account,\nyou can sign up for one here:\n".
     "http://www.amazon.com/gp/aws/landing.html\n".
     "\n");

diag("Please enter your Amazon key id:");
my $key = <STDIN>;
chomp $key;

diag("Please enter your Amazon access key:");
my $access_id = <STDIN>;
chomp $access_id;

ok($key,"Got Amazon key id");
ok($access_id, "Got Amazon access key");

unless(length($key) || length($access_id)) {
	diag("Entering debug mode, no authentication given");
}

open AUTH , ">".TMPFILE;

my $file = -f TMPFILE;
ok($file,"Opened tmp file for writing");

print AUTH $key . '|+++|' . $access_id;
close AUTH;

my $size = -s TMPFILE;
ok($size,"Wrote authentication info to tmp file");
