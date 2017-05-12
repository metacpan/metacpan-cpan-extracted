#! perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..32\n"; }
END {print "not ok 1\n" unless $loaded;}
use Run ':NEW';
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

(new_system 'perl', '-le', 'print "ok $ENV{OK}"')->run({env => {OK => 2}})
  and print "ok 3\n";
(new_system 'perl', '-le', 'print "ok 4"; exit 1')
  ->run({errs => []})		# ignore errs
  or print "ok 5\n";
(new_chain (new_system ('perl', '-le', 'print "ok 6"'),
	    new_system ('perl', '-le', 'print "ok 7"')))->run
  and print "ok 8\n";
(new_and (new_system ('perl', '-le', 'print "ok 9"'),
	  new_system ('perl', '-le', 'print "ok 10"')))->run
  and print "ok 11\n";
(new_and (new_system ('perl', '-le', 'print "ok 12"'),
	  new_system ('perl', '-le', 'print "ok 13"; exit 1')))
  ->run({errs => []})		# ignore errs
  or print "ok 14\n";
(new_and (new_system ('perl', '-le', 'print "ok 15"; exit 1'),
	  new_system ('perl', '-le', 'print "not ok 16"')))
  ->run({errs => []})		# ignore errs
  or print "ok 16\n";
(new_or (new_system ('perl', '-le', 'print "ok 17"; exit 1'),
	 new_system ('perl', '-le', 'print "ok 18"')))
  ->run({errs => []})		# ignore errs
  and print "ok 19\n";
(new_or (new_system ('perl', '-le', 'print "ok 20"'),
	 new_system ('perl', '-le', 'print "not ok 21"')))->run
  and print "ok 21\n";
(new_or (new_system ('perl', '-le', 'print "ok 22"; exit 1'),
	 new_system ('perl', '-le', 'print "ok 23"; exit 1')))
  ->run({errs => []})		# ignore errs
  or print "ok 24\n";

(new_env 
 {OK => 25},
 (new_system 'perl', '-le', 'print "ok $ENV{OK}"'))->run
  and print "ok 26\n";

(new_env 
 {OK => 28},
 (new_chain((new_system 'perl', '-le', '$ENV{OK}--; print "ok $ENV{OK}"'),
	    (new_system 'perl', '-le', 'print "ok $ENV{OK}"'))))->run
  and print "ok 29\n";

(new_env 
 {OK => 31},
 (new_chain( (new_env 
	      {OK => 30},
	      (new_system 'perl', '-le', 'print "ok $ENV{OK}"')),
	     (new_system 'perl', '-le', 'print "ok $ENV{OK}"'))))->run
  and print "ok 32\n";

