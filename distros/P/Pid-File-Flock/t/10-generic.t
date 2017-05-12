#!perl

use strict;
use warnings;

use Test::More tests => 4;
use File::Basename qw(basename);
use Pid::File::Flock;

my $pf = basename($0).'.pid';

ok( Pid::File::Flock->new($pf), 'pid file new' );
ok( -f $pf, 'pid file creating' );

SKIP: {
	skip "on $^O",1 if $^O eq 'MSWin32';
	ok( do { open FH,$pf and <FH> } eq $$, 'pid file content' );
}

Pid::File::Flock::release;

ok( ! -f $pf, 'pid file removing' );

