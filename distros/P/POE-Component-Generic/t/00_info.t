#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use_ok('POE');

eval "use POE::Test::Loops";
$POE::Test::Loops::VERSION = "doesn't seem to be installed" if $@;

# idea from Test::Harness, thanks!
diag(
  "POE $POE::VERSION, ",
  "POE::Test::Loops $POE::Test::Loops::VERSION, ",
  "Perl $], ",
  "$^X on $^O"
);
