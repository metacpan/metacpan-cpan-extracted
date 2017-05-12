#!perl

use strict;
use warnings;

use Test::More;
use Sys::Filesystem;

my ( $fs, @filesystems );
eval { $fs = Sys::Filesystem->new(); @filesystems = $fs->filesystems(); };

$@ and plan skip_all => "Cannot initialize Sys::Filesystem: $@";
@filesystems or BAIL_OUT("Badly poor supported OS or no file systems found.");

ok( ref($fs) eq 'Sys::Filesystem', 'Create new Sys::Filesystem object' );

my @mounted_filesystems = $fs->mounted_filesystems();
my @mounted_filesystems2 = $fs->filesystems( mounted => 1 );
ok( "@mounted_filesystems" eq "@mounted_filesystems2", 'Compare mounted methods' );

my @unmounted_filesystems = $fs->unmounted_filesystems();
my @special_filesystems   = $fs->special_filesystems();

my @regular_filesystems = $fs->regular_filesystems();

ok( @regular_filesystems, 'Get list of regular filesystems' );
ok( @filesystems,         'Get list of all filesystems' );

diag( join( ' - ', qw(filesystem mounted special device options format volume label type) ) );
for my $filesystem (@filesystems)
{
    my $mounted = $fs->mounted($filesystem) || 0;
    my $unmounted = !$mounted;
    ok( $mounted == grep( /^\Q$filesystem\E$/, @mounted_filesystems ), 'Mounted' );
    ok( $unmounted == grep( /^\Q$filesystem\E$/, @unmounted_filesystems ), 'Unmounted' );

    my $special = $fs->special($filesystem) || 0;
    my $regular = !$special;
    ok( $special == grep( /^\Q$filesystem\E$/, @special_filesystems ), 'Special' );
    ok( $regular == grep( /^\Q$filesystem\E$/, @regular_filesystems ), 'Regular' );

    my ( $device, $options, $format, $volume, $label, $type );
    ok( $device = $fs->device($filesystem), "Get device for $filesystem" );
    ok( defined( $options = $fs->options($filesystem) ), "Get options for $filesystem: $options" );
  SKIP:
    {
        $format = $fs->format($filesystem);
        $mounted or skip( "Format might be unavailable unless mounted", 1 );
        ok( $format, "Get format for $filesystem" );
    }
    ok( $volume = $fs->volume($filesystem) || 1, "Get volume type for $filesystem" );
    ok( $label  = $fs->label($filesystem)  || 1, "Get label for $filesystem" );

    $type = $fs->type($filesystem);
    diag(
        join( ' - ',
            $filesystem, $mounted, $special, $device, $options,
            $format || 'n/a', $volume || 'n/a', $label || 'n/a', $type || 'n/a' )
    );
}

my $device = $fs->device( $filesystems[0] );
ok( my $foo_filesystem = Sys::Filesystem::filesystems( device => $device ), "Get filesystem attached to $device" );

done_testing();
