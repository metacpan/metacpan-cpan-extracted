#!/usr/bin/perl -T

use Test::More tests => 52;
use Paranoid;
use Paranoid::Debug;
use Paranoid::IO qw(:all);
use Fcntl qw(:DEFAULT :seek :flock :mode);

use strict;
use warnings;

psecureEnv();
PIOLOCKSTACK = 1;

my $f    = 't/test_io.txt';
my $rlen = length "0000\n";
my ( @tmp, $text, $fh, $rv );

# Pre-emptive cleanup
unlink $f if -f $f;

# Calls on unopened files
ok( pclose($f), 'unopened 1' );
ok( !ptell($f), 'unopened 2' );
ok( !pseek( $f, 0, SEEK_END ), 'unopened 3' );

# Check file mode
ok( $fh = popen( $f, O_CREAT | O_RDWR ), 'file mode 1' );
@tmp = stat $f;
ok( $tmp[2] & 07777 == 0666 ^ umask, 'file mode 2' );
ok( pclose($f),                      'file mode 3' );
unlink $f;

ok( $fh = popen( $f, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR ), 'file mode 4' );
@tmp = stat $f;
ok( ( $tmp[2] & 07777 ) == ( S_IRUSR | S_IWUSR ), 'file mode 5' );

# Check cached file handle
ok( $fh == popen($f), 'popen cache 1' );

# Read empty file
my $bread;
$rv = pread( $f, $bread, 100 );
ok( ( defined $rv and !$rv ), 'read empty 1' );

# Write tests
$text = '';
for ( 0 .. 99 ) { $text .= sprintf( "%04d\n", $_ ) }

# Normal write
$rv = pwrite( $f, $text );
ok( ( $rv and length $text == $rv ), 'pwrite 1' );
pclose($f) and unlink $f;

# Write w/length
$rv = pwrite( $f, $text, 10 );
ok( $rv == 10, 'pwrite 2' );

# Write w/length & offset
$rv = pwrite( $f, $text, 10, -10 );
ok( $rv == 10, 'pwrite 3' );

# Write w/undef
$text = undef;
$rv = pwrite( $f, $text, 10, -10 );
ok( !defined $rv, 'pwrite 4' );

# Read a file that was opened O_WRONLY
$rv = pread( $f, $bread, 100 );
ok( !defined $rv, 'pread write-only 1' );

# Write to a file that opened O_RDONLY
pclose($f);
ok( $fh = popen( $f, O_RDONLY ), 'pwrite read-only 1' );
$rv = pwrite( $f, $bread );
ok( !defined $rv, 'pwrite read-only 2' );

# Test explicit r/w open
pclose($f) and unlink $f;
$text = '';
for ( 0 .. 99 ) { $text .= sprintf( "%04d\n", $_ ) }
ok( $fh = popen( $f, O_CREAT | O_TRUNC | O_RDWR ), 'read/write 1' );
$rv = pwrite( $f, $text );
ok( ( $rv and length $text == $rv ), 'read/write 2' );
$rv = ptell($f);
ok( $rv == length $text, 'read/write 3' );
$rv = pread( $f, $bread, $rlen );
ok( ( defined $rv and $rv == 0 ), 'read/write 4' );
ok( pseek( $f, 0, SEEK_SET ), 'read/write 5' );
$rv = pread( $f, $bread, $rlen );
ok( ( defined $rv and $rv == $rlen ), 'read/write 6' );
ok( $bread eq "0000\n", 'read/write 7' );
$rv = pwrite( $f, "AAAA\n" );
ok( ( $rv and $rlen == $rv ), 'read/write 8' );
ok( pseek( $f, 0, SEEK_SET ), 'read/write 9' );
$rv = pread( $f, $bread, $rlen * 2 );
ok( ( defined $rv and $rv == $rlen * 2 ), 'read/write 10' );
ok( $bread eq "0000\nAAAA\n", 'read/write 11' );

# Test fork w/O_TRUNC
my $cpid = fork;
if ($cpid) {
    wait;
    ok( pseek( $f, 0, SEEK_CUR ), 'fork 1' );
    $rv = pread( $f, $bread, $rlen * 2 );
    ok( ( defined $rv and $rv == $rlen * 2 ), 'fork 2' );
    ok( $bread eq "BBBB\n0003\n", 'fork 3' );
} else {
    pwrite( $f, "BBBB\n" );
    exit 0;
}

# Test pappend w/o O_APPEND
$rv    = ptell($f);
$bread = "ZZZZ\n";
ok( pappend( $f, $bread ), 'pappend 1' );
ok( $rv == ptell($f), 'pappend 2' );
ok( pseek( $f, $rlen * -1, SEEK_END ), 'pappend 3' );
ok( pread( $f, $bread, $rlen ), 'pappend 4' );
ok( $bread eq "ZZZZ\n", 'pappend 5' );

# Test pappend w/O_APPEND
pclose($f);
$rv = ptell($f);
ok( pappend( $f, $bread ), 'pappend 6' );
ok( $rv == ptell($f), 'pappend 7' );

# Test everything w/file handles
$fh = popen($f);
ok( pclose($fh), 'file handle 1' );
$fh = popen($f);
ok( pflock( $f, LOCK_EX ), 'file handle 2' );
ok( pseek( $fh, 0, SEEK_END ), 'file handle 3' );
$rv = ptell($fh);
ok( $rv == $rlen * 102, 'file handle 4' );
ok( pseek( $fh, 0, SEEK_SET ), 'file handle 5' );
$bread = "0000\n";
$rv = pwrite( $fh, $bread );
ok( $rv == $rlen, 'file handle 6' );
ok( pseek( $fh, 0, SEEK_SET ), 'file handle 7' );
$rv = pnlread( $fh, $bread, $rlen );
ok( $rv == $rlen, 'file handle 8' );
ok( pflock( $f, LOCK_UN ), 'file handle 9' );

# Test ptruncate
ok( pseek( $fh, 0, SEEK_SET ), 'ptruncate 1' );
ok( ptruncate($fh), 'ptruncate 2' );
ok( pseek( $fh, 0, SEEK_CUR ), 'ptruncate 3' );
ok( pseek( $fh, 0, SEEK_END ), 'ptruncate 4' );
ok( ptell($fh) == 0, 'ptruncate 5' );

pclose($fh);

unlink $f;
