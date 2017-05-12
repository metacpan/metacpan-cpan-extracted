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

use Shell::Tools;

my @warn;
{
	local $SIG{__WARN__} = sub { push @warn, shift };
	carp "hello!world";
}
is @warn, 1, 'carp 1';
like $warn[0], qr/\bhello\!world\b/, 'carp 2';
ok !defined(eval { croak "ack"; 1 }), 'croak 1';  ## no critic (RequireCheckingReturnValueOfEval, ProhibitUnreachableCode)
like $@, qr/\back\b/, 'croak 2';
ok !defined(eval { confess "blub"; 1 }), 'confess 1';  ## no critic (RequireCheckingReturnValueOfEval, ProhibitUnreachableCode)
like $@, qr/\bblub\b/, 'confess 2';

my $tmpdir = tempdir(CLEANUP=>1);
ok -d $tmpdir, "tempdir $tmpdir created";

my ($tfh,$tfn) = tempfile(DIR=>$tmpdir);
print {$tfh} "foo\nbar\n";
close $tfh or fail "close failed: $!";
ok -f $tfn, "tempfile $tfn created";
ok file_name_is_absolute($tfn), 'tempfile is absolute filename';

make_path( catdir($tmpdir,"foo","bar"), catdir($tmpdir,"quz","baz") );
ok -d catdir($tmpdir,"foo"), "make_path 1";
ok -d catdir($tmpdir,"foo","bar"), "make_path 2";
ok -d catdir($tmpdir,"quz"), "make_path 3";
ok -d catdir($tmpdir,"quz","baz"), "make_path 4";

remove_tree( catdir($tmpdir,"quz") );
ok ! -e catdir($tmpdir,"quz"), "remove_tree";

my $abc_txt = catfile($tmpdir,"foo","abc.txt");
move($tfn, $abc_txt) or fail "Move failed: $!";
ok -f $abc_txt, "move 1";
ok ! -f $tfn, "move 2";

my $xyz_txt = catfile($tmpdir,"foo","bar","xyz.txt");
copy($abc_txt, $xyz_txt) or fail "Copy failed: $!";
ok -f $xyz_txt, "copy 1";
ok -f $abc_txt, "copy 2";

open my $ofh, ">>", $xyz_txt or fail "open failed: $!";
# ->binmode doesn't work on v5.10 and older; haven't found the reason yet
#$ofh->binmode(":raw");
$ofh->autoflush(1);  # IO::File / IO::Handle
$ofh->print("quz") or fail "print failed";
close $ofh;

my @found;
find({ no_chdir=>1, wanted=>sub {
	my $rel = abs2rel($_,$tmpdir);
	# Possible To-Do for Later: Why does abs2rel sometimes return the empty string in v5.6.2,
	# at least in my testing environment? This is a workaround:
	# (Update: now requiring at least Perl v5.8; this workaround can probably be removed)
	$rel = curdir if $rel eq '' && $_ eq $tmpdir;
	push @found, $rel;
} }, $tmpdir);
@found = sort @found;
is_deeply \@found, [curdir, 'foo', catfile('foo','abc.txt'),
	catdir('foo','bar'), catfile('foo','bar','xyz.txt') ], "find"
	or diag explain \@found;

is canonpath(dirname($abc_txt)), catdir($tmpdir,"foo"), 'canonpath of dirname';
is basename($abc_txt), 'abc.txt', "basename";

is rel2abs(curdir), canonpath(getcwd), 'getcwd, curdir, rel2abs';
is canonpath(cwd), canonpath(getcwd), 'cwd';
is abs_path(catdir($tmpdir,"foo",updir)), abs_path($tmpdir), "abs_path";

my @files = do { opendir my $dh, catdir($tmpdir,"foo") or fail $!;
	no_upwards readdir $dh };
@files = sort @files;
is_deeply \@files, ['abc.txt','bar'], "opendir, no_upwards";

my ($fp_fn, $fp_dirs, $fp_suff) = fileparse(catfile("foo","bar","YAK.INI"), qr/\.(txt|ini)$/i);
is $fp_fn, 'YAK', 'fileparse 1';
is $fp_suff, '.INI', 'fileparse 2';
is canonpath($fp_dirs), catdir("foo","bar"), 'fileparse 3';
is_deeply [splitdir canonpath $fp_dirs], ['foo','bar'], 'splitdir';

ok -d rootdir, 'rootdir';

sub slurp { open my $fh, '<', shift or croak $!; return <$fh> }  ## no critic (RequireBriefOpen)

is_deeply [slurp $abc_txt], ["foo\n","bar\n"], 'slurp abc.txt';
is_deeply [slurp $xyz_txt], ["foo\n","bar\n","quz"], 'slurp xyz.txt';

is LOCK_SH, 1, 'LOCK_SH';
is LOCK_EX, 2, 'LOCK_EX';
is LOCK_UN, 8, 'LOCK_UN';
is LOCK_NB, 4, 'LOCK_NB';
is SEEK_SET, 0, 'SEEK_SET';
is SEEK_CUR, 1, 'SEEK_CUR';
is SEEK_END, 2, 'SEEK_END';

{
	local $Data::Dumper::Purity = 1;
	local $Data::Dumper::Useqq  = 1;
	local $Data::Dumper::Terse  = 1;
	local $Data::Dumper::Indent = 0;
	is Dumper("hello\nworld"), '"hello\\nworld"', 'Dumper 1';
	is Dumper({foo=>['bar','quz']}), '{"foo" => ["bar","quz"]}', 'Dumper 2';
}

ok looks_like_number('123.45'), 'looks_like_number 1';
ok looks_like_number('  -635.2342e-34'), 'looks_like_number 2';
ok !looks_like_number('123x'), 'looks_like_number 3';

is +( first {/3/} 10..20 ), 13, 'first';
# get rid of "used only once" warning
our ($a, $b);  ## no critic (ProhibitPackageVars)
is +( reduce { $a + $b } 1..10 ), 55, 'reduce/sum';

done_testing;

