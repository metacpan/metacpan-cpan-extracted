#!/usr/bin/perl -w

use strict;

use Test::More tests => 2;
use File::Path;
use Cwd;
use SVK::Test;

my ($xd, $svk) = build_test();
our $output;
my ($copath, $corpath) = get_copath();
$svk->mkdir ('-m', 'trunk', '//trunk');
my $tree = create_basic_tree ($xd, '//trunk');
$svk->cp ('-m', 'branch', '//trunk', '//local');
$svk->rm ('-m', 'remove branch', '//local');
$svk->co ('//trunk', $copath);
append_file("$copath/me", "a change\n");
$svk->ci ('-m', 'change file', $copath );
$svk->switch ('//local@4', $copath);

is_output($svk, 'sm', ['-C', '//trunk', $copath],
    ['Auto-merging (3, 6) /trunk to /local (base /trunk:3).',
     __("U   $copath/me"),
     qr'New merge ticket: .*:/trunk:6']
);
is_output($svk, 'sm', ['//trunk', $copath],
    ['Auto-merging (3, 6) /trunk to /local (base /trunk:3).',
     __("U   $copath/me"),
     qr'New merge ticket: .*:/trunk:6']
);

#diag $output;
