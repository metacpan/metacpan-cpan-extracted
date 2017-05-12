######################################################################
# Test suite for Sys::Ramdisk
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;
use Test::More;
use Sys::Ramdisk;
use Log::Log4perl qw(:easy);
use Sysadm::Install qw(blurt);
# Log::Log4perl->easy_init($DEBUG);

my $nof_tests = 4;

plan tests => $nof_tests;

my $os = Sys::Ramdisk->os_find();
my $supported = Sys::Ramdisk->os_class_find();
my $uid = $>;

SKIP: {
    if(!$supported) {
        skip "OS '$os' not supported", $nof_tests;
    }

    if(lc $os eq "linux" and $uid != 0) {
        skip "RAM disks to be created as root on Linux - skipping tests", 
             $nof_tests;
    }

    ok($supported, "OS '$os' is supported");

    my $ramdisk = Sys::Ramdisk->new();
    $ramdisk->mount();

    my $dir = $ramdisk->dir();

    ok -d $dir, "Mount directory exists";

    for(1..100) {
        blurt "$_\n", "$dir/$_";
    }

    # print STDERR "dir=$dir\n";
    # <>;

    ok -f "$dir/1", "new file exists";

    undef $ramdisk;
    ok !-f "$dir/1", "Mount directory cleaned up";
}
