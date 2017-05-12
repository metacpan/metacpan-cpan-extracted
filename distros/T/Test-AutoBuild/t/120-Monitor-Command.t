# -*- perl -*-

use Test::More tests => 13;
use warnings;
use strict;
use Log::Log4perl;

Log::Log4perl::init("t/log4perl.conf");

BEGIN {
  use_ok("Test::AutoBuild::Monitor::CommandLine") or die;
}


TEST_ONE: {
  my $monitor = Test::AutoBuild::Monitor::CommandLine->new(name => "command",
							   label => "Change process command line");
  isa_ok($monitor, "Test::AutoBuild::Monitor::CommandLine");

  my $cmd = $0;
  $monitor->notify("beginStage", "foo");
  is($0, "$cmd [running foo]", "command line is foo");

  $monitor->notify("beginStage", "bar");
  is($0, "$cmd [running foo->bar]", "command line is foo->bar");

  $monitor->notify("beginBuild", "eek");
  is($0, "$cmd [running foo->bar (eek)]", "command line is foo->bar (eek)");

  $monitor->notify("endBuild", "eek");
  is($0, "$cmd [running foo->bar]", "command line is foo->bar");

  $monitor->notify("completeStage", "bar");
  is($0, "$cmd [running foo]", "command line is foo");

  $monitor->notify("beginStage", "bar");
  is($0, "$cmd [running foo->bar]", "command line is foo->bar");

  $monitor->notify("failStage", "bar");
  is($0, "$cmd [running foo]", "command line is foo");

  $monitor->notify("beginStage", "bar");
  is($0, "$cmd [running foo->bar]", "command line is foo->bar");

  $monitor->notify("abortStage", "bar");
  is($0, "$cmd [running foo]", "command line is foo");

  $monitor->notify("skipStage", "bar");
  is($0, "$cmd [running foo]", "command line is foo");

  $monitor->notify("completeStage", "bar");
  is($0, "$cmd [running ]", "command line is empty");
}
