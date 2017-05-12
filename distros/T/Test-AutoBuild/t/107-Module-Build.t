# -*- perl -*-

use Test::More tests => 42;
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
my $log_root = catfile($scratch, "log-root");
my $source_root = catfile($scratch, "source-root");
my $install_root = catfile($scratch, "install-root");
my $package_root = catfile($scratch, "package-root");

END {
    rmtree([$scratch])
	unless exists $ENV{DEBUG_TESTS};
}

mkpath([$archive, $log_root, $source_root, $install_root, $package_root]);

my $arcman = Test::AutoBuild::ArchiveManager::File->new(options => {
    "archive-dir" => $archive
    });
$arcman->create_archive("1");

my $counter = MyCounter->new();
$counter->set(1);

my $runtime = Test::AutoBuild::Runtime->new("install_root" => $install_root,
					    "package_root" => $package_root,
					    "source_root" => $source_root,
					    "log_root" => $log_root,
					    package_types => {
						rpm => Test::AutoBuild::PackageType->new(name => "rpm",
											 label => "RPM",
											 extension => "rpm",
											 spool => catfile($package_root, "rpm")),
					    },
					    counter => $counter,
					    timestamp => 123,
					    archive_manager => $arcman);

# Clean out existing autouild env vars inherited from local env
foreach (grep { /^AUTO/ } keys %ENV) {
    delete $ENV{$_};
}

SHELL_ENV: {
    mkpath([catdir($source_root, "mymod")]);

    open CTL, ">" . catfile($source_root, "mymod", "autobuild.sh")
	or die "cannot create autobuild.sh: $!";
    print CTL <<EOF;
#!/bin/sh

pwd
echo \$1
echo \$AUTOBUILD_SOURCE_ROOT
echo \$AUTOBUILD_INSTALL_ROOT
echo \$AUTOBUILD_PACKAGE_ROOT
echo \$AUTOBUILD_COUNTER
echo \$AUTOBUILD_TIMESTAMP
echo \$AUTOBUILD_MODULE
echo \$AUTO_BUILD_ROOT
echo \$AUTO_BUILD_COUNTER
EOF

    close CTL;
    chmod 0755, catfile($source_root, "mymod", "autobuild.sh");

    my $module = Test::AutoBuild::Module->new(name => "mymod",
					      label => "My Module",
					       sources => [
							   {
							       repository => "myrepo",
							       path => "mypath",
							   },
							   ],
					      );
    $module->_add_result("checkout", "success");

    my $res = $module->invoke_shell($runtime,
				    "autobuild.sh",
				    catfile($log_root, "mymod-output.log"),
				    [catfile($log_root, "mymod-result.log")]);
    is($res, 0, "result is 0");

    ok(-f catfile($log_root, "mymod-output.log"), "output log exists");

    open LOG, catfile($log_root, "mymod-output.log")
	or die "cannot read output log: $!";
    my @lines = map { chomp $_ ; $_ } <LOG>;
    close LOG;

    is(int(@lines),  10, "10 lines of output");
    is($lines[0], catdir($source_root, "mymod"), "source root matches");
    is($lines[1], catdir($log_root, "mymod-result.log"), "results log file matches");
    is($lines[2], $source_root, "source root matches");
    is($lines[3], $install_root, "install root matches");
    is($lines[4], $package_root, "package root matches");
    is($lines[5], 1, "counter is 1");
    is($lines[6], 123, "timestamp is 123");
    is($lines[7], "mymod", "name is mymod");
    is($lines[8], $install_root, "legacy build root is set");
    is($lines[9], 1, "legacy counter is set");

    link catfile($source_root, "mymod", "autobuild.sh"),
	 catfile($source_root, "mymod", "rollingbuild.sh");

    unlink catfile($log_root, "mymod-output.log");
    unlink catfile($log_root, "mymod-result.log");
}

BUILD_PASS: {
    my $module = Test::AutoBuild::Module->new(name => "othermod",
					      label => "My Module",
					       sources => [
							   {
							       repository => "myrepo",
							       path => "mypath",
							   },
							   ],
					      );
    $module->_add_result("checkout", "success");

    mkpath([catdir($source_root, "othermod")]);

    open CTL, ">" . catfile($source_root, "othermod", "autobuild.sh")
	or die "cannot create autobuild.sh: $!";
    print CTL <<EOF;
#!/bin/sh

mkdir \$AUTOBUILD_INSTALL_ROOT/foo
touch \$AUTOBUILD_INSTALL_ROOT/foo/bar.txt
touch \$AUTOBUILD_INSTALL_ROOT/foo/wizz.txt
touch \$AUTOBUILD_INSTALL_ROOT/foo/eek.txt

mkdir \$AUTOBUILD_PACKAGE_ROOT/rpm
touch \$AUTOBUILD_PACKAGE_ROOT/rpm/foo.rpm
mkdir \$AUTOBUILD_PACKAGE_ROOT/rpm/bar.txt
exit 0
EOF

    close CTL;
    chmod 0755, catfile($source_root, "othermod", "autobuild.sh");

    $module->build($runtime, "autobuild.sh");

    is($module->status, "success", "status is success");
    my $installed = $module->installed();
    ok(exists $installed->{catfile($install_root, "foo", "bar.txt")}, "foo/bar.txt exists");
    ok(exists $installed->{catfile($install_root, "foo", "wizz.txt")}, "foo/bar.txt exists");
    ok(exists $installed->{catfile($install_root, "foo", "eek.txt")}, "foo/bar.txt exists");

    my $packages = $module->packages();
    ok(exists $packages->{catfile($package_root, "rpm", "foo.rpm")}, "rpm/foo.rpm exists");
    ok(!exists $packages->{catfile($package_root, "rpm", "bar.txt")}, "rpm/bar.txt does not exist");

    $module->packages({});
    $module->installed({});
    $module->{results} = { 'build' => { 'status' => 'pending'},
			   'checkout' => { 'status' => 'pending'} };
    $module->_add_result("checkout", "success");

    $arcman->create_archive("2");
    $module->build($runtime, "autobuild.sh");
    is($module->build_status, "cached", "status is cached");

    $installed = $module->installed();
    ok(exists $installed->{catfile($install_root, "foo", "bar.txt")}, "foo/bar.txt exists");
    ok(exists $installed->{catfile($install_root, "foo", "wizz.txt")}, "foo/bar.txt exists");
    ok(exists $installed->{catfile($install_root, "foo", "eek.txt")}, "foo/bar.txt exists");

    $packages = $module->packages();
    ok(exists $packages->{catfile($package_root, "rpm", "foo.rpm")}, "rpm/foo.rpm exists");
    ok(!exists $packages->{catfile($package_root, "rpm", "bar.txt")}, "rpm/bar.txt does not exist");

#    $module->test($runtime, "wizz", "autotest-wizz.sh");
}

BUILD_FAIL: {
    my $module = Test::AutoBuild::Module->new(name => "failmod",
					      label => "My Module",
					      sources => [
							  {
							      repository => "myrepo",
							      path => "mypath",
							  },
							  ],
					      );
    $module->_add_result("checkout", "success");

    mkpath([catdir($source_root, "failmod")]);

    open CTL, ">" . catfile($source_root, "failmod", "autobuild.sh")
	or die "cannot create autobuild.sh: $!";
    print CTL <<EOF;
#!/bin/sh

mkdir \$AUTOBUILD_INSTALL_ROOT/bar
touch \$AUTOBUILD_INSTALL_ROOT/bar/bar.txt

mkdir \$AUTOBUILD_PACKAGE_ROOT/rpm
touch \$AUTOBUILD_PACKAGE_ROOT/rpm/bar.rpm
exit 1
EOF

    close CTL;
    chmod 0755, catfile($source_root, "failmod", "autobuild.sh");

    $arcman->create_archive("3");

    $module->build($runtime, "autobuild.sh");

    is($module->status, "failed", "status is failed");
    my $installed = $module->installed();
    ok(!exists $installed->{catfile($install_root, "bar", "bar.txt")}, "foo/bar.txt does not exist");

    my $packages = $module->packages();
    ok(!exists $packages->{catfile($package_root, "rpm", "bar.rpm")}, "rpm/bar.txt does not exist");

    $module->status("pending");
    $module->{results} = {};
    $module->_add_result("checkout", "success");

    $arcman->create_archive("4");
    $module->build($runtime, "autobuild.sh");

    is($module->status, "failed", "status is failed");
    $installed = $module->installed();
    ok(!exists $installed->{catfile($install_root, "bar", "bar.txt")}, "foo/bar.txt does not exist");

    $packages = $module->packages();
    ok(!exists $packages->{catfile($package_root, "rpm", "bar.rpm")}, "rpm/bar.txt does not exist");
}

TESTS: {
    my $module = Test::AutoBuild::Module->new(name => "testmod",
					      label => "My Module",
					      sources => [
							  {
							      repository => "myrepo",
							      path => "mypath",
							  },
							  ],
					      );
    $module->_add_result("checkout", "success");

    mkpath([catdir($source_root, "testmod")]);

    open CTL, ">" . catfile($source_root, "testmod", "autotest-a.sh")
	or die "cannot create autotest-a.sh: $!";
    print CTL <<EOF;
#!/bin/sh
exit 0
EOF

    close CTL;
    chmod 0755, catfile($source_root, "testmod", "autotest-a.sh");


    open CTL, ">" . catfile($source_root, "testmod", "autotest-b.sh")
	or die "cannot create autotest-b.sh: $!";
    print CTL <<EOF;
#!/bin/sh
exit 1
EOF

    close CTL;
    chmod 0755, catfile($source_root, "testmod", "autotest-b.sh");

    $module->build($runtime, "/bin/true");

    $module->test($runtime, "a", "autotest-a.sh");
    is($module->test_status("a"), "success", "test status is success");
    is($module->status, "success", "status is success");


    $module->test($runtime, "b", "autotest-b.sh");
    is($module->test_status("b"), "failed", "test status is failed");
    is($module->status, "failed", "status is failed");
}

BOGUS_CONTROLFILE: {
    my $module = Test::AutoBuild::Module->new(name => "testmodfail",
					      label => "My Module",
					      sources => [
							  {
							      repository => "myrepo",
							      path => "mypath",
							  },
							  ],
					      );
    $module->_add_result("checkout", "success");

    mkpath([catdir($source_root, "testmodfail")]);
    my $cf = catfile($source_root, "testmodfail", "this-must-not-exist.sh");

    $module->build($runtime, $cf);
    is($module->status, "failed", "status is failed");
    my $log = catfile($log_root, $module->build_output_log_file);
    open LOG, "<$log" or die "cannot read $log: $!";
    my $logdata = <LOG>;
    close LOG;
    my $there = catdir($source_root, "testmodfail");

    ok($logdata =~ /^cannot find control file '$cf'/,
       "got control file failure");
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

package MyCounter;

use base qw(Test::AutoBuild::Counter);

sub generate {
    my $self = shift;
    return $self->{value};
}

sub set {
    my $self = shift;
    $self->{value} = shift;
}
