#!/usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;
eval { require SVN::Mirror; 1 } or plan skip_all => 'require SVN::Mirror';
plan tests => 21;

my ($xd, $svk) = build_test('test');

our $output;

my $tree = create_basic_tree ($xd, '/test/');

my ($copath, $corpath) = get_copath ('sync-crazy-replace');

$svk->checkout ('/test/', $copath);

is_output($svk, cp => ["$copath/A", "$copath/A-copy"],
          [
           __("A   $copath/A-copy"),
           __("A   $copath/A-copy/Q"),
           __("A   $copath/A-copy/Q/qu"),
           __("A   $copath/A-copy/Q/qz"),
           __("A   $copath/A-copy/be"),
          ]);

is_sorted_output($svk, rm => ["$copath/A-copy/Q"],
          [
           __("D   $copath/A-copy/Q"),
           __("D   $copath/A-copy/Q/qu"),
           __("D   $copath/A-copy/Q/qz"),
          ]);

is_output($svk, cp => ["$copath/A/Q", "$copath/A-copy/Q"],
          [
           __("A   $copath/A-copy/Q"),
           __("A   $copath/A-copy/Q/qu"),
           __("A   $copath/A-copy/Q/qz"),
          ]);

is_output($svk, st => [$copath],
          [
           __("A + $copath/A-copy"),
           __("R + $copath/A-copy/Q"),
          ]);

is_output($svk, ci => [-m => "make branch", $copath], ["Committed revision 3."]);

my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/', 1);
my $uri = uri($srepospath.($spath eq '/' ? '' : $spath));

is_output($svk, mirror => ['//m', $uri],
          ["Mirror initialized.  Run svk sync //m to start mirroring."]);

is_output($svk, 'sync', ['//m'],
	  ["Syncing $uri",
	   'Retrieving log information from 1 to 3',
	   'Committed revision 2 from revision 1.',
	   'Committed revision 3 from revision 2.',
           'Committed revision 4 from revision 3.']);

is_sorted_output($svk, rm => ["$copath/A-copy"],
          [
           __("D   $copath/A-copy"),
	   __("D   $copath/A-copy/be"),
           __("D   $copath/A-copy/Q"),
           __("D   $copath/A-copy/Q/qu"),
           __("D   $copath/A-copy/Q/qz"),
          ]);

is_output($svk, cp => ["$copath/A", "$copath/A-copy"],
          [
           __("A   $copath/A-copy"),
           __("A   $copath/A-copy/Q"),
           __("A   $copath/A-copy/Q/qu"),
           __("A   $copath/A-copy/Q/qz"),
	   __("A   $copath/A-copy/be"),
          ]);

is_output($svk, cp => ["$copath/A/Q", "$copath/A-copy/Q-copy"],
          [
           __("A   $copath/A-copy/Q-copy"),
           __("A   $copath/A-copy/Q-copy/qu"),
           __("A   $copath/A-copy/Q-copy/qz"),
          ]);

is_output($svk, cp => ["$copath/A/Q/qu", "$copath/A-copy/qu-copy"],
          [
           __("A   $copath/A-copy/qu-copy"),
          ]);


is_output($svk, rm => ["$copath/A-copy/be"],
          [
           __("D   $copath/A-copy/be"),
          ]);

is_output($svk, cp => ["$copath/A/Q/qu", "$copath/A-copy/be"],
          [
           __("A   $copath/A-copy/be"),
          ]);

is_output($svk, rm => ["$copath/A-copy/Q/qu"],
          [
           __("D   $copath/A-copy/Q/qu"),
          ]);

is_output($svk, cp => ["$copath/A/Q/qu", "$copath/A-copy/Q/qu"],
          [
           __("A   $copath/A-copy/Q/qu"),
          ]);
append_file("$copath/A-copy/Q/qu", "R + M changed\n");

is_output($svk, st => [$copath],
          [
           __("R + $copath/A-copy"),
           __("R + $copath/A-copy/Q/qu"),
           __("A + $copath/A-copy/Q-copy"),
           __("R + $copath/A-copy/be"),
           __("A + $copath/A-copy/qu-copy"),
          ]);

is_output($svk, ci => [-m => 'copy inside replace', $copath],
	  ['Committed revision 4.']);

is_output($svk, 'sync', ['//m'],
	  ["Syncing $uri",
	   'Retrieving log information from 4 to 4',
	   'Committed revision 5 from revision 4.']);
is_ancestor($svk, '//m/A-copy', '/m/A', 3);
is_ancestor($svk, '//m/A-copy/be', '/m/A/Q/qu', 2);

is_output($svk, 'cat', ['//m/A-copy/Q/qu'],
	  ['first line in qu',
	   '2nd line in qu',
	   'R + M changed']);
