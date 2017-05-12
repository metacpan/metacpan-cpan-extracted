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
  use_ok("Test::AutoBuild::Repository::Darcs") or die;
  use_ok("Test::AutoBuild::Runtime") or die;
  use_ok("Test::AutoBuild::Module") or die;
}


my $here = getcwd;
my $build_repos = catfile($here, "t", "build-repos");
my $build_home = catfile($here, "t", "build-home");
my $archive = catfile($here, "t", "110-Repository-Darcs.tar.gz");

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

  my $found_darcs = 0;
  my $found_gunzip = 0;
  my $found_tar = 0;
  foreach my $dir (File::Spec->path) {
    my $darcs = catfile($dir, "darcs");
    $found_darcs = 1 if -x $darcs;
    my $gunzip = catfile($dir, "gunzip");
    $found_gunzip = 1 if -x $gunzip;
    my $tar = catfile($dir, "tar");
    $found_tar = 1 if -x $tar;
  }
  skip "darcs binary not in path", 28 unless $found_darcs;
  skip "gunzip binary not in path", 28 unless $found_gunzip;
  skip "tar binary not in path", 28 unless $found_tar;

  system "cd $build_repos && (gunzip -c $archive | tar xf -)";

  my $head = "trunk";
  my $branch = "/branch";

  chdir $build_home;
  $repos = Test::AutoBuild::Repository::Darcs->new(name => "test", label => "Test", options => { 'base-url' => $build_repos});
  isa_ok($repos, "Test::AutoBuild::Repository::Darcs");


  &checkout("head", $head, 1197259392, "0\n", 1, {}, 1);

  &checkout("head", $head, 1197259402, "1\n", 1,
	    { 20071210040321 => Test::AutoBuild::Change->new(number => 20071210040321,
							     user => "Fred Bloggs <fred\@example.org>",
							     date => "1197259401",
							     files => [],
							     description => "Change 1 on trunk")}, 1);


  &checkout("head", $head, 1197259412, "2\n", 1,
	    { 20071210040331 => Test::AutoBuild::Change->new(number => 20071210040331,
							     user => "Fred Bloggs <fred\@example.org>",
							     date => "1197259411",
							     files => [],
							     description => "Change 2 on trunk")}, 2);

  &checkout("branch", $branch, 1197259432, "3\n", 1, { }, 3 );

  &checkout("head", $head, 1197259453, "4\n", 1,
	    { 20071210040351 => Test::AutoBuild::Change->new(number => 20071210040351,
							     user => "Fred Bloggs <fred\@example.org>",
							     date => "1197259431",
							     files => [],
							     description => "Change 3 on branch"),
	      20071210040412 => Test::AutoBuild::Change->new(number => 20071210040412,
							     user => "Fred Bloggs <fred\@example.org>",
							     date => "1197259452",
							     files => [],
							     description => "Change 4 on trunk"), }, 4 );
  &checkout("branch", $branch, 1197259453, "3\n", 0, {}, 3);

  &checkout("branch", $branch, 1197259463, "5\n", 1,
	    { 20071210040422 => Test::AutoBuild::Change->new(number => 20071210040422,
							     user => "Fred Bloggs <fred\@example.org>",
							     date => "1197259462",
							     files => [],
							     description => "Change 5 on branch") }, 5 );

  &checkout("head", $head, 1197259474, "6\n", 1,
	    { 20071210040422 => Test::AutoBuild::Change->new(number => 20071210040422,
							     user => "Fred Bloggs <fred\@example.org>",
							     date => "1197259462",
							     files => [],
							     description => "Change 5 on branch"),
	      20071210040433 => Test::AutoBuild::Change->new(number => 20071210040433,
							     user => "Fred Bloggs <fred\@example.org>",
							     date => "1197259473",
							     files => [],
							     description => "Change 6 on trunk") }, 6 );
  &checkout("branch", $branch, 1197259474, "5\n", 0, {}, 5);

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

