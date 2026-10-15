#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Fcntl      qw(:flock);

use OSLV::Monitor;

plan tests => 12;

# stands in for a backend so this does not depend on the OS
{

	package OSLV::Monitor::Backends::TestDummy;
	sub new { my $self = { runs => 0 }; bless $self; return $self; }
	sub run { $_[0]{runs}++; return { oslvms => {} }; }
}

my $base_dir = tempdir( CLEANUP => 1 );

#
# lock is off by default and nothing is locked
#

my $monitor = OSLV::Monitor->new( base_dir => $base_dir );
$monitor->{backend_mod} = OSLV::Monitor::Backends::TestDummy->new;
my $status = $monitor->run;
is( $status->{error},      0, 'a run without lock works' );
is( $monitor->lock_failed, 0, 'lock_failed is 0 without lock' );
ok( !-e $base_dir . '/lock', 'no lock file is created without lock' );

#
# with lock and nothing else holding it
#

$monitor = OSLV::Monitor->new( base_dir => $base_dir, lock => 1 );
$monitor->{backend_mod} = OSLV::Monitor::Backends::TestDummy->new;
$status = $monitor->run;
is( $status->{error},      0, 'a run with lock works when it is free' );
is( $monitor->lock_failed, 0, 'lock_failed is 0 when the lock was taken' );
ok( -e $base_dir . '/lock', 'the lock file is created' );

#
# with lock while something else holds it... flock locks are per open file, so
# a second open of it in this process conflicts the same as another process
#

open( my $held_fh, '>>', $base_dir . '/lock' ) || die($!);
flock( $held_fh, LOCK_EX ) || die($!);

$monitor->{backend_mod} = OSLV::Monitor::Backends::TestDummy->new;
$status = $monitor->run;
is( $status->{error},            1, 'a run with the lock held errors' );
like( $status->{errorString}, qr/holds the lock/, 'the error says the lock is held' );
is( $monitor->lock_failed,       1, 'lock_failed is 1 when the lock is held' );
is( $monitor->{backend_mod}{runs}, 0, 'the backend is not run when the lock is held' );

#
# once released, the next run takes it and lock_failed is reset
#

close($held_fh);

$status = $monitor->run;
is( $status->{error},      0, 'a run works once the lock is released' );
is( $monitor->lock_failed, 0, 'lock_failed is reset by the next run' );
