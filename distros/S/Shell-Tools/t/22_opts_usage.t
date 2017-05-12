#!/usr/bin/env perl
use warnings;
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

use Test::More;

use Capture::Tiny 'capture';
use Config;

use Shell::Tools;

my $script = catfile($FindBin::Bin, 'test_opts_usage.pl');

my $USAGE_RE = qr/\bUsage:\s*test_opts_usage\.pl \[OPTIONS\] FILENAME.*?-b BAR\s+- bar\b/si;  ## no critic (ProhibitComplexRegexes)

# Possible To-Do for Later: Also test $VERSION_STRING and !$VERSION
# variants of VERSION_MESSAGE (using %ENV to control test script?)

subtest 'no filename' => sub {
	my ($out,$err) = capture { system $Config{perlpath}, $script };
	ok $? != 0, 'perl failed';
	is $out, '', 'no stdout';
	like $err, qr/\bmust specify a filename\b.+?$USAGE_RE/si, 'stderr message correct';
};

subtest 'bad option' => sub {
	my ($out,$err) = capture { system $Config{perlpath}, $script, '-x' };
	ok $? != 0, 'perl failed';
	is $out, '', 'no stdout';
	like $err, qr/\bunknown option\b.+?$USAGE_RE/si, 'stderr message correct';
};

subtest '--version' => sub {
	my ($out,$err) = capture { system $Config{perlpath}, $script, '--version' };
	ok $? == 0, 'perl ok';
	is $out, "test_opts_usage.pl Version 0.123\n", 'stdout message correct';
	is $err, '', 'no stderr';
};

subtest '--help' => sub {
	my ($out,$err) = capture { system $Config{perlpath}, $script, '--help' };
	ok $? != 0, 'perl failed';
	like $out, qr/\btest_opts_usage.pl Version 0.123\b.+?$USAGE_RE/si, 'stdout message correct';
	is $err, '', 'no stderr';
};

subtest 'no options' => sub {
	my ($out,$err) = capture { system $Config{perlpath}, $script, "FileName" };
	ok $? == 0, 'perl ok';
	is $out, 'Foo=0, Bar=(0), FN=FileName', 'stdout correct';
	is $err, '', 'no stderr';
};

subtest 'bar bad option' => sub {
	my ($out,$err) = capture { system $Config{perlpath}, $script, '-b', 'xfailx', "FileName" };
	ok $? != 0, 'perl failed';
	is $out, '', 'no stdout';
	like $err, qr/\bbad bar option\b.+?$USAGE_RE/si, 'stderr message correct';
};

subtest 'full options' => sub {
	my ($out,$err) = capture { system $Config{perlpath}, $script, '-b', 'boop', '-f', "FileName" };
	ok $? == 0, 'perl ok';
	is $out, 'Foo=1, Bar=boop, FN=FileName', 'stdout correct';
	is $err, '', 'no stderr';
};

done_testing;

