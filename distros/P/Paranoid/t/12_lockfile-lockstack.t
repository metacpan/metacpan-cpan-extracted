#!/usr/bin/perl -T

use Test::More tests => 6;
use Paranoid;
use Paranoid::IO qw(PIOLOCKSTACK);
use Paranoid::IO::Lockfile;
use Fcntl qw(:flock);

use strict;
use warnings;

psecureEnv();

PIOLOCKSTACK = 1;

my $lfile = 't/test.lock';

ok( plock( $lfile, LOCK_EX, 0666 ), 'plock excluse 1' );
ok( plock($lfile), 'plock exclusive 2' );
ok( plock( $lfile, LOCK_SH ), 'plock share 1' );
ok( pexclock($lfile), 'pexclock 1' );
ok( pshlock($lfile),  'pshclock 1' );
ok( punlock($lfile),  'punlock 1' );

unlink $lfile;
