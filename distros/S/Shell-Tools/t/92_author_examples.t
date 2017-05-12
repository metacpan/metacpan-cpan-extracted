#!/usr/bin/env perl
use warnings FATAL=>'all';
use strict;

# Tests for the Perl module Shell::Tools
# 
# Copyright (c) 2014 Hauke Daempfling (haukex@zero-g.net).
# 
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl 5 itself.
# 
# For more information see the "Perl Artistic License",
# which should have been distributed with your copy of Perl.
# Try the command "perldoc perlartistic" or see
# http://perldoc.perl.org/perlartistic.html .

use FindBin ();
use lib $FindBin::Bin;
use Shell_Tools_Testlib;

use Test::More $AUTHOR_TESTS ? (tests=>4)
	: (skip_all=>'author tests of example scripts');

use File::Temp 'tempdir';
use File::Spec::Functions qw/catdir catfile updir/;
use File::Path 'make_path';
use Capture::Tiny 'capture';
use Config;

# ### Test the "follow" script ###

my $FOLLOW = catfile($FindBin::Bin, updir, 'examples', 'follow');
ok -f $FOLLOW, 'the "follow" script exists';

my $tmpdir = tempdir(CLEANUP=>1);
my $dir_foo = catdir($tmpdir,'foo');
my $dir_bar = catdir($tmpdir,'bar');
my $file_a = catfile($dir_foo,'aaaaa');
my $file_b = catfile($dir_bar,'bbbbb');
my $file_c = catfile($tmpdir,'ccccc');
my $file_c_rel = catfile(updir,'ccccc');

make_path($dir_foo, $dir_bar);
open my $cfh, '>', $file_c or croak $!;
print $cfh qq{#!/bin/sh\n\necho "Hello"\n};
close $cfh;
chmod(oct('755'), $file_c)==1 or croak $!;
symlink($file_c_rel, $file_b) or croak $!;  # relative symlink
symlink($file_b, $file_a) or croak $!;  # abs symlink

my ($out,$err,$code) = capture {
		local $ENV{PATH} = "$dir_foo:$ENV{PATH}";  # so "which" can find it
		system $Config{perlpath}, $FOLLOW, '--', 'aaaaa';
	};
is $code, 0, 'follow $?';
is $err, '', 'follow stderr';
## no critic (ProhibitComplexRegexes)
like $out, qr{
^ \Q$file_a: symbolic link to `$file_b'
$file_b: symbolic link to `$file_c_rel'
$file_c: \E[^\n]*shell\ script[^\n]*\n
$ }x, 'follow stdout';

