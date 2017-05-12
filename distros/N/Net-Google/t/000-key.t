use strict;
use Test::More;

plan tests => 3;

use constant TMPFILE => "./blib/google-api.key";

diag("\n".
     "The Google API web service requires that you provide create a Google Account and obtain a license key\n".
     "This key is then passed with each request you make to the Google servers.\n".
     "If you do not already have a Google Account, you can sign up for one here:\n".
     "http://www.google.com/apis/\n".
     "\n");

diag("Please enter your Google API key:");

my $key = <STDIN>;
chomp $key;

ok($key,"Got Google API key");

open KEY , ">".TMPFILE;

my $file = -f TMPFILE;
ok($file,"Opened tmp file for writing");

print KEY $key;
close KEY;

my $size = -s TMPFILE;
ok($size,"Wrote key to tmp filed");
