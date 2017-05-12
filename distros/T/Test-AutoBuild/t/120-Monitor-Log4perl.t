# -*- perl -*-

use Test::More tests => 2;
use warnings;
use strict;
use Log::Log4perl;

Log::Log4perl::init("t/log4perl.conf");

BEGIN {
  use_ok("Test::AutoBuild::Monitor::Log4perl") or die;
}


TEST_ONE: {
  my $monitor = Test::AutoBuild::Monitor::Log4perl->new(name => "log4pler",
							label => "Send to log4perl appenders");
  isa_ok($monitor, "Test::AutoBuild::Monitor::Log4perl");

  $monitor->notify("beginStage", "foo", "Foo 'eek' wizz\\n");
  $monitor->notify("endStage", "foo");
}
