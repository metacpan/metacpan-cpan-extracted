#!/usr/bin/perl

# Copyright 2005-2008, Sam Vilain.  All rights reserved.  This program
# is free software; you can use it and/or distribute it under the same
# terms as Perl itself; either the latest stable release of Perl when
# the module was written, or any subsequent stable release.

use warnings;
use strict;
use t::Util;

use Scriptalicious;

use Test::More tests => 17;

my ($rc, @out) = capture_err($^X, "-Mlib=lib", "t/fork.pl", "-v");

is($rc, 0, "Command completed successfully");

my $out = join "", @out;

like($out, qr/\(parent\)/, "Parent managed to use the timer");
like($out, qr/\(child\)/, "Child managed to use the timer");

# test that file descriptors can be fed in lots of different ways

slop $testfile, "Hello, world!";
my $output = capture( -in => $testfile,
		      $^X, "-Mlib=lib", "t/loopback.pl");
like($output, qr/:.*Hello, world!/, "run -in => 'FILENAME'");

$output = capture( -in => sub { print "Hi there\n" },
		   $^X, "-Mlib=lib", "t/loopback.pl");
like($output, qr/:.*Hi there/, "run -in => SUB");

open TEST, "<$testfile" or barf "damn! $!";
$output = capture( -in => \*TEST,
		   $^X, "-Mlib=lib", "t/loopback.pl");
like($output, qr/:.*Hello, world!/, "run -in => GLOB");
close TEST;

# output...
$output = capture( -out => $testfile,
		   -in  => sub { print "Loop this!\n" },
		   $^X, "-Mlib=lib", "t/loopback.pl");
is($output, "", "run out => 'FILENAME' (no output from capture)");
$output = slurp $testfile;
like($output, qr/:.*Loop this!/, "run -out => 'FILENAME'");

$output = capture( -out => sub { my $foo = <STDIN>;
				 slop $testfile, $foo;
			     },
		   -in  => sub { print "slopslopslop\n" },
		   $^X, "-Mlib=lib", "t/loopback.pl");
is($output, "", "run out => CODE (no output from capture)");
$output = slurp $testfile;
like($output, qr/:.*slopslopslop/, "run -out => CODE");

open TEST, ">$testfile" or barf $!;
$output = capture( -out => \*TEST,
		   -in  => sub { print "suckonthis!\n" },
		   $^X, "-Mlib=lib", "t/loopback.pl");
is($output, "", "run out => GLOB (no output from capture)");
close TEST;
$output = slurp $testfile;
like($output, qr/:.*suckonthis!/, "run -out => GLOB");

# explicit file descriptors...
slop $testfile, "Burp";
$output = capture( -in4  => $testfile,
		   $^X, "-Mlib=lib", "t/loopback.pl", qw(-i 4));
like($output, qr/Burp/, "-in4 => 'FILENAME'");

slop $testfile, "Burp";
$output = capture( -in => sub { print "It should be so easy!\n" },
		   -out4  => $testfile,
		   $^X, "-Mlib=lib", "t/loopback.pl", qw(-o 4));
is($output, "", "-out4 => 'FILENAME' (no output from capture)");
$output = slurp $testfile;
like($output, qr/:.*easy!/, "run -out4 => 'FILENAME'");

# last out!
$output = capture( -in5 => sub { print "slurpamunchalot\n" },
		   -out4  => sub { my $foo = <STDIN>;
				   slop $testfile, $foo },
		   $^X, "-Mlib=lib", "t/loopback.pl", qw(-o 4 -i 5));
is($output, "", "run -out4 => CODE, -in4 => CODE (no output from capture)");
$output = slurp $testfile;
like($output, qr/:.*slurpamunchalot/, "run -out4 => CODE, -in4 => CODE");
