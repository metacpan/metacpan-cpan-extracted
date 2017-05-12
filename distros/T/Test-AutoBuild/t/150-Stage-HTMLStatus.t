# -*- perl -*-

use Test::More tests => 4;
use warnings;
use strict;
use Log::Log4perl;

Log::Log4perl::init("t/log4perl.conf");

BEGIN {
  use_ok("Test::AutoBuild::Stage::HTMLStatus") or die;
  use_ok("Test::AutoBuild::Runtime") or die;
  use_ok("Test::AutoBuild::Counter::Time") or die;
}

my $runtime = Test::AutoBuild::Runtime->new(counter => Test::AutoBuild::Counter::Time->new());

TEST_ONE: {
  my $stage = Test::AutoBuild::Stage::HTMLStatus->new(name => "html-status",
						      label => "Generate HTML status pages",
						      options => {
								 });
  isa_ok($stage, "Test::AutoBuild::Stage::HTMLStatus");

  # Implement me!
  #$stage->run($runtime);
  #ok($stage->succeeded(), "stage succeeeded");
}
