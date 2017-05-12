#!/usr/bin/perl -w
use Test::More tests => 1;
use strict;
use File::Path;
use Cwd;
use SVK::Test;

my ($xd, $svk) = build_test();
our $output;
my ($copath, $corpath) = get_copath();
$svk->mkdir ('-m', 'trunk', '//trunk');
my $tree = create_basic_tree ($xd, '//trunk');
$svk->cp ('-m', 'branch', '//trunk', '//local');

$svk->mkdir(-m => 'somedir', '//local/somedir');
$svk->mv(-m => 'rename local to local-foo', '//local', '//local-foo');

is_output($svk, 'push', ['//local-foo'],
	  ['Auto-merging (0, 6) /local-foo to /trunk (base /trunk:3).',
	   '===> Auto-merging (0, 6) /local-foo to /trunk (base /trunk:3).',
	   'A   somedir',
	   qr'New merge ticket: .*:/local:5',
	   qr'New merge ticket: .*:/local-foo:6',
	   'Committed revision 7.']);
