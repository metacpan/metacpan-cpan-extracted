# -*- perl -*-

use Test::More tests => 16;
use warnings;
use strict;
use Log::Log4perl;

Log::Log4perl::init("t/log4perl.conf");

BEGIN {
  use_ok("Test::AutoBuild::Monitor") or die;
}


TEST_ONE: {
  my $monitor = Test::AutoBuild::Monitor->new(name => "test",
					      label => "test",
					      options => {
							 foo => "bar"
							 });
  isa_ok($monitor, "Test::AutoBuild::Monitor");

  is($monitor->option("foo"), "bar", "foo is bar");
  is($monitor->option("foo", "eek"), "eek", "foo is eek");
  is($monitor->option("foo"), "eek", "foo is eek");

  is($monitor->option("bar"), undef, "bar is undefined");
  is($monitor->option("bar", "foo"), "foo", "bar is foo");
}

TEST_ERRORS: {
  eval {
    my $monitor = Test::AutoBuild::Monitor->new(label => "test");
  };
  ok(defined $@, "name is required");

  eval {
    my $monitor = Test::AutoBuild::Monitor->new(name => "test");
  };
  ok(defined $@, "label is required");

  eval {
    my $monitor = Test::AutoBuild::Monitor->new(name => "test",
						label => "test");
    $monitor->notify("foo");
  };
  ok(defined $@, "process method is required");
}

TEST_ENV: {
  my $monitor = MyMonitor->new(name => "foo",
			       label => "foo",
			       enabled => 0,
			       env => {
				       ENV1 => "foo",
				      });

  is($monitor->env("ENV2"), undef, "ENV2 is undefined");
  is($monitor->env("ENV2", "eek"), "eek", "ENV2 is eek");

  $monitor->notify("foo");
  is($monitor->{ENV1}, undef, "ENV1 is undefined");
  is($monitor->{ENV2}, undef, "ENV2 is undefined");

  $monitor->is_enabled(1);

  $monitor->notify("foo");
  is($monitor->{ENV1}, "foo", "ENV1 is foo");
  is($monitor->{ENV2}, "eek", "ENV2 is eek");
}


package MyMonitor;

use base qw(Test::AutoBuild::Monitor);

sub process {
  my $self = shift;

  $self->{ENV1} = $ENV{ENV1};
  $self->{ENV2} = $ENV{ENV2};
}
