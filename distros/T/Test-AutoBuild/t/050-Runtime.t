# -*- perl -*-

use Test::More tests => 69;
use warnings;
use strict;
use Log::Log4perl;

BEGIN {
  use_ok("Test::AutoBuild::Runtime");
  use_ok("Test::AutoBuild::Module");
  use_ok("Test::AutoBuild::ArchiveManager::Memory");
}

Log::Log4perl::init("t/log4perl.conf");

use Test::AutoBuild::Runtime;
use Test::AutoBuild::Module;
use Test::AutoBuild::Repository;
use Test::AutoBuild::Publisher;
use Test::AutoBuild::PackageType;
use Test::AutoBuild::Monitor;
use Test::AutoBuild::Group;
use Test::AutoBuild::Archive;

my %modules = (
	       test1 => Test::AutoBuild::Module->new(name => "test1", label => 'Test1', sources => [], runtime => undef),
	       test2 => Test::AutoBuild::Module->new(name => "test2", depends => [ 'test1'], label => 'Test2', sources => [], runtime => undef),
	       test3 => Test::AutoBuild::Module->new(name => "test3", label => 'Test3', sources => [], runtime => undef),
	       test4 => Test::AutoBuild::Module->new(name => "test4", depends => [ 'test1', 'test2' ], label => 'Test3', sources => [], runtime => undef),
	       test5 => Test::AutoBuild::Module->new(name => "test5", depends => [ 'test2', 'test3' ], label => 'Test3', sources => [], runtime => undef),
	      );

my %monitors = (
		test1 => Test::AutoBuild::Monitor::Example->new(name => "test1", label => "Test 1"),
		test2 => Test::AutoBuild::Monitor::Example->new(name => "test1", label => "Test 1"),
	       );

my %publishers = (
		  test1 => Test::AutoBuild::Publisher->new(name => "test1", label => "Test"),
		  test2 => Test::AutoBuild::Publisher->new(name => "test2", label => "Test"),
		  );
my %package_types = (
		  test1 => Test::AutoBuild::PackageType->new(name => "test1", label => "Test", extension => "*.txt"),
		  test2 => Test::AutoBuild::PackageType->new(name => "test2", label => "Test", extension => "*.txt"),
		  );
my %groups = (
		  test1 => Test::AutoBuild::Group->new(name => "test1", label => "Test"),
		  test2 => Test::AutoBuild::Group->new(name => "test2", label => "Test"),
		  );
my %repositories = (
		  test1 => Test::AutoBuild::Repository->new(name => "test1", label => "Test"),
		  test2 => Test::AutoBuild::Repository->new(name => "test2", label => "Test"),
		  );

TEST_EMPTY: {
    eval {
	my $runtime = Test::AutoBuild::Runtime->new();
    };
    ok(defined $@, "throw an error when counter is missing");
}

TEST_MINIMAL: {
    my $runtime = Test::AutoBuild::Runtime->new(counter => Test::AutoBuild::Counter::Dummy->new(1));
    isa_ok($runtime, "Test::AutoBuild::Runtime");
    is($runtime->build_counter, 1, "counter is 1");

    my $runtime2 = $runtime->new(counter => Test::AutoBuild::Counter::Dummy->new(1));
    isa_ok($runtime2, "Test::AutoBuild::Runtime");

    my @modules = $runtime->modules();
    is($#modules, -1, "modules is empty");

    my @publishers = $runtime->publishers();
    is($#publishers, -1, "publishers is empty");

    my @monitors = $runtime->monitors();
    is($#monitors, -1, "monitors is empty");

    my @repositories = $runtime->repositories();
    is($#repositories, -1, "repositories is empty");

    my @package_types = $runtime->package_types();
    is($#package_types, -1, "package_types is empty");

    my @groups = $runtime->groups();
    is($#groups, -1, "groups is empty");

    my $archive = $runtime->archive();
    ok(!defined $archive, "archive not defined");
}

TEST_MAXIMAL: {
    my $runtime = Test::AutoBuild::Runtime->new(counter => Test::AutoBuild::Counter::Dummy->new(10),
						archive_manager => Test::AutoBuild::ArchiveManager::Memory->new(),
						groups => \%groups,
						publishers => \%publishers,
						package_types => \%package_types,
						modules => \%modules,
						monitors => \%monitors,
						repositories => \%repositories);
    isa_ok($runtime, "Test::AutoBuild::Runtime");

    is($runtime->build_counter, 10, "counter is 10");

    my $archiveman = $runtime->archive_manager;
    ok(defined $archiveman, "archive manager is defined");

    $runtime->archive_manager->create_archive(10);
    my $archive = $runtime->archive;
    ok(defined $archive, "archive is defined");

    my @modules = $runtime->modules();
    my @ex_modules = keys %modules;
    is($#modules, 4, "modules has 5 entries");
    ok(eq_array(\@modules, \@ex_modules), "got expected  modules");
    is($runtime->module($modules[0]), $modules{$modules[0]}, "module 0 found");
    is($runtime->module($modules[1]), $modules{$modules[1]}, "module 0 found");
    is($runtime->module($modules[2]), $modules{$modules[2]}, "module 0 found");
    is($runtime->module($modules[3]), $modules{$modules[3]}, "module 0 found");
    is($runtime->module($modules[4]), $modules{$modules[4]}, "module 0 found");
    eval {
	$runtime->module("no-such");
    };
    ok(defined $@, "got error with unknown name");

    my @publishers = $runtime->publishers();
    my @ex_publishers = keys %publishers;
    is($#publishers, 1, "publishers has 2 entries");
    ok(eq_array(\@publishers, \@ex_publishers), "got expected  publishers");
    is($runtime->publisher($publishers[0]), $publishers{$publishers[0]}, "publisher 0 found");
    is($runtime->publisher($publishers[1]), $publishers{$publishers[1]}, "publisher 0 found");
    eval {
	$runtime->publisher("no-such");
    };
    ok(defined $@, "got error with unknown name");

    my @monitors = $runtime->monitors();
    my @ex_monitors = keys %monitors;
    is($#monitors, 1, "monitors has 2 entries");
    ok(eq_array(\@monitors, \@ex_monitors), "got expected  monitors");
    is($runtime->monitor($monitors[0]), $monitors{$monitors[0]}, "monitor 0 found");
    is($runtime->monitor($monitors[1]), $monitors{$monitors[1]}, "monitor 0 found");
    eval {
	$runtime->monitor("no-such");
    };
    ok(defined $@, "got error with unknown name");

    my @repositories = $runtime->repositories();
    my @ex_repositories = keys %repositories;
    is($#repositories, 1, "repositories has 2 entries");
    ok(eq_array(\@repositories, \@ex_repositories), "got expected  repositories");
    is($runtime->repository($repositories[0]), $repositories{$repositories[0]}, "repository 0 found");
    is($runtime->repository($repositories[1]), $repositories{$repositories[1]}, "repository 0 found");
    eval {
	$runtime->repository("no-such");
    };
    ok(defined $@, "got error with unknown name");

    my @package_types = $runtime->package_types();
    my @ex_package_types = keys %package_types;
    is($#package_types, 1, "package_types has 2 entries");
    ok(eq_array(\@package_types, \@ex_package_types), "got expected  package_types");
    is($runtime->package_type($package_types[0]), $package_types{$package_types[0]}, "package_type 0 found");
    is($runtime->package_type($package_types[1]), $package_types{$package_types[1]}, "package_type 0 found");
    eval {
	$runtime->package_type("no-such");
    };
    ok(defined $@, "got error with unknown name");

    my @groups = $runtime->groups();
    my @ex_groups = keys %groups;
    is($#groups, 1, "groups has 2 entries");
    ok(eq_array(\@groups, \@ex_groups), "got expected  groups");
    is($runtime->group($groups[0]), $groups{$groups[0]}, "group 0 found");
    is($runtime->group($groups[1]), $groups{$groups[1]}, "group 0 found");
    eval {
	$runtime->group("no-such");
    };
    ok(defined $@, "got error with unknown name");
}

TEST_MODULE_ORDERING: {
    my $runtime = Test::AutoBuild::Runtime->new(counter => Test::AutoBuild::Counter::Dummy->new(1),
						archive_manager => Test::AutoBuild::ArchiveManager::Memory->new(),
						modules => \%modules);

    my @ordered = $runtime->sorted_modules();

    ok(@ordered == 5, "5 modules sorted");

    my %ordered;
    for (my $i = 0 ; $i <= $#ordered ; $i++) {
	$ordered{$ordered[$i]} = $i;
    }

    ok($ordered{test1} < $ordered{test2}, "test1 is before test2");
    ok($ordered{test1} < $ordered{test4}, "test1 is before test4");
    ok($ordered{test2} < $ordered{test4}, "test2 is before test4");
    ok($ordered{test2} < $ordered{test5}, "test2 is before test5");
    ok($ordered{test3} < $ordered{test5}, "test3 is before test5");
}

TEST_NOTIFICATIONS: {
    my $runtime = Test::AutoBuild::Runtime->new(counter => Test::AutoBuild::Counter::Dummy->new(1),
						archive_manager => Test::AutoBuild::ArchiveManager::Memory->new(),
						monitors => \%monitors);

    my @expected = (
		    ["beginCycle", time],
		    ["beginStage", "build", time],
		    ["completeStage", "build", time],
		    ["beginStage", "test", time],
		    ["completeStage", "test", time],
		    ["endCycle", time],
		    );

    foreach my $args (@expected) {
	$runtime->notify(@{$args});
    }

    my $mon1 = $runtime->monitor("test1");
    my @actual = $mon1->messages();
    ok(eq_array(\@expected, \@actual), "monitor 1 got all notifications");

    my $mon2 = $runtime->monitor("test2");
    @actual = $mon2->messages();
    ok(eq_array(\@expected, \@actual), "monitor 2 got all notifications");
}

TEST_ATTRIBUTES: {
    my $runtime = Test::AutoBuild::Runtime->new(counter => Test::AutoBuild::Counter::Dummy->new(1),
						archive_manager => Test::AutoBuild::ArchiveManager::Memory->new());

    is($runtime->attribute("foo"), undef, "foo undefined");

    is($runtime->attribute("foo", "bar"), "bar", "foo set to bar & bar returned");

    is($runtime->attribute("foo"), "bar", "foo is bar");

    is($runtime->attribute("foo", "wiz"), "wiz", "foo set to wiz & wiz returned");

    is($runtime->attribute("foo"), "wiz", "foo is wiz");

    my @attributes = sort { $a cmp $b } $runtime->attributes();
    ok(eq_array(\@attributes, [ 'foo' ]), "hash contains foo");
}

TEST_MACROS: {
    my %modules = (
		   'test-mod-1' => Test::AutoBuild::Module->new(name => "test1", label => 'Test1', sources => [], runtime => undef),
		   'test-mod-2' => Test::AutoBuild::Module->new(name => "test2", depends => [ 'test1'], label => 'Test2', sources => [], runtime => undef),
		   'test-mod-3' => Test::AutoBuild::Module->new(name => "test3", label => 'Test3', sources => [],  runtime => undef),
		   );

    my %package_types = (
			 'test-type-1' => Test::AutoBuild::PackageType->new(name => "test1", label => "Test", extension => "*.txt"),
			 'test-type-2' => Test::AutoBuild::PackageType->new(name => "test2", label => "Test", extension => "*.txt"),
			 );
    my $runtime = Test::AutoBuild::Runtime->new(counter => Test::AutoBuild::Counter::Dummy->new(1),
						archive_manager => Test::AutoBuild::ArchiveManager::Memory->new(),
						package_types => \%package_types,
						modules => \%modules);

    my $template1 = "foo-%m/%p";
    my @expected1a = (
		     "foo-test-mod-1/test-type-1",
		     "foo-test-mod-1/test-type-2",
		     "foo-test-mod-2/test-type-1",
		     "foo-test-mod-2/test-type-2",
		     "foo-test-mod-3/test-type-1",
		     "foo-test-mod-3/test-type-2"
		     );
    my @expected1b = (
		     "foo-test-mod-1/test-type-1",
		     "foo-test-mod-1/test-type-2",
		     );
    my @expected1c = (
		     "foo-test-mod-1/test-type-2",
		     );

    my @actual1a = sort $runtime->expand_macros($template1);
    ok(eq_array(\@expected1a, \@actual1a), "expanded templates");

    my @actual1b = sort $runtime->expand_macros($template1,
						{ module => "test-mod-1"});
    ok(eq_array(\@expected1b, \@actual1b), "expanded templates");

    my @actual1c = sort $runtime->expand_macros($template1,
						{
						    module => "test-mod-1",
						    package_type => "test-type-2",
						});
    ok(eq_array(\@expected1c, \@actual1c), "expanded templates");

    my $template2 = "foo-%p/%m/%g";
    my @actual2 = sort $runtime->expand_macros($template2);
    ok(eq_array([], \@actual2), "no expanded templates");
}

package Test::AutoBuild::Monitor::Example;

use base qw(Test::AutoBuild::Monitor);

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);

  $self->{messages} = [];

  return $self;
}

sub messages {
  my $self = shift;
  return @{$self->{messages}};
}

sub notify {
  my $self = shift;
  my @args = @_;

  push @{$self->{messages}}, \@args;
}

package Test::AutoBuild::Counter::Dummy;

use base qw(Test::AutoBuild::Counter);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();

    $self->{counter} = shift;

    return $self;
}

sub generate {
    my $self = shift;
    return $self->{counter};
}
