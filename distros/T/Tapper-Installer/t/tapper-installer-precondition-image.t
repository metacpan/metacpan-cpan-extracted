#! /usr/bin/env perl

use strict;
use warnings;

use Cwd;
use Test::More;
use Test::MockModule;
use File::Temp qw/tempdir/;
use Log::Log4perl;

my $string = "
log4perl.rootLogger           = OFF, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.stderr = 1
log4perl.appender.root.layout = SimpleLayout";
Log::Log4perl->init(\$string);


BEGIN {
        use_ok('Tapper::Installer::Precondition::Image');
 }

my $tempdir = tempdir( CLEANUP => 1 );
my $config = {paths =>
              {
               base_dir  => $tempdir,
               image_dir => $tempdir,
              }
             };

my $precondition = {
                    partition => '/dev/sda2',
                    mount     => '/mountpath/',
                   };

my $image_installer = Tapper::Installer::Precondition::Image->new($config);
my $retval;
SKIP:{
        skip "Can not test get_device since make dist kills symlinks", 3 unless -l "t/misc/dev/disk/by-label/testing";
        $retval = $image_installer->get_device('/dev/hda2','t/misc/');
        is($retval, "/dev/hda2", "Find device from single file without links");

        $retval = $image_installer->get_device('testing','t/misc/');
        is($retval, "/dev/hda2", "Find device from single file with links");

        $retval = $image_installer->get_device(['/dev/sda2','testing'],'t/misc/');
        is($retval, "/dev/hda2", "Find device from file list with links");
}

my $mock_image = Test::MockModule->new('Tapper::Installer::Precondition::Image');
$mock_image->mock('get_device', sub{return(0, '/dev/sda2')});
$mock_image->mock('makedir', sub{return('FAIL')});
$mock_image->mock('log_and_exec', sub{return(wantarray ? (0,0) : 0)});


$retval = $image_installer->install($precondition);
is($retval, 'FAIL', 'Test when makedir fails');


$mock_image->mock('makedir', sub{return(0)});
$mock_image->unmock('makedir');

for (my $i = 1; $i <= 3; $i++) {
        my %precondition = %$precondition;
        $precondition{mount} = "/mount$i";
        $retval = $image_installer->install(\%precondition);
        is($retval, 0, "Install one image without actual image part ($i)");
}

# get a list of images that don't have $basedir.$mount as mount value
my @wrong_mounts =  grep{$_->{mount} !~ m|/mount\d|} @{$image_installer->images};
is_deeply(\@wrong_mounts, [], 'Mounts saved in $self->images');

my @results;
$mock_image->mock('log_and_exec', sub{shift @_; push @results, \@_});
$image_installer->unmount();

for (my $i = 3; $i >= 1; $i--) {
        my $image = shift @results;
        is_deeply($image, ['umount',"$tempdir/mount$i"], "Umount directory ($i)");
}

$precondition->{image} = '/this/image/does/not/exists.tgz';

$retval = $image_installer->install($precondition);
is($retval, "Image "."/this/image/does/not/exists.tgz could not be found", 'Install nonexisting image');



done_testing();
