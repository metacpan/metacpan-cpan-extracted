# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use strict;
use vars qw($AUTOLOAD);
use Carp;

use SQL::Generator;

use SQL::Generator::Lang::MYSQL;

#use Object::ObjectList;

my $loaded = 0;
my $lasttest;

BEGIN { $lasttest=1 }

BEGIN { $| = 1; print "1..$lasttest\n"; }
END {print "not ok $lasttest\n" unless $loaded;}

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

printf "ok %d\n", ++$loaded;
