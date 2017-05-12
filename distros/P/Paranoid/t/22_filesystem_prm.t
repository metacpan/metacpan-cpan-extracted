#!/usr/bin/perl -T

use Test::More tests => 9;
use Paranoid;
use Paranoid::Debug;
use Paranoid::Filesystem;
use Paranoid::Glob;

#PDEBUG = 20;

psecureEnv();

use strict;
use warnings;

no warnings qw(qw);

my $glob;
my %errors;

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
    mkdir './t/test_rm';
    mkdir './t/test_rm/foo';
    mkdir './t/test_rm/bar';
    mkdir './t/test_rm/foo/bar';
    mkdir './t/test_rm/foo/bar/roo';
    touch('./t/test_rm/foo/touched');
    symlink 'foo',  './t/test_rm/sym1';
    symlink 'fooo', './t/test_rm/sym2';
}

# start testing
prep();
ok( !prm( './t/test_rm', %errors ), 'prm single 1' );
ok( prm(Paranoid::Glob->new(
            globs => [
                qw(./t/test_rm/bar
                    ./t/test_rm/foo/touched)
                ]
            ),
        %errors
        ),
    'prm glob 1'
    );
touch('./t/test_rm/foo/touched');
ok( prm(Paranoid::Glob->new(
            globs => [
                qw(./t/test_rm/* ./t/test_rm/foo
                    ./t/test_rm/foo/{*/,}*)
                ]
            ),
        %errors
        ),
    'prm glob 2'
    );

# Test recursive function
prep();
ok( prmR( './t/test_rm2/foo', 0, %errors ), 'prmR 1' );
mkdir './t/test_rm2/foo';
symlink '../../test_rm/foo', './t/test_rm2/foo/bar';
ok( prmR( './t/test_rm*', 0, %errors ), 'prmR 2' );
ok( !-d './t/test_rm', 'prmR 3' );

ok( prmR( './t/test_rm_not_there', 0, %errors ), 'prmR 4' );
mkdir './t/test_rm_noperms';
mkdir './t/test_rm_noperms/foo';
SKIP: {
    skip( 'Running as root -- skipping permissions test', 1 );
    chmod 0400, './t/test_rm_noperms';
    ok( !prmR( './t/test_rm_noperms/foo', 0, %errors ), 'prmR 5' );
}
chmod 0755, './t/test_rm_noperms';
ok( prmR( './t/test_rm_noperms', 0, %errors ), 'prmR 6' );

system("rm -rf ./t/test_rm_noperms");

