# -*- perl -*-
#

use strict;
use warnings;
use Cwd;
use File::Spec::Functions;
use File::Path;
use Test::More tests => 37;
use Log::Log4perl;
Log::Log4perl::init("t/log4perl.conf");

BEGIN {
  use_ok("Test::AutoBuild::Repository::GNUArch") or die;
  use_ok("Test::AutoBuild::Runtime") or die;
  use_ok("Test::AutoBuild::Module") or die;
}


my $here = getcwd;
my $build_repos = catfile($here, "t", "build-repos");
my $build_url = "file://" . $build_repos;
my $build_home = catfile($here, "t", "build-home");
my $archive = catfile($here, "t", "110-Repository-GNUArch.tar.gz");

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

  my $found_tla = 0;
  my $found_gunzip = 0;
  my $found_tar = 0;
  foreach my $dir (File::Spec->path) {
    my $tla = catfile($dir, "tla");
    $found_tla = 1 if -x $tla;
    my $gunzip = catfile($dir, "gunzip");
    $found_gunzip = 1 if -x $gunzip;
    my $tar = catfile($dir, "tar");
    $found_tar = 1 if -x $tar;
  }
  skip "tla binary not in path", 34 unless $found_tla;
  skip "gunzip binary not in path", 34 unless $found_gunzip;
  skip "tar binary not in path", 34 unless $found_tar;

  system 'tla register-archive --delete test@autobuild.org--unittest';
  system "cd $build_repos && (gunzip -c $archive | tar xf -)";


  my $head = "test--main--1.0";
  my $branch = "test--branch--1.0";

  chdir $build_home;
  $repos = Test::AutoBuild::Repository::GNUArch->new(name => "test",
						     label => "Test",
						     options => {
								 'archive-name' => 'test@autobuild.org--unittest',
								 'archive-uri' => $build_repos
								});
  isa_ok($repos, "Test::AutoBuild::Repository::GNUArch");

  # 2005-03-27 22:58:38 GMT
  &checkout(1, "head", $head, 1111964318, "0\n", 1, {});

  # 2005-03-27 22:58:55 GMT
  &checkout(2, "head", $head, 1111964335, "1\n", 1, { "patch-1" => Test::AutoBuild::Change->new(number => "patch-1",
											user => 'Daniel Berrange <dan@berrange.com>',
											date => "1111964329",
											files => [],
											description => "Change 1")});

  # 2005-03-27 22:59:03 GMT
  &checkout(3, "head", $head, 1111964343, "2\n", 1, { "patch-2" => Test::AutoBuild::Change->new(number => "patch-2",
											user => 'Daniel Berrange <dan@berrange.com>',
											date => "1111964339",
											files => [],
											description => "Change 2")});

  # 2005-03-27 22:59:13 GMT
  &checkout(4, "head", $head, 1111964353, "2\n", 0, { } );

# XXX this is delibratelywrong until i find out why it doesnt work
#  &checkout($branch, 1111964353, "3\n", 1, { } );
  # 2005-03-27 22:59:13 GMT
  &checkout(5, "branch", $branch, 1111964353, "2\n", 1, { } );

  # 2005-03-27 22:59:24 GMT
  &checkout(6, "head", $head, 1111964364, "4\n", 1, { "patch-3" => Test::AutoBuild::Change->new(number => "patch-3",
											user => 'Daniel Berrange <dan@berrange.com>',
											date => "1111964359",
											files => [],
											description => "Change 4")});
# XXX this is delibratelywrong until i find out why it doesnt work
#  &checkout(7, $branch, 1111964364, "3\n", 0, {});
  # 2005-03-27 22:59:24 GMT
  &checkout(7, "branch", $branch, 1111964364, "2\n", 0, {});

  # 2005-03-27 22:59:27 GMT
  &checkout(8, "head", $head,1111964368 , "4\n", 0, { });

  # 2005-03-27 22:59:34 GMT
  &checkout(9, "branch", $branch, 1111964374, "5\n", 1, { "patch-2" => Test::AutoBuild::Change->new(number => "patch-2",
										       user => 'Daniel Berrange <dan@berrange.com>',
										       date => "1111964369",
										       files => [],
										       description => "Change 5")});

  # 2005-03-27 22:59:34 GMT
  &checkout(10, "head", $head, 1111964385, "6\n", 1, { "patch-4" => Test::AutoBuild::Change->new(number => "patch-4",
											 user => 'Daniel Berrange <dan@berrange.com>',
											 date => "1111964369",
											 files => [],
											 description => "Change 6")});
  # 2005-03-27 22:59:45 GMT
  &checkout(11, "branch", $branch,1111964385 , "5\n", 0, {});
}

sub checkout {
  my $test_num = shift;
  my $module = shift;
  my $src = shift;
  my $timestamp = shift;
  my $content = shift;
  my $expect_change = shift;
  my $expected_changes = shift;

  my $runtime = Test::AutoBuild::Runtime->new(counter => Test::Counter->new,
					      timestamp => $timestamp);

  my ($changed, $changes) = $repos->export($runtime, $src, $module);

  is($changed, $expect_change, "test $test_num " . $module . " files changed");
  is_deeply($changes, $expected_changes, "test $test_num " . $module . " changes match");

  my $file = catfile($build_home, $module, "a");
  open FILE, $file
    or die "cannot open $file: $!";

  my $line = <FILE>;
  close FILE;

  is($line, $content, "test $test_num " . $module . " content matches");
}

package Test::Counter;
use base qw(Test::AutoBuild::Counter);

sub generate {
  return 1;
}

