#!perl

use strict;
use warnings;

use Test::More;
use Sys::Filesystem;

delete @ENV{qw(CANONDEV FSTAB MTAB)};

my ( $fs, @filesystems );
eval { $fs = Sys::Filesystem->new(); };

$@ and plan skip_all => "Cannot initialize Sys::Filesystem: $@";
@filesystems = $fs->filesystems;

my %devsymlinks;
for my $filesystem (@filesystems)
{
    my $device = $fs->device($filesystem);
    -l $device and $devsymlinks{$filesystem} = $device;
}

$fs = Sys::Filesystem->new( canondev => 1 );
@filesystems = $fs->filesystems;

for my $filesystem (@filesystems)
{
    my $device = $fs->device($filesystem);
    ok( !-l $device, "$device is not a symlink (canondev => 1)" );
}

SCOPE:
{
    local $Sys::Filesystem::CANONDEV = 0;
    $fs          = Sys::Filesystem->new();
    @filesystems = $fs->filesystems;
    my %symdevs;
    for my $filesystem (@filesystems)
    {
        my $device = $fs->device($filesystem);
        -l $device and $symdevs{$filesystem} = $device;
    }
    is_deeply( \%symdevs, \%devsymlinks, "\$S::F::CANONDEV = 0 works as expected" );
}

SCOPE:
{
    local $Sys::Filesystem::CANONDEV = 1;
    $fs          = Sys::Filesystem->new();
    @filesystems = $fs->filesystems;
    for my $filesystem (@filesystems)
    {
        my $device = $fs->device($filesystem);
        ok( !-l $device, "$device is not a symlink (\$S::F::CANONDEV = 1)" );
    }
}

# Testing $S::F::MTAB and/or $S::F::FSTAB is pointless - half of the
# plugins ignore at least one, likely both

# devnull

done_testing;
