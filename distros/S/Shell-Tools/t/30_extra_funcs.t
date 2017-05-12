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

use Test::More $HAVE_REQUIRED_EXTRAS ? ()
	: (skip_all=>'not all extra modules are installed');

use Shell::Tools::Extra;

try { croak "ack" }
catch { ok /\back\b/, 'catch' }
finally { ok 1, 'finally 1' };

try { ok 1, 'try' }
catch { fail 'bad catch' }
finally { ok 1, 'finally 2' };

try { croak "bleh" }
finally { ok 1, 'finally 3' };

my $tmpdir = dir(tempdir(CLEANUP=>1));
isa_ok $tmpdir, 'Path::Class::Dir', 'dir';
ok -d $tmpdir, "tempdir $tmpdir created";

my $abc_txt = $tmpdir->file('abc.txt');
isa_ok $abc_txt, 'Path::Class::File', 'file 1';
ok ! -f $abc_txt, "$abc_txt not a file yet";

my $xyz_txt = file("$tmpdir", 'xyz.txt');
isa_ok $xyz_txt, 'Path::Class::File', 'file 2';
ok ! -f $xyz_txt, "$xyz_txt not a file yet";

$abc_txt->touch;
ok -f $abc_txt, "$abc_txt now exists";

$xyz_txt->spew("foo\nbar\nquz");
ok -f $xyz_txt, "$abc_txt now exists";

$tmpdir->file('blah.ini')->touch;

my $prevwd = cwd;
{
	my $pushd = pushd($tmpdir);
	is abs_path(cwd), abs_path($tmpdir), 'work dir changed';
	
	my @files = rule->file->name('*.txt')->in(curdir);
	@files = sort @files;
	is_deeply \@files, ['abc.txt','xyz.txt'], 'File::Find::Rule';
}
is canonpath(cwd), canonpath($prevwd), 'work dir restored';

done_testing;

