# -*- perl -*-
#

use strict;
use warnings;
use Cwd;
use File::Spec::Functions;
use File::Path;
use Test::More tests => 26;
use Log::Log4perl;
Log::Log4perl::init("t/log4perl.conf");

BEGIN {
  use_ok("Test::AutoBuild::Repository::CVS") or die;
  use_ok("Test::AutoBuild::Runtime") or die;
  use_ok("Test::AutoBuild::Module") or die;
}


my $here = getcwd;
my $build_repos = catfile($here, "t", "build-repos");
my $build_home = catfile($here, "t", "build-home");
my $archive = catfile($here, "t", "110-Repository-CVS.tar.gz");

END {
  chdir $here;
  unless ($ENV{DEBUG_TESTS}) {
    rmtree ($build_repos);
    rmtree ($build_home);
  }
}

rmtree ($build_repos);
rmtree ($build_home);

SKIP: {

  my $found_cvs = 0;
  my $found_svnadmin = 0;
  my $found_gunzip = 0;
  my $found_tar = 0;
  foreach my $dir (File::Spec->path) {
    my $cvs = catfile($dir, "cvs");
    $found_cvs = 1 if -x $cvs;
    my $gunzip = catfile($dir, "gunzip");
    $found_gunzip = 1 if -x $gunzip;
    my $tar = catfile($dir, "tar");
    $found_tar = 1 if -x $tar;
  }
  skip "cvs binary not in path", 23 unless $found_cvs;
  skip "gunzip binary not in path", 23 unless $found_gunzip;
  skip "tar binary not in path", 23 unless $found_tar;

  mkpath ([$build_repos, $build_home], 0, 0755);
  system "cd $build_repos && (gunzip -c $archive | tar xf -)";

  my $head = "test";
  my $branch = "test:branch";

  chdir $build_home;
  my $repos = Test::AutoBuild::Repository::CVS->new(name => "test", label => "Test", env => { CVSROOT => $build_repos });
  isa_ok($repos, "Test::AutoBuild::Repository::CVS");

  &checkout($repos, "head", $head, 1109197163, "1\n", 1);
  &checkout($repos, "head", $head, 1109197165, "1\n", 0);

  &checkout($repos, "head", $head, 1109197174, "2\n", 1);

  &checkout($repos, "head", $head, 1109197185, "2\n", 0);
  &checkout($repos, "branch", $branch, 1109197185, "3\n", 1);

  &checkout($repos, "head", $head, 1109197197, "4\n", 1);
  &checkout($repos, "branch", $branch, 1109197197, "3\n", 0);

  &checkout($repos, "head", $head, 1109197209, "4\n", 0);
  &checkout($repos, "branch", $branch, 1109197209, "5\n", 1);

  &checkout($repos, "head", $head, 1109197211, "6\n", 1);
  &checkout($repos, "branch", $branch, 1109197211, "5\n", 0);
}


sub checkout {
  my $repos = shift;
  my $module = shift;
  my $src = shift;
  my $timestamp = shift;
  my $content = shift;
  my $changes = shift;

  my $runtime = Test::AutoBuild::Runtime->new(counter => Test::Counter->new(),
					      timestamp => $timestamp);

  my $changed = $repos->export($runtime, $src, $module);

  is($changes, $changed, $module . " files changed");

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


