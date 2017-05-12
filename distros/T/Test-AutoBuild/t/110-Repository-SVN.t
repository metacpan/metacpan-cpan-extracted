# -*- perl -*-

use strict;
use warnings;
use Cwd;
use File::Spec::Functions;
use File::Path;
use Test::More tests => 48;
use Log::Log4perl;
Log::Log4perl::init("t/log4perl.conf");

BEGIN {
  use_ok("Test::AutoBuild::Repository::Subversion") or die;
  use_ok("Test::AutoBuild::Runtime") or die;
  use_ok("Test::AutoBuild::Module") or die;
}


my $here = getcwd;
my $build_repos = catfile($here, "t", "build-repos");
my $build_url = "file://" . $build_repos;
my $build_home = catfile($here, "t", "build-home");
my $archive = catfile($here, "t", "110-Repository-SVN.gz");

END {
  chdir $here;
  rmtree ($build_repos);
  rmtree ($build_home);
}

rmtree ($build_repos);
rmtree ($build_home);

mkpath ([$build_repos, $build_home], 0, 0755);

my $repos;

SKIP: {

  my $found_svn = 0;
  my $found_svnadmin = 0;
  my $found_gunzip = 0;
  foreach my $dir (File::Spec->path) {
    my $svnadmin = catfile($dir, "svnadmin");
    $found_svnadmin = 1 if -x $svnadmin;
    my $svn = catfile($dir, "svn");
    $found_svn = 1 if -x $svn;
    my $gunzip = catfile($dir, "gunzip");
    $found_gunzip = 1 if -x $gunzip;
  }
  skip "svn binary not in path", 45 unless $found_svn;
  skip "svnadmin binary not in path", 45 unless $found_svnadmin;
  skip "gunzip binary not in path", 45 unless $found_gunzip;

  system "svnadmin create $build_repos";
  system "cd $build_repos && (gunzip -c $archive | svnadmin load $build_repos) > /dev/null";

  my $head = "test/trunk";
  my $branch = "test/branch";

  chdir $build_home;
  $repos = Test::AutoBuild::Repository::Subversion->new(name => "test", label => "Test", options => { url => $build_url });
  isa_ok($repos, "Test::AutoBuild::Repository::Subversion");


  &checkout("head", $head, 1109844389, "0\n", 1, {}, 1);
  &checkout("head", $head, 1109844401, "1\n", 1, { 2 => Test::AutoBuild::Change->new(number => 2,
									     user => "dan",
									     date => "1109844400",
									     files => ["M /test/trunk/a"],
									     description => "Change 1")}, 2);

  &checkout("head", $head, 1109844412, "2\n", 1, { 3 => Test::AutoBuild::Change->new(number => 3,
									     user => "dan",
									     date => "1109844411",
									     files => ["M /test/trunk/a"],
									     description => "Change 2")}, 3);

  &checkout("head", $head, 1109844423, "2\n", 0, { }, 5 );
  &checkout("branch", $branch, 1109844423, "3\n", 1, { }, 5 );

  &checkout("head", $head, 1109844435, "4\n", 1, { 6 => Test::AutoBuild::Change->new(number => 6,
									     user => "dan",
									     date => "1109844434",
									     files => ["M /test/trunk/a"],
									     description => "Change 4") }, 6 );
  &checkout("branch", $branch, 1109844435, "3\n", 0, {}, 6);

  &checkout("head", $head, 1109844447, "4\n", 0, { }, 7);
  &checkout("branch", $branch, 1109844447, "5\n", 1, { 7 => Test::AutoBuild::Change->new(number => 7,
									       user => "dan",
									       date => "1109844446",
									       files => ["M /test/branch/a"],
									       description => "Change 5") }, 7 );

  &checkout("head", $head, 1109844449, "6\n", 1, { 8 => Test::AutoBuild::Change->new(number => 8,
									     user => "dan",
									     date => "1109844448",
									     files => ["M /test/trunk/a"],
									     description => "Change 6") }, 8 );
  &checkout("branch", $branch, 1109844449, "5\n", 0, {}, 8);
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

  my $rootChange = $repos->changelist($runtime);
  is($rootChange, $expect_root_change, "root changelist matches");
}

package Test::Counter;
use base qw(Test::AutoBuild::Counter);

sub generate {
  return 1;
}

