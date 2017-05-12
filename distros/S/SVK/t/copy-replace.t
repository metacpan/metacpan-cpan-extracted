#!/usr/bin/perl -w
use Test::More tests => 5;
use strict;
our $output;
use SVK::Test;
my ($xd, $svk) = build_test();
$svk->mkdir ('-pm', 'init', '//V/Y');
my $tree = create_basic_tree ($xd, '//V/Y');
my ($copath, $corpath) = get_copath();

$svk->cp('//V/Y' => '//V/X', -m => 'Y => X');

$svk->checkout('//V', $copath);

$svk->rm("$copath/Y");
$svk->cp('//V/X' => "$copath/Y");

is_output($svk, 'st', [$copath],
	  [__("R + $copath/Y")]);

$svk->ci(-m => 'go', $copath);

$svk->rm("$copath/Y");
$svk->cp('//V/X' => "$copath/Y");
$svk->rm("$copath/Y/D");
is_output($svk, 'st', [$copath],
	  [__("R + $copath/Y"),
	   __("D + $copath/Y/D"),
	   __("D + $copath/Y/D/de")]);

append_file("$copath/Y/A/be", "bwahaha\n");

is_output($svk, 'st', [$copath],
	  [__("R + $copath/Y"),
	   __("M + $copath/Y/A/be"),
	   __("D + $copath/Y/D"),
	   __("D + $copath/Y/D/de")]);
$svk->ci(-m => 'go', $copath);
$svk->admin ('rmcache');
is_output($svk, 'st', [$copath], []);

$svk->rm("$copath/Y");
$svk->cp('//V/Y@5' => "$copath/Y");
append_file("$copath/Y/A/be", "mmmmmm\n");

is_output($svk, 'st', [$copath],
	  [__("R + $copath/Y"),
	   __("M + $copath/Y/A/be")]);
