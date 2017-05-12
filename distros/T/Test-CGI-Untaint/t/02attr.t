#!/usr/bin/perl -w

###
# testing local extraction handler
###

package BuffyTheVampireSlayer::CGI::Untaint::slayer;
use base qw(CGI::Untaint::object);
use strict;

# define the regex
sub _untaint_re { qr/(Buffy|Kendra|Faith)/i };

# fool perl that we've loaded properly
# will this work on windows?
$INC{"BuffyTheVampireSlayer/CGI/Untaint/slayer.pm"} = 1;

####
# tests
####

use Test::More tests => 2;
use Test::Builder::Tester;
use Test::CGI::Untaint qw(:all);

# set the config path to BuffyTheVampireSlayer.  This way the slayer
# can be loaded, and by loading it we're testing config_vars works
# okay
config_vars({ INCLUDE_PATH => "BuffyTheVampireSlayer" });

# okay, now can we load slayer from that class?
test_out("ok 1 - 'buffy' extractable as slayer");
is_extractable("buffy","buffy","slayer");
test_test("setting attributes works");

# check if we config config_vars with something odd it
# fails correctly with a nice error message

SKIP:
{
  # load test exception at compile time
  my $no_test_exception;
  BEGIN {
   eval { require Test::Exception; Test::Exception->import };
   $no_test_exception = $@;
  }

  # didn't load test exception?  skip
  if ($no_test_exception) { skip "No Test::Exception", 1 }

  throws_ok
    { config_vars("Argument to 'config_vars' must be a hashref") }
    qr/Argument to 'config_vars' must be a hashref/,
    "dies right";
}

