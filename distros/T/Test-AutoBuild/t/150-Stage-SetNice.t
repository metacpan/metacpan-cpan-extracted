# -*- perl -*-

use Test::More tests => 9;
use warnings;
use strict;
use Log::Log4perl;
use BSD::Resource;

Log::Log4perl::init("t/log4perl.conf");

BEGIN {
  use_ok("Test::AutoBuild::Stage::SetNice") or die;
  use_ok("Test::AutoBuild::Runtime") or die;
  use_ok("Test::AutoBuild::Counter::Time") or die;
}

my $runtime = Test::AutoBuild::Runtime->new(counter => Test::AutoBuild::Counter::Time->new());

TEST_DEFAULTS: {
  my $stage = Test::AutoBuild::Stage::SetNice->new(name => "setnice",
						   label => "Renice builder process");
  is($stage->option("nice-level"), 19, "nice level defaults to 19");
}

TEST_LOW: {
  my $stage = Test::AutoBuild::Stage::SetNice->new(name => "setnice",
						   label => "Renice builder process",
						   options => {
							       'nice-level' => 19
							      });
  isa_ok($stage, "Test::AutoBuild::Stage::SetNice");

  $stage->run($runtime);
  ok($stage->succeeded(), "stage succeeeded");

  my $prio = getpriority PRIO_PROCESS, $$;
  ok(defined $prio && $prio == 19, "priority is 19");
}

TEST_HIGH: {
  my $stage = Test::AutoBuild::Stage::SetNice->new(name => "setnice",
						   label => "Renice builder process",
						   options => {
							       'nice-level' => -15
							      });
  isa_ok($stage, "Test::AutoBuild::Stage::SetNice");

  $stage->run($runtime);
  # If someone happens to be running this test as root
  # then it'll actually succeeed - but not if under
  # debian's fakeroot in which case it'll still fail
  if ($< == 0 && ! exists $ENV{FAKED_MODE}) {
    ok($stage->succeeded(), "stage succeeeded");
  } else {
    ok($stage->failed(), "stage failed");
  }
}
