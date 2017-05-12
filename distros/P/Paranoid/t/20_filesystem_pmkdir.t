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

my $cmask = umask;
my $glob;

ok( pmkdir('t/test/{ab,cd,ef{1,2}}'), 'pmkdir 1' );
foreach (qw(t/test/ab t/test/cd t/test/ef1 t/test/ef2 t/test)) {
    rmdir $_;
}

SKIP: {
    skip( 'Running as root -- skipping permissions test', 1 ) if $< == 0;
    ok( !pmkdir( 't/test/{ab,cd,ef{1,2}}', 0555 ), 'pmkdir 2' );

}

rmdir 't/test';

$glob = Paranoid::Glob->new( globs => ['t/test/{ab,cd,ef{1,2}}'], );
ok( pmkdir( $glob, 0750 ), 'pmkdir 3' );
my @fstat = stat 't/test/ab';
is( ( $fstat[2] & 07777 ) ^ umask, 0750 ^ umask, 'pmkdir perms 1' );

foreach (qw(t/test/ab t/test/cd t/test/ef1 t/test/ef2 t/test)) {
    rmdir $_;
}

$glob = Paranoid::Glob->new( literals => ['t/test/{ab,cd,ef{1,2}}'], );
ok( pmkdir($glob), 'pmkdir 4' );

{
    no warnings 'qw';
    foreach (qw(t/test/{ab,cd,ef{1,2}} t/test)) { rmdir $_ }
}

ok( !pmkdir(undef), 'pmkdir 5' );
ok( !pmkdir( 't/test', 'mymode' ), 'pmkdir 6' );

ok( pmkdir('t/test_pmkdir/with/many/subdirs'),       'pmkdir 7' );
ok( pmkdir('t/test_pmkdir/with/many/subdirs/again'), 'pmkdir 8' );

system 'rm -rf t/test_pmkdir';

