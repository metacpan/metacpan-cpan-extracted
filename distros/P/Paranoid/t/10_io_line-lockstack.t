#!/usr/bin/perl -T

use Test::More tests => 47;
use Paranoid;
use Paranoid::IO qw(:all);
use Paranoid::IO::Line qw(:all);
use Paranoid::Debug;
use Fcntl qw(:DEFAULT :mode :seek :flock);

use strict;
use warnings;

psecureEnv();

my ( $val, $fh, $f, $l, @lines, $rv, @all );

# Create another test file for sip
PIOMAXFSIZE  = 4096;
PIOBLKSIZE   = 512;
PIOLOCKSTACK = 1;
$l   = "1" x 78 . "\15\12";
$val = int( ( 6 * 1024 ) / length $l );
$f   = "./t/test24KB";
open $fh, '>', $f or die "failed to open file: $!\n";
for ( 1 .. $val ) { print $fh $l }
for ( 1 .. $val ) { print $fh '0' x 80 }
for ( 1 .. $val ) { print $fh $l }
for ( 1 .. $val ) { print $fh '0' x 80 }
close $fh;

# Sip block 1
is( sip( $f, @lines ), 51, 'sip block 1 - 1' );
is( $lines[0], $l, 'sip block 1 - 2' );
push @all, @lines;

# Sip block 2
is( sip( $f, @lines ), undef, 'sip block 2 - 1' );
push @all, @lines;
is( scalar @lines, 25, 'sip block 2 - 2' );

# Sip block 3
is( sip( $f, @lines ), '0 but true', 'sip block 3 - 1' );
push @all, @lines;
is( scalar @lines, 0, 'sip block 3 - 2' );

# Sip block 4
is( sip( $f, @lines ), 51, 'sip block 4 - 1' );
push @all, @lines;

# Sip block 5
is( sip( $f, @lines ), undef, 'sip block 5 - 1' );
push @all, @lines;
is( scalar @lines, 24, 'sip block 5 - 2' );

# Sip block 6
is( sip( $f, @lines ), undef, 'sip block 6 - 1' );
push @all, @lines;
is( scalar @lines, 0, 'sip block 6 - 2' );

# Sip block 7
is( sip( $f, @lines ), '0 but true', 'sip block 7 - 1' );
push @all, @lines;
is( scalar @lines, 0, 'sip block 7 - 2' );

# Add some content, try sipping some more content
open $fh, '>>', $f or die "failed to open file: $!\n";
for ( 1 .. $val ) { print $fh "2" x 78 . "\12" }
close $fh;

# Sip block 8 (with autochomp)
is( sip( $f, @lines, 1 ), 50, 'sip block 8 - 1' );
push @all, @lines;

# Test no chomp/chomp
is( length $all[0],  80,       'sip no pchomp 1' );
is( length $all[-1], 78,       'sip pchomp 1' );
is( $all[-1],        '2' x 78, 'sip pchomp 2' );

# Sip block 9 & 10
is( sip( $f, @lines, 1 ), 25,           'sip block 9 - 1' );
is( sip( $f, @lines, 1 ), '0 but true', 'sip block 10 - 1' );

# Tailf and piolClose
ok( piolClose($f), 'piolClose 1' );
is( tailf( $f, @lines, 0 ), 10, 'tailf 1' );
ok( piolClose($f), 'piolClose 2' );
is( tailf( $f, @lines, 0, -75 ), 75, 'tailf 2' );
ok( piolClose($f), 'piolClose 3' );

# Multiplea tail test
ok( popen( $f, O_RDWR ), 'multiple tailf 1' );
is( tailf( $f, @lines, 0, -1 ), 1,            'multiple tailf 2' );
is( tailf( $f, @lines, 0, -1 ), '0 but true', 'multiple tailf 3' );
ok( pappend( $f, "line 1\n,line 2\nline 3" ), 'multiple tailf 4' );
is( tailf( $f, @lines, 0, -1 ), 2, 'multiple tailf 5' );
ok( pappend( $f, "\n" ), 'multiple tailf 6' );
is( tailf( $f, @lines, 0, -1 ), 1, 'multiple tailf 7' );
is( $lines[0], "line 3\n", 'multiple tailf 8' );

# Test truncate
open $fh, '>', $f or die "failed to open file: $!\n";
print $fh "line a\nline b\nline c\n";
close $fh;
is( tailf( $f, @lines, 0, -4 ), 3, 'multiple tailf 11' );
is( $lines[0], "line a\n", 'multiple tailf 12' );

# Test overwrite
unlink $f;
open $fh, '>', $f or die "failed to open file: $!\n";
print $fh "testing\ntesting\n";
close $fh;
is( tailf( $f, @lines, 0, -4 ), 2, 'multiple tailf 13' );
is( $lines[0], "testing\n", 'multiple tailf 14' );
is( $lines[1], "testing\n", 'multiple tailf 15' );

# Test delete
unlink $f;
is( tailf( $f, @lines, 0, -4 ), undef, 'multiple tailf 16' );

# Test slurp
#
# Create a test file
PIOMAXFSIZE = 16 * 1024;
$val = int( ( 4 * 1024 ) / length $l );
$f = "./t/test4KB";
open $fh, '>', $f or die "failed to open file: $!\n";
for ( 1 .. $val ) { print $fh $l }
close $fh;

# Test small file
ok( slurp( $f, @lines ), 'slurp w/4KB file 1' );
ok( @lines == $val, 'slurp w/4KB file 2' );

# Test filehandle slurp
open $fh, '<', $f or die "failed to open file: $!\n";
ok( slurp( $fh, @lines ), 'slurp w/filehandle 1' );
ok( @lines == $val, 'slurp w/filehandle 2' );
ok( !slurp( $fh, @lines ), 'slurp w/filehandle 3' );
ok( @lines == 0, 'slurp w/filehandle 4' );
close $fh;

# Create a larger test file
$val = int( ( 24 * 1024 ) / length $l );
$f = "./t/test24KB";
open $fh, '>', $f or die "failed to open file: $!\n";
for ( 1 .. $val ) { print $fh $l }
close $fh;

# Test a larger file
ok( !slurp( $f, @lines ), 'slurp w/24KB file 1' );
ok( scalar @lines, 'slurp w/24KB file 2' );

# Test reading non-existant file
$f = "./t/foo-test";

ok( !slurp( $f, @lines ), 'slurp\'ing non-existent file' );

unlink qw(./t/test4KB ./t/test24KB);
