#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::MockModule;
use File::Temp qw/tempdir/;

BEGIN { use_ok('Tapper::Installer::Precondition');
        use_ok('Tapper::Installer::Precondition::Image');
        use_ok('Tapper::Installer::Base');
}

my $mock_base = Test::MockModule->new('Tapper::Base');

{
        # testing gethostname with an IP address will try to set the hostname
        # this may cause problems if tester is root and thus can set the hostname
        my $sys_hostname = new Test::MockModule('Sys::Hostname');
        $sys_hostname->mock('hostname', sub { return 'bascha' });

        my $inst=new Tapper::Installer::Precondition;
        is (Sys::Hostname::hostname(), 'bascha', 'mocking worked');
        is ($inst->gethostname(), 'bascha', "gethostname by ip");
}

# get_file_type checks in two ways.
# First it analyses the file suffix. For this, the file does not need to exists.
my $inst_base = new Tapper::Installer::Precondition;
is ($inst_base->get_file_type('/tmp/1.iso'), 'iso', 'Detected ISO using extenstion.');
is ($inst_base->get_file_type('/tmp/2.tar.gz'), 'gzip', 'Detected tar.gz using extension.');
is ($inst_base->get_file_type('/tmp/3.tgz'), 'gzip', 'Detected tgz using extension.');
is ($inst_base->get_file_type('/tmp/4.tar'), 'tar', 'Detected tar using extension.');

# second way of get_file_type -> analyse using file magic

is ($inst_base->get_file_type('t/file_type/targzfile'), 'gzip', 'Detected tar.gz using file type.');
is ($inst_base->get_file_type('t/file_type/tarbz2file'), 'bz2', 'Detected bzip using file type.');
is ($inst_base->get_file_type('t/file_type/tarfile'), 'tar', 'Detected tar using file.');

my $grub_dir   = tempdir( CLEANUP => 1 );
my $config     = {paths => {grubpath => $grub_dir}};
my $inst_image = Tapper::Installer::Precondition::Image->new($config);
my $retval;

$mock_base->mock('log_and_exec', sub{ return });
my $base = Tapper::Installer::Base->new();
$retval = $base->free_loop_device();
ok(!$retval, 'free_loop_device');


done_testing();
