#!/usr/bin/perl -w

use strict;
use SVK::Test;
plan tests => 12;

our ($output, $answer);
my ($xd, $svk) = build_test();

$svk->mkdir ('-m', 'init', '//foo');
my $tree = create_basic_tree ($xd, '//foo');

waste_rev ($svk, '//waste') for (1..100);

$svk->cp (-m => 'bar', '//foo' => '//bar');
$svk->cp (-m => 'baz', '//bar/B' => '//baz');

is_ancestor ($svk, '//bar',
	     '/foo', 3);
is_ancestor ($svk, '//bar/B/S/P',
	     '/foo/B/S/P', 3,
	     '/foo/A/P', 2);
is_ancestor ($svk, '//bar/B/S/P/pe',
	     '/foo/B/S/P/pe', 3,
	     '/foo/A/P/pe', 2);
is_ancestor ($svk, '//bar/A',
	     '/foo/A', 3);
is_ancestor ($svk, '//baz',
	     '/bar/B', 204,
	     '/foo/B', 3);
is_ancestor ($svk, '//baz/S',
	     '/bar/B/S', 204,
	     '/foo/B/S', 3,
	     '/foo/A', 2);
$svk->mkdir (-m => 'fnord', '//baz/fnord');
$svk->cp (-m => 'xyz', '//baz' => '//xyz');
is_ancestor ($svk, '//xyz/fnord',
	     '/baz/fnord', 206);
my $depot = $xd->find_depot('');
my $repos = $depot->repos;
my $fs = $repos->fs;

$svk->ps(-m=>'mod', 'foo', 'bar', '//baz/S');

is_copy ([SVK::Path->real_new
	  ({depot => $depot,
	    revision => 208, path => '/baz/S'})->nearest_copy],
	 [205, 204, '/bar/B/S']);
is_copy ([SVK::Path->real_new
	  ({depot => $depot,
	    revision => 208, path => '/baz'})->nearest_copy],
	 [205, 204, '/bar/B']);
is_copy ([SVK::Path->real_new
	  ({depot => $depot,
	    revision => 204, path => '/bar/B/S'})->nearest_copy],
	 [204, 3, '/foo/B/S']);
is_copy ([SVK::Path->real_new
	  ({depot => $depot,
	    revision => 3, path => '/foo/B/S'})->nearest_copy],
	 [3, 2, '/foo/A']);
is_copy ([SVK::Path->real_new
	  ({depot => $depot,
	    revision => 2, path => '/foo/A'})->nearest_copy],
	 []);

sub is_copy {
    if (exists $_[0][0]) {
	$_[0][0] = $_[0][0]->revision_root_revision;
	$_[0][1] = $_[0][1]->revision_root_revision;
    }
    goto \&is_deeply;
}

