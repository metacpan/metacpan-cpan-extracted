#! /usr/bin/env perl

use strict;
use warnings;
use 5.010;

use Test::More;
use File::Temp qw/tempdir/;
use Test::MockModule;
use Test::Deep;
use Cwd;
use Log::Log4perl;

my $string = "
log4perl.rootLogger           = WARN, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.stderr = 1
log4perl.appender.root.layout = SimpleLayout";
Log::Log4perl->init(\$string);


use subs qw/chroot chdir/;
sub chroot { return;}
sub chdir  { return; }

my $tempdir = tempdir( CLEANUP => 1 );
my $config = {paths =>
              {
               base_dir => $tempdir,
               package_dir => getcwd(),
              }

             };


BEGIN {
        use_ok('Tapper::Installer::Precondition::Package');
}


my $pkg_precondition = {
                         filename => 't/misc/packages/debian_package_test.deb',
                        };

my $module = Test::MockModule->new('Tapper::Installer::Precondition::Exec');
$module->mock('file_save', sub {return 0});
$module->mock('log_and_exec', sub { return 0;});


my $pkg_installer = Tapper::Installer::Precondition::Package->new($config);
my $retval = $pkg_installer->install($pkg_precondition);
is($retval, 0, 'Package installed');

my @exec;
my $mock_package = Test::MockModule->new('Tapper::Installer::Precondition::Package');
$mock_package->mock('makedir', sub { return 0; });
$mock_package->mock('log_and_exec', sub { shift @_; push @exec, @_; return 0;});

$pkg_precondition = { url => 'nfs://osko:/path/to/debian_package_test.tgz', };
$retval = $pkg_installer->install($pkg_precondition);
is($retval, 0, 'Package installed');
cmp_deeply(\@exec, supersetof("mount osko:/path/to /mnt/nfs",
                              "umount /mnt/nfs"), 'Mount and umount NFS');

done_testing();
