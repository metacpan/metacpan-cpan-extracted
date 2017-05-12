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
  use_ok("Test::AutoBuild::Repository::Git") or die;
  use_ok("Test::AutoBuild::Runtime") or die;
  use_ok("Test::AutoBuild::Module") or die;
}


my $here = getcwd;
my $build_repos = catfile($here, "t", "build-repos");
my $build_home = catfile($here, "t", "build-home");
my $archive = catfile($here, "t", "110-Repository-Git.tar.gz");

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

  my $found_git = 0;
  my $found_gunzip = 0;
  my $found_tar = 0;
  foreach my $dir (File::Spec->path) {
    my $git = catfile($dir, "git");
    $found_git = 1 if -x $git;
    my $gunzip = catfile($dir, "gunzip");
    $found_gunzip = 1 if -x $gunzip;
    my $tar = catfile($dir, "tar");
    $found_tar = 1 if -x $tar;
  }
  skip "git binary not in path", 28 unless $found_git;
  skip "gunzip binary not in path", 28 unless $found_gunzip;
  skip "tar binary not in path", 28 unless $found_tar;

  system "cd $build_repos && (gunzip -c $archive | tar xf -)";

  my $head = "main";
  my $branch = "main:wibble";

  chdir $build_home;
  $repos = Test::AutoBuild::Repository::Git->new(name => "test", label => "Test", options => { 'base-url' => $build_repos});
  isa_ok($repos, "Test::AutoBuild::Repository::Git");


  &checkout(1, "head", $head, 1197239946, "0\n", 1, {}, 1);

  &checkout(2, "head", $head, 1197239957, "1\n", 1, { "39c0910" => Test::AutoBuild::Change->new(number => "39c0910",
									     user => "Daniel Berrange <berrange\@t60wlan.home.berrange.com>",
									     date => "1197239956",
									     files => ["a"],
									     description => "Change 1 on trunk")}, 1);

  &checkout(3, "head", $head, 1197239967, "2\n", 1, { "3c4dfa7" => Test::AutoBuild::Change->new(number => "3c4dfa7",
									     user => "Daniel Berrange <berrange\@t60wlan.home.berrange.com>",
									     date => "1197239966",
									     files => ["a"],
									     description => "Change 2 on trunk")}, 2);


  #&checkout("head", $head, 1109844423, "2\n", 0, { }, 3 );
  &checkout(4, "branch", $branch, 1197239987, "3\n", 1, { }, 3 );

  &checkout(5, "head", $head, 1197240007, "4\n", 1, { "673bfe8" => Test::AutoBuild::Change->new(number => "673bfe8",
									     user => "Daniel Berrange <berrange\@t60wlan.home.berrange.com>",
									     date => "1197239986",
									     files => ["a"],
									     description => "Change 3 on branch"),
					   "3870532" => Test::AutoBuild::Change->new(number => "3870532",
									     user => "Daniel Berrange <berrange\@t60wlan.home.berrange.com>",
									     date => "1197240006",
									     files => ["a"],
									     description => "Change 4 on trunk"), }, 4 );
  &checkout(6, "branch", $branch, 1197240007, "3\n", 0, {}, 3);

  #&checkout("head", $head, 1109844447, "4\n", 0, { }, 7);
  &checkout(7, "branch", $branch, 11972400017, "5\n", 1, { "10c317b" => Test::AutoBuild::Change->new(number => "10c317b",
									     user => "Daniel Berrange <berrange\@t60wlan.home.berrange.com>",
									       date => "1197240016",
									       files => ["a"],
									       description => "Change 5 on branch") }, 5 );

  &checkout(8, "head", $head, 1197240027, "6\n", 1, { "10c317b" => Test::AutoBuild::Change->new(number => "10c317b",
									     user => "Daniel Berrange <berrange\@t60wlan.home.berrange.com>",
									     date => "1197240016",
									     files => ["a"],
									     description => "Change 5 on branch"),
					   "f92574d"=> Test::AutoBuild::Change->new(number => "f92574d",
									     user => "Daniel Berrange <berrange\@t60wlan.home.berrange.com>",
									     date => "1197240016",
									     files => [],
									     description => "Merge branch 'wibble'"),
					   "0273df1"=> Test::AutoBuild::Change->new(number => "0273df1",
									     user => "Daniel Berrange <berrange\@t60wlan.home.berrange.com>",
									     date => "1197240026",
									     files => ["a"],
									     description => "Change 6 on trunk") }, 6 );
  &checkout(9, "branch", $branch, 1197240027, "5\n", 0, {}, 5);

}

sub checkout {
  my $index = shift;
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

  is($changed, $expect_change, "$index " . $module . " files changed");
  is_deeply($changes, $expected_changes, "$index " . $module . " changes match");

  my $file = catfile($build_home, $module, "a");
  open FILE, $file
    or die "cannot open $file: $!";

  my $line = <FILE>;
  close FILE;

  is($line, $content, "$index " . $module . " content matches");
}

package Test::Counter;
use base qw(Test::AutoBuild::Counter);

sub generate {
  return 1;
}

