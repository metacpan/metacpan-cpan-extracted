#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::MockModule;
use File::Temp qw/tempdir/;
use Data::Dumper;


BEGIN {
        use_ok('Tapper::Installer::Base');
        use_ok('Tapper::Installer::Precondition');
}

# setup l4p
use Log::Log4perl;
my $string = "
log4perl.rootLogger           = INFO, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.stderr = 1
log4perl.appender.root.layout = SimpleLayout";
Log::Log4perl->init(\$string);

my $tempdir_base  = tempdir( CLEANUP => 1 );
my $tempdir_guest = tempdir( CLEANUP => 1 );


my @commands;
my $mock_base = Test::MockModule->new('Tapper::Base');
$mock_base->mock('log_and_exec', sub{ shift @_;push @commands, \@_; return 0});


my $base         = Tapper::Installer::Base->new;
my $package_file = 't/misc/packages/debian_package_test.deb';
my $destfile     = '/somefile';
my $config       = {paths => {
                              guest_mount_dir => $tempdir_guest,
                              base_dir        => $tempdir_base,
                             }};
my $precondition = {precondition_type => 'copyfile',
                    name => $package_file,
                    dest => $destfile,
                    protocol => 'local',
                    mountfile => '/tmp/directory/'};



my $copyfile=Tapper::Installer::Precondition::Copyfile->new($config);
my $retval = $copyfile->precondition_install($precondition);
is($retval, 0, 'Installation into flat image without errors');

is_deeply(\@commands, [
                       ["mount -o loop $tempdir_base/tmp/directory/ $tempdir_guest"],
                       ["cp", "--sparse=always", "-r", "-L", $package_file, "$tempdir_guest$destfile"],
                       ["umount $tempdir_guest"],
                       ["kpartx -d /dev/loop0"],
                       ["losetup -d /dev/loop0"],
                      ], "Guest install into flat image");

@commands = ();
# last installation may have changed precondition so we need to set it again
$precondition = {
                 precondition_type => 'copyfile',
                 name => $package_file,
                 dest => $destfile,
                 protocol => 'local',
                 mountfile => '/tmp/directory/',
                 mountpartition => 'p1'
                };
$retval = $copyfile->precondition_install($precondition);
is($retval, 0, 'Installation into image partition without errors');
is_deeply(\@commands,
          [
           ["losetup -d /dev/loop0"],
           ["losetup /dev/loop0 $tempdir_base/tmp/directory/"],
           ["kpartx -a /dev/loop0"],
           ["mount /dev/mapper/loop0p1 $tempdir_guest"],
           ["cp","--sparse=always","-r","-L","t/misc/packages/debian_package_test.deb","$tempdir_guest/somefile"],
           ["umount /dev/mapper/loop0p1"],
           ["kpartx -d /dev/loop0"],
           ["losetup -d /dev/loop0"],
          ], "Guest install into image partition"
         );


@commands = ();
# last installation may have changed precondition so we need to set it again
$precondition = {
                 precondition_type => 'copyfile',
                 name => $package_file,
                 dest => $destfile,
                 protocol => 'local',
                 mountpartition => '/does/not/exist',
                };
$retval = $copyfile->precondition_install($precondition);
is($retval, 0, 'Installation into partition without errors');
is_deeply(\@commands,
          [
           ["mount /does/not/exist $tempdir_guest"],
           ["cp","--sparse=always","-r","-L","t/misc/packages/debian_package_test.deb","$tempdir_guest/somefile"],
           ["umount $tempdir_guest"],
          ], "Guest install into partition"
         );

@commands = ();
# last installation may have changed precondition so we need to set it again
$precondition = {
                 precondition_type => 'copyfile',
                 name => $package_file,
                 dest => $destfile,
                 protocol => 'local',
                 mountdir => '/non/exist',
                };
$retval = $copyfile->precondition_install($precondition);
is($retval, 0, 'Installation into partition without errors');
is_deeply(\@commands,
          [
           ["cp","--sparse=always","-r","-L",$package_file,"$tempdir_base/non/exist$destfile"],
          ], "Guest install into directory"
         );

@commands = ();
# last installation may have changed precondition so we need to set it again
$precondition = {
                 precondition_type => 'copyfile',
                 name => $package_file,
                 dest => $destfile,
                 protocol => 'local',
                };

$retval = $copyfile->precondition_install($precondition);
is($retval, 0, 'Installation into partition without errors');
is_deeply(\@commands,
          [
           ["cp","--sparse=always","-r","-L",$package_file,"$tempdir_base$destfile"],
          ], "Normal install without guest"
         );

my $package=Tapper::Installer::Precondition::Package->new($config);
@commands = ();
# last installation may have changed precondition so we need to set it again
$precondition = {
                 precondition_type => 'package',
                 source_url        => 'nfs://osko:/exports/images/image.tgz',
                };

$retval = $package->precondition_install($precondition);
is($retval, 0, 'Installation of package from NFS without errors');
my $nfs_tempdir = $commands[0][3]; # if we succeed it will ;-)
is_deeply(\@commands,
          [
           [ 'mount', '-t nfs', 'osko:/exports/images/', $nfs_tempdir, ],
           [ "tar --no-same-owner -C $tempdir_base -xzf $nfs_tempdir/image.tgz" ],
           [ 'umount', $nfs_tempdir,]
          ],
          "Installation of package from NFS without errors"
         );

done_testing();
