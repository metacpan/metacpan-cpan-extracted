# -*- perl -*-

use Test::More tests => 20;
use warnings;
use strict;
use Log::Log4perl;
use Cwd;
use File::Spec::Functions;
use File::Path;

BEGIN {
  use_ok("Test::AutoBuild::Module");
  use_ok("Test::AutoBuild::PackageType");
  use_ok("Test::AutoBuild::Lib");
  use_ok("Test::AutoBuild::ArchiveManager::File");
  use_ok("Test::AutoBuild::Runtime");
}

Log::Log4perl::init("t/log4perl.conf");

my $here = getcwd;
my $scratch = catfile($here, "t", "scratch");
rmtree([$scratch]);

my $archive = catfile($scratch, "archive");
my $install_root = catfile($scratch, "install-root");
my $package_root = catfile($scratch, "package-root");
my $log_root = catfile($scratch, "log-root");

END {
    rmtree([$scratch])
	unless exists $ENV{DEBUG_TESTS};
}

mkpath([$archive, $install_root,$package_root]);

ARCHIVING: {
    my $module1 = Test::AutoBuild::Module->new(name => "mymod",
					       label => "My Module",
					       sources => [
							   {
							       repository => "myrepo",
							       path => "mypath",
							   },
							   ],
					       );
    my $module2 = Test::AutoBuild::Module->new(name => "mymod",
					       label => "My Module",
					       sources => [
							   {
							       repository => "myrepo",
							       path => "mypath",
							   },
							   ],
					       );

    my $arcman = Test::AutoBuild::ArchiveManager::File->new(options => {
	"archive-dir" => $archive
	});
    $arcman->create_archive("1");

    my $counter = MyCounter->new();

    my $runtime = Test::AutoBuild::Runtime->new("install_root" => $install_root,
						"package_root" => $package_root,
						package_types => {
						    rpm => Test::AutoBuild::PackageType->new(name => "rpm",
											     label => "RPM",
											     extension => "rpm",
											     spool => catfile($package_root, "rpm")),
						},
						counter => $counter,
						archive_manager => $arcman);

    my $before_install = $runtime->installed_snapshot();
    my $before_package = $runtime->package_snapshot();

    mkpath([catdir($install_root, "foo"),
	    catdir($package_root, "rpm")]);

    my $bar1 = save_file($install_root, catfile("foo", "bar1.txt"), "bar1");
    my $bar2 = save_file($install_root, catfile("foo", "bar2.txt"), "bar2");
    my $bar3 = save_file($install_root, catfile("foo", "bar3.txt"), "bar3");
    my $bar4 = save_file($install_root, catfile("foo", "bar4.txt"), "bar4");

    my $pkg1 = save_file($package_root, catfile("rpm", "pkg1.rpm"), "pkg1");
    my $pkg2 = save_file($package_root, catfile("rpm", "pkg2.rpm"), "pkg2");
    my $pkg3 = save_file($package_root, catfile("rpm", "pkg3.rpm"), "pkg3");
    my $pkg4 = save_file($package_root, catfile("rpm", "pkg4.rpm"), "pkg4");

    my $link1 = save_link(catfile($install_root, "foo","link1.txt"), catfile($install_root, "foo", "bar1.txt"));
    my $link2 = save_link(catfile($install_root, "foo","link2.txt"), "bar1.txt");
    my $link3 = save_link(catfile($install_root, "foo","link3.txt"), "bogus1.txt");

    my $after_install = $runtime->installed_snapshot();
    my $after_package = $runtime->package_snapshot();

    $module1->installed(Test::AutoBuild::Lib::new_packages($before_install,
							  $after_install));
    $module1->packages(Test::AutoBuild::Lib::new_packages($before_package,
							 $after_package));

    my $now = time;
    sleep 2;
    my $then = time;
    sleep 2;
    $module1->_add_result("build", "success", $now, $then);

    my $archive = $runtime->archive;

    $module1->archive_result($runtime, $archive, "build");

    rmtree([catdir($install_root, "foo"),
	    catdir($package_root, "rpm")]);

    ok($module1->archive_usable($runtime, $archive, "build"), "archive is usuable");

    ok($module2->archive_usable($runtime, $archive, "build"), "archive is usuable");

    $module2->unarchive_result($runtime, $archive, "build");

    is($module2->build_status, "cached", "status is cached");
    is($module2->build_start_date, $now, "start time matches");
    is($module2->build_end_date, $then, "end time matches");

    is_deeply($module1->installed,
	      $module2->installed,
	      "restored files match original");

    is_deeply($module1->packages,
	      $module2->packages,
	      "restored packages match original");

    ok(-f catfile($install_root, "foo", "bar1.txt"), "foo/bar1.txt has been restored");
    ok(-f catfile($install_root, "foo", "bar2.txt"), "foo/bar2.txt has been restored");
    ok(-f catfile($install_root, "foo", "bar3.txt"), "foo/bar3.txt has been restored");
    ok(-f catfile($install_root, "foo", "bar4.txt"), "foo/bar4.txt has been restored");

    ok(-f catfile($package_root, "rpm", "pkg1.rpm"), "rpm/pkg1.rpm has been restored");
    ok(-f catfile($package_root, "rpm", "pkg2.rpm"), "rpm/pkg2.rpm has been restored");
    ok(-f catfile($package_root, "rpm", "pkg3.rpm"), "rpm/pkg3.rpm has been restored");
    ok(-f catfile($package_root, "rpm", "pkg4.rpm"), "rpm/pkg4.rpm has been restored");
}

sub save_file {
    my $dir = shift;
    my $file = shift;
    my $data = shift;

    my $dst = catfile($dir, $file);
    open DST, ">$dst"
	or die "cannot create $dst: $!";
    print DST $data;
    close DST;

    return $dst;
}

sub save_link {
    my $dst = shift;
    my $src = shift;

    symlink $src, $dst or die "cannot link $src to $dst: $!";
}

package MyCounter;

use base qw(Test::AutoBuild::Counter);

sub generate {
    my $self = shift;
    return 1;
}
