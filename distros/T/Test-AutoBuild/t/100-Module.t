# -*- perl -*-

use Test::More tests => 41;
use warnings;
use strict;
use Log::Log4perl;

BEGIN {
  use_ok("Test::AutoBuild::Module");
  use_ok("Test::AutoBuild::Archive::Memory");
  use_ok("Test::AutoBuild::Runtime");
  use_ok("Test::AutoBuild::Counter::Time");
}

Log::Log4perl::init("t/log4perl.conf");


BUILD: {
  my $module = Test::AutoBuild::Module->new(name => "mymod",
					    label => "My Module",
					    sources => [
							{
							 repository => "myrepo",
							 path => "mypath",
							},
						       ]
					   );
  isa_ok($module, "Test::AutoBuild::Module");

  my $now = time;
  sleep 2;
  my $then = time;

  $module->_add_result("checkout", "success");
  $module->_add_result("build", "success", $now, $then);

  is($module->build_status, "success", "build status is success");
  is($module->build_start_date, $now, "start time is $now");
  is($module->build_end_date, $then, "start time is $then");
  is($module->build_output_log_file, "mymod-build-output.log", "log name is mymod-build-output.log");
  is($module->build_result_log_file, "mymod-build-result.log", "log name is mymod-build-result.log");

  is($module->status, "success", "status is success");
}

TESTS: {
  my $module = Test::AutoBuild::Module->new(name => "mymod",
					    label => "My Module",
					    sources => [
							{
							 repository => "myrepo",
							 path => "mypath",
							}
						       ]
					   );
  isa_ok($module, "Test::AutoBuild::Module");

  my $now = time;
  sleep 2;
  my $then = time;

  $module->_add_result("checkout", "success");
  $module->_add_result("build", "success",  $now, $then);
  $module->_add_result("test-a", "success", $now, $then);

  is($module->test_status("a"), "success", "build status is success");
  is($module->test_start_date("a"), $now, "start time is $now");
  is($module->test_end_date("a"), $then, "start time is $then");
  is($module->test_output_log_file("a"), "mymod-test-a-output.log", "log name is mymod-test-output.log");
  is($module->test_result_log_file("a"), "mymod-test-a-result.log", "log name is mymod-test-result.log");

  is($module->status, "success", "status is success");

  $module->_add_result("test-b", "skipped", $now, $then);

  is($module->test_status("b"), "skipped", "build status is success");
  is($module->test_start_date("b"), $now, "start time is $now");
  is($module->test_end_date("b"), $then, "start time is $then");
  is($module->test_output_log_file("b"), "mymod-test-b-output.log", "log name is mymod-test-b-output.log");
  is($module->test_result_log_file("b"), "mymod-test-b-result.log", "log name is mymod-test-b-result.log");

  is($module->status, "success", "status is success");

  $module->_add_result("test-c", "failed", $now, $then);

  is($module->test_status("c"), "failed", "build status is success");
  is($module->test_start_date("c"), $now, "start time is $now");
  is($module->test_end_date("c"), $then, "start time is $then");
  is($module->test_output_log_file("c"), "mymod-test-c-output.log", "log name is mymod-test-c-output.log");
  is($module->test_result_log_file("c"), "mymod-test-c-result.log", "log name is mymod-test-c-result.log");

  is($module->status, "failed", "status is failed");

  my @tests = $module->tests;
  is_deeply(\@tests, ["a", "b", "c"], "three tests available");

}


CACHE: {
  my $mod1 = Test::AutoBuild::Module->new(name => "mod1",
					  label => "Mod 1",
					  sources => []);
  my $mod2 = Test::AutoBuild::Module->new(name => "mod2",
					  label => "Mod 2",
					  sources => []);
  $mod1->_add_result("checkout", "success");
  $mod2->_add_result("checkout", "success");

  my $runtime = Test::AutoBuild::Runtime->new(modules => {
							  mod1 => $mod1,
							  mod2 => $mod2,
							 },
					      counter => Test::AutoBuild::Counter::Time->new());

  my $cache = Test::AutoBuild::Archive::Memory->new(key => 1,
						    created => time);

  ok(!$mod1->archive_usable($runtime, $cache, "build"), "cache is not usable");

  $cache->save_data("mod1", "build", { status => "failed" });
  ok(!$mod1->archive_usable($runtime, $cache, "build"), "cache is not usable");

  $cache->save_data("mod1", "build", { status => "success" });
  ok($mod1->archive_usable($runtime, $cache, "build"), "cache is usable");

  $mod1->changed(1);
  ok(!$mod1->archive_usable($runtime, $cache, "build"), "cache is not usable");

  $mod1->changed(0);
  ok($mod1->archive_usable($runtime, $cache, "build"), "cache is usable");

  $mod1->depends(["mod2"]);
  ok(!$mod1->archive_usable($runtime, $cache, "build"), "cache is not usable");

  $cache->save_data("mod2", "build", { status => "failed"});
  ok(!$mod1->archive_usable($runtime, $cache, "build"), "cache is not usable");

  $cache->save_data("mod2", "build", { status => "success"});
  ok($mod1->archive_usable($runtime, $cache, "build"), "cache is usable");
}

SKIP: {
  my $mod1 = Test::AutoBuild::Module->new(name => "mod1",
					  label => "Mod 1",
					  sources => []);
  my $mod2 = Test::AutoBuild::Module->new(name => "mod2",
					  label => "Mod 2",
					  sources => [],
					  depends => [
						      "mod1",
						     ]);
  $mod1->_add_result("checkout", "success");
  $mod2->_add_result("checkout", "success");

  my $runtime = Test::AutoBuild::Runtime->new(modules => {
							  mod1 => $mod1,
							  mod2 => $mod2,
							 },
					      counter => Test::AutoBuild::Counter::Time->new());

  $mod1->_add_result("build", "failed");

  $mod2->build($runtime, "nosuchbuild.sh");

  is($mod2->build_status, "skipped", "build status is skipped");
  is($mod2->build_end_date, $mod2->build_start_date, "build end time == start time");
}

