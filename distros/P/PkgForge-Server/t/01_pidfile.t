#!/usr/bin/perl
use strict;
use warnings;

use File::Temp;
use Test::More;
use Test::File;
use Test::Exception;

use PkgForge::PidFile;

my $pidfile1 = PkgForge::PidFile->new();

isa_ok( $pidfile1, 'PkgForge::PidFile' );

is( $pidfile1->pid, $$, 'default process ID' );

my $dir = File::Temp::tempdir( CLEANUP => 1 );

my $pidfile2 = PkgForge::PidFile->new( basedir  => $dir,
                                      progname => 'test2',
                                      pid      => 99999 );

is( $pidfile2->basedir, $dir, 'base directory set correctly' );
is( $pidfile2->progname, 'test2', 'program name set correctly' );
is( $pidfile2->pid, 99999, 'process ID set correctly' );

is( $pidfile2->is_running, 0, 'Test process is not running' );

is( $pidfile2->file, "$dir/test2.pid", 'PID file name correctly generated' );

is( $pidfile2->does_file_exist, 0, 'non-existent PID file' );

is( $pidfile2->remove, 1, 'does not explode when removing non-existent file' );

{
my $fh = IO::File->new( "$dir/test3.pid", 'w' ) or die "$!";
$fh->print("$$\n") or die "$!";
$fh->close or die "$!";
}

my $pidfile3 = PkgForge::PidFile->new( basedir  => $dir,
                                       progname => 'test3' );

is( $pidfile3->pid, $$, 'PID default correct' );

is( $pidfile3->does_file_exist, 1, 'Check PID file existence' );

is( $pidfile3->is_running, 1, 'Test process is running' );

is( $pidfile3->remove, 1, 'file removal' );

is( $pidfile3->does_file_exist, 0, 'Check PID file existence again' );

my $pidfile4 = PkgForge::PidFile->new( basedir  => $dir,
                                       progname => 'test4' );

is( $pidfile4->pid, $$, 'PID default correct' );
is( $pidfile4->file, "$dir/test4.pid", 'PID file name correctly generated' );

is( $pidfile4->store, 1, 'call store()' );

file_exists_ok( "$dir/test4.pid", 'pidfile exists' );
file_line_count_is(  "$dir/test4.pid", 1, 'pidfile line count' );
file_mode_is( "$dir/test4.pid", $pidfile4->mode, 'pidfile mode' );

is( $pidfile4->does_file_exist, 1, 'Check PID file existence' );

is( $pidfile4->is_running, 1, 'Test process is running' );

dies_ok { $pidfile4->store } 'exclusive file access';

{
my $fh = IO::File->new( "$dir/test5.pid", 'w' ) or die "$!";
$fh->print("foo\n") or die "$!";
$fh->close or die "$!";
}

my $pidfile5 = PkgForge::PidFile->new( basedir  => $dir,
                                       progname => 'test5' );

throws_ok { $pidfile5->pid } qr/^Failed to parse contents of PID file/, 'fails on bad input';

done_testing();
