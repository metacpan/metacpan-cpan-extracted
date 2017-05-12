#!perl

use strict;
use warnings;

use Test::More;
use Sys::Filesystem;

my $fs;
eval { $fs = Sys::Filesystem->new(); };

$@ and plan skip_all => "Cannot initialize Sys::Filesystem: $@";

ok( ref($fs) eq 'Sys::Filesystem', 'Create new Sys::Filesystem object' );

my @special_filesystems = $fs->special_filesystems();
my @regular_filesystems = $fs->regular_filesystems();

SKIP:
{

    skip( 'Badly poor supported OS or no file systems found.', 0 ) unless (@regular_filesystems);
    ok( @regular_filesystems, 'Get list of regular filesystems' );

    for my $filesystem (@regular_filesystems)
    {
        my $special = $fs->special($filesystem) || 0;
        ok( !$special, "Regular" );
    }
}

SKIP:
{

    skip( 'Badly poor supported OS or no file systems found.', 0 ) unless (@special_filesystems);
    ok( @special_filesystems, 'Get list of regular filesystems' );

    for my $filesystem (@special_filesystems)
    {
        my $special = $fs->special($filesystem) || 0;
        ok( $special, "Special" );
    }
}

done_testing();
