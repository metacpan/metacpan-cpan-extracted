#!/usr/bin/perl -w
use strict;
use SVK::Util qw( is_executable );
use SVK::Test;
plan tests => 1;
our $output;

# Basically, trying to merge a revision containing a copy, where the cop source file is removed at the
# previous  revision, but also a copy with modification on the revision in question
#< clkao> branch from r1, r2 - remove file B, r3 - cp B@1 to C with modification, cp A@2 to B
#< clkao> so try to merge changes between r1 and r3
my ($xd, $svk) = build_test();
$svk->mkdir ('-pm', 'init', '//V/A');
my $tree = create_basic_tree ($xd, '//V/A');
my ($copath, $corpath) = get_copath ('checksum');
$svk->cp(-m => 'V to X', '//V', '//X');

# r2 - remove file B

#$svk->rm(-m => 'r5 - remove file A/me', "//V/A/me");

$svk->checkout('//V',$copath);
# r3 - cp B@1 to C with modification,
$svk->cp('//V/A/me' => "$copath/Cme", -r => 4 );

append_file("$copath/Cme", "mmmmmmxx\n");
$svk->ci(-m => 'r8 - modify Cme', $copath);
# cp A@2 to B, if we comment these two out, 
#$svk->cp('//V/A/D/de' => "$copath/A/me", -r => 5);
append_file("$copath/A/me", "mmmmmm\n");
$svk->ci(-m => 'some copy with mods', $copath);

is_output($svk, 'smerge', [-m => 'go', '//V', '//X'],
	  ['Auto-merging (3, 6) /V to /X (base /V:3).',
	   'U   A/me',
	   'A + Cme',
	   qr'New merge ticket: .*:/V:6',
	   'Committed revision 7.']);

1;
