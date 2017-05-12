# -*- perl -*-

use Test::More tests => 28;
use warnings;
use strict;
use Log::Log4perl;

Log::Log4perl::init("t/log4perl.conf");

BEGIN {
  use_ok("Test::AutoBuild::Stage") or die;
  use_ok("Test::AutoBuild::Runtime") or die;
  use_ok("Test::AutoBuild::Counter::Time") or die;
}

my $runtime = Test::AutoBuild::Runtime->new(counter => Test::AutoBuild::Counter::Time->new(),
					    timestamp => time);

TEST_BASE: {
  my $stage = Test::AutoBuild::Stage->new(name => "base",
					  label => "Base stage",
					  options => {});
  isa_ok($stage, "Test::AutoBuild::Stage");

  ok(!defined $stage->start_time(), "start time undefined");
  ok(!defined $stage->end_time(), "end time undefined");

  # We should start off in pending state
  ok($stage->pending(), "stage pending");
  is($stage->status(), "pending", "stage status is pending");

  $stage->run($runtime);
  ok(defined $stage->start_time(), "start time defined");
  ok(defined $stage->end_time(), "end time defined");
  ok($stage->end_time >= $stage->start_time(), "end time > start time");

  is($stage->end_time() - $stage->start_time(), $stage->duration(), "duration = end-start");

  # We should abort because we forgot the 'process' method
  ok($stage->aborted(), "stage aborted");
  is($stage->status(), "aborted", "stage status is aborted");

  $stage->is_enabled(0);
  $stage->run($runtime);
  # We should be skipped
  ok($stage->skipped(), "stage skipped");
  is($stage->status(), "skipped", "stage status is skipped");
}

TEST_ERRORS: {
  eval {
    my $stage = Test::AutoBuild::Stage->new();
  };
  ok($@, "error about missing name");

  eval {
    my $stage = Test::AutoBuild::Stage->new(name => "name");
  };
  ok($@, "error about missing label");
}

TEST_DEFAULTS: {
  my $stage = Test::AutoBuild::Stage->new(name => "name",
					  label => "label",
					  critical => 0,
					  enabled => 0);

  is($stage->is_enabled(), 0, "stage disabled");
  is($stage->is_critical(), 0, "stage critical");
}

TEST_OPTIONS: {
  my $stage = StageOption->new(name => "options",
			       label => "Options",
			       options => {
					   data => "Some message",
					  });
  isa_ok($stage, "StageOption");

  $stage->run($runtime);
  ok($stage->succeeded(), "stage succeeeded");
  is($stage->status(), "success", "stage status is success");

  is($stage->data(), "Some message", "Got option");
}

TEST_FAILURE: {
  my $stage = StageFailure->new(name => "options",
				label => "Options",
				options => {});
  isa_ok($stage, "StageFailure");

  $stage->run($runtime);
  ok($stage->failed(), "stage succeeeded");

  $stage->is_critical(0);
  is($stage->is_critical(), 0, "stage is critical");

  $stage->run($runtime);
  ok($stage->failed(), "stage succeeeded");
}

package StageOption;

use base qw(Test::AutoBuild::Stage);

sub process {
  my $self = shift;
  my $runtime = shift;

  $self->{data} = $self->option("data");
}

sub data {
  my $self = shift;
  return $self->{data};
}

package StageFailure;

use base qw(Test::AutoBuild::Stage);

sub process {
  my $self = shift;
  my $runtime = shift;

  $self->fail("Failed stage");
}
