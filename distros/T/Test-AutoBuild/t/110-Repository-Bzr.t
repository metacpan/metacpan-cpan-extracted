# -*- perl -*-
#

use strict;
use warnings;
use Cwd;
use File::Spec::Functions;
use File::Path;
use Test::More tests => 31;
use Log::Log4perl;
Log::Log4perl::init("t/log4perl.conf");

BEGIN {
  use_ok("Test::AutoBuild::Repository::Bazaar") or die;
  use_ok("Test::AutoBuild::Runtime") or die;
  use_ok("Test::AutoBuild::Module") or die;
}


my $here = getcwd;
my $build_repos = catfile($here, "t", "build-repos");
my $build_home = catfile($here, "t", "build-home");
my $archive = catfile($here, "t", "110-Repository-Bzr.tar.gz");

END {
  chdir $here;
  unless ($ENV{DEBUG_TESTS}) {
    rmtree ($build_repos);
    rmtree ($build_home);
  }
}

rmtree ($build_repos);
rmtree ($build_home);

mkpath ([$build_repos, $build_home], 0, 0755);

my $repos;

SKIP: {

  my $found_bzr = 0;
  my $found_gunzip = 0;
  my $found_tar = 0;
  foreach my $dir (File::Spec->path) {
    my $bzr = catfile($dir, "bzr");
    $found_bzr = 1 if -x $bzr;
    my $gunzip = catfile($dir, "gunzip");
    $found_gunzip = 1 if -x $gunzip;
    my $tar = catfile($dir, "tar");
    $found_tar = 1 if -x $tar;
  }
  skip "bzr binary not in path", 28 unless $found_bzr;
  skip "gunzip binary not in path", 28 unless $found_gunzip;
  skip "tar binary not in path", 28 unless $found_tar;

  system "cd $build_repos && (gunzip -c $archive | tar xf -)";

  my $head = "main";
  my $branch = "main/wibble";

  chdir $build_home;
  $repos = Test::AutoBuild::Repository::Bazaar->new(name => "test", label => "Test", options => { 'base-url' => $build_repos});
  isa_ok($repos, "Test::AutoBuild::Repository::Bazaar");


  &checkout("head", $head, 1197306890, "0\n", 1, {}, 1);

  &checkout("head", $head, 1197306900, "1\n", 1,
	    { 2 => Test::AutoBuild::Change->new(number => 2,
						user => "Daniel Berrange <berrange\@t60wlan.home.berrange.com>",
						date => "1197306899",
						files => [],
						description => "Change 1 on trunk")}, 1);

  &checkout("head", $head, 1197306911, "2\n", 1,
	    { 3 => Test::AutoBuild::Change->new(number => 3,
						user => "Daniel Berrange <berrange\@t60wlan.home.berrange.com>",
						date => "1197306910",
						files => [],
						description => "Change 2 on trunk")}, 2);

  #&checkout("head", $head, 1109844423, "2\n", 0, { }, 3 );
  &checkout("branch", $branch, 1197306931, "3\n", 1, { }, 3 );

  &checkout("head", $head, 1197306951, "4\n", 1,
	    { 4 => Test::AutoBuild::Change->new(number => 4,
						user => "Daniel Berrange <berrange\@t60wlan.home.berrange.com>",
						date => "1197306950",
						files => [],
						description => "Change 4 on trunk"), }, 4 );
  &checkout("branch", $branch, 1197306951, "3\n", 0, {}, 3);

  #&checkout("head", $head, 1109844447, "4\n", 0, { }, 7);
  &checkout("branch", $branch, 1197306962, "5\n", 1,
	    { 5 => Test::AutoBuild::Change->new(number => 5,
						user => "Daniel Berrange <berrange\@t60wlan.home.berrange.com>",
						date => "1197306961",
						files => [],
						description => "Change 5 on branch") }, 5 );

  &checkout("head", $head, 1197306972, "6\n", 1,
	    { 5 => Test::AutoBuild::Change->new(number => 5,
						user => "Daniel Berrange <berrange\@t60wlan.home.berrange.com>",
						date => "1197306971",
						files => [],
						description => "Change 6 on trunk")});
  &checkout("branch", $branch, 1197306972, "5\n", 0, {}, 5);

}

sub checkout {
  my $module = shift;
  my $src = shift;
  my $timestamp = shift;
  my $content = shift;
  my $expect_change = shift;
  my $expected_changes = shift;
  my $expect_root_change = shift;

  my $runtime = Test::AutoBuild::Runtime->new(counter => Test::Counter->new,
					      timestamp => $timestamp);

  my ($changed, $changes) = $repos->export($runtime, $src, $module);

  is($changed, $expect_change, $module . " files changed");
  is_deeply($changes, $expected_changes, $module . " changes match");

  my $file = catfile($build_home, $module, "a");
  open FILE, $file
    or die "cannot open $file: $!";

  my $line = <FILE>;
  close FILE;

  is($line, $content, $module . " content matches");
}

package Test::Counter;
use base qw(Test::AutoBuild::Counter);

sub generate {
  return 1;
}

