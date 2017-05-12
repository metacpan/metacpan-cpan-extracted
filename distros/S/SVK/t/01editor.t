#!/usr/bin/perl -w
use Test::More tests => 1;
use strict;
use SVK::Test;
our $output;
my ($xd, $svk) = build_test();
my ($copath, $corpath) = get_copath();
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);

$svk->checkout ('//', $copath);
mkdir ("$copath/A");
mkdir ("$copath/B");
overwrite_file ("$copath/A/foo", "foobar\nfnord\n");
overwrite_file ("$copath/A/bar", "foobar\n");
overwrite_file ("$copath/B/nor", "foobar\n");
$svk->add ("$copath/A", "$copath/B");
$svk->commit ('-m', 'init', $copath);

set_editor(<< 'TMP');
$_ = shift;
print "# props $_\n";
open _ or die $!;
@_ = ("props\n", <_>);
close _;
unlink $_;
open _, '>', $_ or die $!;
print _ @_;
close _;
TMP

$svk->ps ('someprop', 'somevalue', "$copath/B/nor");
$svk->commit ( $copath);
is_output ($svk, 'status', [$copath], [], 'committed correctly with editor');
