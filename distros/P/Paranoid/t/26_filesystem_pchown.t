#!/usr/bin/perl -T

use Test::More tests => 15;
use Paranoid;
use Paranoid::Debug;
use Paranoid::Filesystem qw(:all);
use Paranoid::Glob;
use Paranoid::Process qw(ptranslateUser ptranslateGroup);

#PDEBUG = 20;

psecureEnv();

use strict;
use warnings;

no warnings qw(qw);

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

my ( $user, $group, $uid, $gid, $id, %errors );
mkdir './t/test_chown';
mkdir './t/test_chown2';
mkdir './t/test_chown2/foo';
symlink '../../test_chown', './t/test_chown2/foo/bar';
touch('./t/test_chown/foo');
touch('./t/test_chown/bar');

$user  = 'nobody';
$uid   = ptranslateUser($user);
$group = 'nogroup';
$gid   = ptranslateGroup($group);
unless ( defined $gid ) {
    $group = 'nobody';
    $gid   = ptranslateGroup($group);
}

# NOTE: The following block is skipped due to a bug in all current
# version of Perl involving platforms with unsigned ints for GIDs.  A patch
# has been submitted to bleadperl to fix it.
SKIP: {
    skip( 'Bug in some perls UINT in GIDs', 15 ) unless $] >= 5.010;
    skip( 'Non-root user running tests',    15 ) unless $< == 0;
    skip( 'Failed to resolve nobody/nogroup to test with', 15 )
        unless defined $uid and defined $gid;
    ok( pchown( "./t/test_chown/*", $user ), 'pchown no group 1' );
    $id = ( stat "./t/test_chown/foo" )[4];
    is( $id, $uid, 'pchown no group 2' );
    ok( pchown( "./t/test_chown/*", undef, $group ), 'pchown no user 1' );
    $id = ( stat "./t/test_chown/foo" )[5];
    is( $id, $gid, 'pchown no user 2' );
    ok( pchown( "./t/test_chown/*", 0, 0, %errors ), 'pchown both 1' );
    ok( pchownR( "./t/test_chown2", $user ), 'pchownR no group/no follow 1' );
    $id = ( stat "./t/test_chown2/foo" )[4];
    is( $id, $uid, 'pchownR no group/no follow 2' );
    $id = ( stat "./t/test_chown/foo" )[4];
    is( $id, 0, 'pchownR no group/no follow 3' );
    ok( pchown( "./t/test_chown/*", 0, 0 ), 'pchown both 2' );
    ok( pchownR( "./t/test_chown2", -1, $group, 1, %errors ),
        'pchownR no user/follow 1' );
    $id = ( stat "./t/test_chown2/foo" )[5];
    is( $id, $gid, 'pchownR no user/follow 2' );
    $id = ( stat "./t/test_chown/foo" )[5];
    is( $id, $gid, 'pchownR no user/follow 3' );
    $id = ( stat "./t/test_chown/foo" )[4];
    is( $id, 0, 'pchownR no user/follow 4' );
    ok( !pchown( "./t/test_chown2/roo", -1, $group, %errors ),
        'pchown no user 2' );
    ok( !pchownR( "./t/test_chown2/roo", -1, $group, 1, %errors ),
        'pchownR no user/follow 5' );
}

system('rm -rf ./t/test_chown* 2>/dev/null');

