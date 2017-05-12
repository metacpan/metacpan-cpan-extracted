#!/usr/bin/perl -T

use Test::More tests => 18;
use Paranoid;
use Paranoid::Debug;
use Paranoid::Filesystem;

#PDEBUG = 20;

psecureEnv();

use strict;
use warnings;

no warnings qw(qw);

my @tmp;

sub touch {
    my $filename = shift;
    my $size = shift || 0;
    my $fh;

    open $fh, '>', $filename or die "Couldn't touch file $filename: $!\n";
    while ( $size - 80 > 0 ) {
        print $fh 'A' x 79, "\n";
        $size -= 80;
    }
    print $fh 'A' x $size;
    close $fh;
}

sub prep {
    mkdir './t/test_fs',         0777;
    mkdir './t/test_fs/subdir',  0777;
    mkdir './t/test_fs/subdir2', 0777;
    touch('t/test_fs/one');
    touch('t/test_fs/two');
    touch('t/test_fs/subdir/three');
}

# start testing
prep();

ok( preadDir( './t/test_fs', @tmp ), 'preadDir 1' );
is( $#tmp, 3,, 'preadDir 2' );
ok( !preadDir( './t/test_fsss', @tmp ), 'preadDir 3' );
is( $#tmp, -1,, 'preadDir 4' );
ok( !preadDir( './t/test_fs/one', @tmp ), 'preadDir 5' );
ok( Paranoid::ERROR =~ /is not a dir/, 'preadDir 6' );
ok( psubdirs( './t/test_fs', @tmp ), 'psubdirs 1' );
is( $#tmp, 1,, 'psubdirs 2' );
ok( psubdirs( './t/test_fs/subdir', @tmp ), 'psubdirs 3' );
is( $#tmp, -1,, 'psubdirs 4' );
ok( !psubdirs( './t/test_fs/ssubdir', @tmp ), 'psubdirs 5' );
is( $#tmp, -1,, 'psubdirs 6' );
ok( pfiles( './t/test_fs', @tmp ), 'pfiles 1' );
is( $#tmp, 1,, 'pfiles 2' );
ok( !pfiles( './t/test_fss', @tmp ), 'pfiles 3' );
is( $#tmp, -1,, 'pfiles 4' );
ok( pfiles( './t/test_fs/subdir2', @tmp ), 'pfiles 5' );
is( $#tmp, -1,, 'pfiles 6' );

# Clean up files
unlink qw(t/test_fs/one t/test_fs/two t/test_fs/subdir/three);
rmdir './t/test_fs/subdir'  || warn "subdir: $!\n";
rmdir './t/test_fs/subdir2' || warn "subdir2: $!\n";
rmdir './t/test_fs'         || warn "test_fs: $!\n";

