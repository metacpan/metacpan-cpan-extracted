# -*- perl -*-

use Test::More tests => 41;
use warnings;
use strict;
use Log::Log4perl;
use File::Path;
use File::Spec::Functions;
use File::stat;

BEGIN {
  use_ok("Test::AutoBuild::Archive::File");
}

Log::Log4perl::init("t/log4perl.conf");

END {
    if (!exists $ENV{DEBUG_TESTS}) {
	rmtree catdir("t", "scratch");
    }
}

rmtree catdir("t", "scratch");
mkdir catdir("t", "scratch");
mkdir catdir("t", "scratch", "build-root");
mkdir catdir("t", "scratch", "install-root");
mkdir catdir("t", "scratch", "archive-root");
mkdir catdir("t", "scratch", "archive-root", "1");
mkdir catdir("t", "scratch", "archive-root", "2");
mkdir catdir("t", "scratch", "archive-root", "3");

SIMPLE: {
    my $arc = Test::AutoBuild::Archive::File->new(key => 1,
						  created => time,
						  archive_dir => catdir("t", "scratch", "archive-root"));
    isa_ok($arc, "Test::AutoBuild::Archive::File");

    my $one = catfile("t", "scratch", "build-root", "one");
    &create_file($one, "one");
    my $two = catfile("t", "scratch", "build-root", "two");
    &create_file($two, "two");
    my $three = catfile("t", "scratch", "build-root", "three");
    &create_file($three, "three");

    my $sone = stat $one;
    my $stwo = stat $two;
    my $sthree = stat $three;
    my $tosave = {
	$one => $sone,
	$two => $stwo,
	$three => $sthree,
    };

    $arc->save_data("mymod",
		    "test1",
		    { foo => "bar" });

    $arc->save_files("mymod",
		     "build",
		     $tosave,
		     {
			 base => catdir("t", "scratch", "build-root"),
		     });

    ok(-d catdir("t", "scratch", "archive-root", "1", "mymod"), "mymod exists");
    ok(-d catdir("t", "scratch", "archive-root", "1", "mymod", "build"), "mymod build bucket exists");

    my $files = $arc->get_files("mymod", "build");

    my $toget = {
	"one" => $sone,
	"two" => $stwo,
	"three" => $sthree,
    };

    is_deeply($files, $toget,"got back 3 files");

    $arc->extract_files("mymod",
			"build",
			catdir("t", "scratch", "install-root"));


    ok(-f catfile("t", "scratch", "install-root", "one"), "file one exists");
    ok(-f catfile("t", "scratch", "install-root", "two"), "file two exists");
    ok(-f catfile("t", "scratch", "install-root", "three"), "file three exists");
    is((stat catfile("t", "scratch", "install-root", "one"))->nlink, 1, "only 1 link");
    is((stat catfile("t", "scratch", "install-root", "two"))->nlink, 1, "only 1 link");
    is((stat catfile("t", "scratch", "install-root", "three"))->nlink, 1, "only 1 link");


    ok($arc->has_files("mymod", "build"), "mymod has files in build bucket");
    ok(!$arc->has_files("mymod", "nobuild"), "mymod does not have files in nobuild bucket");
    ok($arc->has_data("mymod", "test1"), "mymod has data in test1 bucket");
    ok(!$arc->has_data("mymod", "test2"), "mymod does not have data in test2 bucket");

    is_deeply($arc->get_data("mymod", "test1"), { foo => "bar" }, "mymod has data in test1 bucket");
    is_deeply($arc->get_data("mymod", "test2"), {}, "mymod does not have data in test2 bucket");
    is_deeply($arc->get_files("mymod", "nobuild"), {}, "mymod does not have any files in the nobuild bucket");

}


FILE_LINKING: {
    my $arc = Test::AutoBuild::Archive::File->new(key => 2,
						  created => time,
						  archive_dir => catdir("t", "scratch", "archive-root"));
    isa_ok($arc, "Test::AutoBuild::Archive::File");

    my $one = catfile("t", "scratch", "build-root", "one");
    &create_file($one, "one");
    my $two = catfile("t", "scratch", "build-root", "two");
    &create_file($two, "two");
    my $three = catfile("t", "scratch", "build-root", "three");
    &create_file($three, "three");

    my $sone = stat $one;
    my $stwo = stat $two;
    my $sthree = stat $three;
    my $tosave = {
	$one => $sone,
	$two => $stwo,
	$three => $sthree,
    };

    $arc->save_files("othermod",
		     "build",
		     $tosave,
		     {
			 base => catdir("t", "scratch", "build-root"),
			 link => 1,
		     });

    ok(-d catdir("t", "scratch", "archive-root", "2", "othermod"), "othermod exists");
    ok(-d catdir("t", "scratch", "archive-root", "2", "othermod", "build"), "othermod build bucket exists");

    my $files = $arc->get_files("othermod", "build");

    my $toget = {
	"one" => $sone,
	"two" => $stwo,
	"three" => $sthree,
    };

    is_deeply($files, $toget,"got back 3 files");

    $arc->extract_files("othermod",
			"build",
			catdir("t", "scratch", "install-root"),
			{ link => 1 });

    ok(-f catfile("t", "scratch", "install-root", "one"), "file one exists");
    ok(-f catfile("t", "scratch", "install-root", "two"), "file two exists");
    ok(-f catfile("t", "scratch", "install-root", "three"), "file three exists");
    is((stat catfile("t", "scratch", "install-root", "one"))->nlink, 3, "has 3 links");
    is((stat catfile("t", "scratch", "install-root", "two"))->nlink, 3, "has 3 links");
    is((stat catfile("t", "scratch", "install-root", "three"))->nlink, 3, "has 3 links");
}

ARCHIVE_LINKING: {
    my $firstarc = Test::AutoBuild::Archive::File->new(key => 1,
						       created => time,
						       archive_dir => catdir("t", "scratch", "archive-root"));
    isa_ok($firstarc, "Test::AutoBuild::Archive::File");

    my $oldarc = Test::AutoBuild::Archive::File->new(key => 2,
						     created => time,
						     archive_dir => catdir("t", "scratch", "archive-root"));
    isa_ok($oldarc, "Test::AutoBuild::Archive::File");

    my $newarc = Test::AutoBuild::Archive::File->new(key => 3,
						     created => time,
						     archive_dir => catdir("t", "scratch", "archive-root"));
    isa_ok($newarc, "Test::AutoBuild::Archive::File");

    $newarc->clone_files("mymod", "build", $firstarc);

    ok(-d catdir("t", "scratch", "archive-root", "3", "mymod"), "mymod exists");
    ok(-d catdir("t", "scratch", "archive-root", "3", "mymod", "build"), "mymod build bucket exists");
    is((stat catfile("t", "scratch", "archive-root", "3", "mymod", "build", "VROOT", "one"))->nlink, 1, "has 1 links");
    is((stat catfile("t", "scratch", "archive-root", "3", "mymod", "build", "VROOT", "two"))->nlink, 1, "has 1 links");
    is((stat catfile("t", "scratch", "archive-root", "3", "mymod", "build", "VROOT", "three"))->nlink, 1, "has 1 links");

    $newarc->clone_files("othermod", "build", $oldarc, { link => 1 });

    ok(-d catdir("t", "scratch", "archive-root", "3", "othermod"), "othermod exists");
    ok(-d catdir("t", "scratch", "archive-root", "3", "othermod", "build"), "othermod build bucket exists");
    is((stat catfile("t", "scratch", "archive-root", "3", "othermod", "build", "VROOT", "one"))->nlink, 4, "has 4 links");
    is((stat catfile("t", "scratch", "archive-root", "3", "othermod", "build", "VROOT", "two"))->nlink, 4, "has 4 links");
    is((stat catfile("t", "scratch", "archive-root", "3", "othermod", "build", "VROOT", "three"))->nlink, 4, "has 4 links");
}

sub create_file {
    my $path = shift;
    my $data = shift;

    open FILE, ">$path"
	or die "cannot create $path: $!";
    print FILE $data;
    close FILE
	or die "cannnot save $path: $!";
}
