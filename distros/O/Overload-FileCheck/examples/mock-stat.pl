#!perl

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck q(:all);

# our helper would be called for every stat & lstat calls
mock_stat( \&my_stat );

sub my_stat {
    my ( $opname, $file_or_handle ) = @_;

    # $opname can be 'stat' or 'lstat'
    # in this sample only mock stat, leave lstat alone
    return FALLBACK_TO_REAL_OP() if $opname eq 'lstat';

    my $f = $file_or_handle;    # alias for readability

    # return an array ref with 13 elements containing the stat output
    return [ 1 .. 13 ] if $f eq $0;

    my $fake_stat = [ (0) x 13 ];

    # you also have access to some constants
    # to set the stat values in the correct slot
    # this is using some fake values, without any specific meaning...
    $fake_stat->[ST_DEV]     = 1;
    $fake_stat->[ST_INO]     = 2;
    $fake_stat->[ST_MODE]    = 4;
    $fake_stat->[ST_NLINK]   = 8;
    $fake_stat->[ST_UID]     = 16;
    $fake_stat->[ST_GID]     = 32;
    $fake_stat->[ST_RDEV]    = 64;
    $fake_stat->[ST_SIZE]    = 128;
    $fake_stat->[ST_ATIME]   = 256;
    $fake_stat->[ST_MTIME]   = 512;
    $fake_stat->[ST_CTIME]   = 1024;
    $fake_stat->[ST_BLKSIZE] = 2048;
    $fake_stat->[ST_BLOCKS]  = 4096;

    return $fake_stat if $f eq 'fake.stat';

    # can also retun stats as a hash ref
    return { st_dev => 1, st_atime => 987654321 } if $f eq 'hash.stat';

    return {
        st_dev     => 1,
        st_ino     => 2,
        st_mode    => 3,
        st_nlink   => 4,
        st_uid     => 5,
        st_gid     => 6,
        st_rdev    => 7,
        st_size    => 8,
        st_atime   => 9,
        st_mtime   => 10,
        st_ctime   => 11,
        st_blksize => 12,
        st_blocks  => 13,
    } if $f eq 'hash.stat.full';

    # return an empty array if you want to mark the file as not available
    return [] if $f eq 'file.is.not.there';

    # fallback to the regular OP
    return FALLBACK_TO_REAL_OP();
}

is [ stat($0) ], [ 1 .. 13 ], 'stat is mocked for $0';
is [ stat(_) ], [ 1 .. 13 ],
  '_ also works: your mocked function is not called';

is [ stat('fake.stat') ],
  [ 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096 ], 'fake.stat';

is [ stat('hash.stat.full') ], [ 1 .. 13 ], 'hash.stat.full';

unmock_stat();

done_testing;
