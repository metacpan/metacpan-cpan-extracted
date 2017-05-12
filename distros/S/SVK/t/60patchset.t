#!/usr/bin/perl -w
use strict;
use SVK::Test;
SVN::Repos->can ('get_commit_editor2')
    or plan (skip_all => 'svn 1.2 required');
eval { require Text::Thread; 1 }
    or plan (skip_all => "Text::Thread required for testing patchset");

plan tests => 3;
our $output;

# build another tree to be mirrored ourself
my ($xd, $svk) = build_test();

my $tree = create_basic_tree ($xd, '//');

my ($copath, $corpath) = get_copath ('patchset');
$svk->checkout ('//', $copath);

my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);

append_file ("$copath/A/be", "modified on trunk\n");
$svk->commit ('-m', 'modify A/be', $copath);

append_file ("$copath/D/de", "modified on trunk\n");
$svk->commit ('-m', 'modify D/de', $copath);

append_file ("$copath/D/de", "modified both\n");
append_file ("$copath/A/be", "modified both\n");
$svk->commit ('-m', 'modify A/be and D/de', $copath);

append_file ("$copath/A/Q/qu", "modified qu\n");
$svk->commit ('-m', 'modify A/qu', $copath);

use SVK::Patchset;

my $fs = $repos->fs;
my $ps = bless { xd => $xd }, 'SVK::Patchset';

is_deeply ($ps->all_dependencies ($repos, 6), [1], 'r6 depends on r1');
is_deeply (deptree($fs->youngest_rev),
	   ['1: test init tree',
	    '`->6: modify A/qu',
	    '2: test init tree',
	    '3: modify A/be',
	    '4: modify D/de',
	    '5: modify A/be and D/de',
	   ], 'lazy computation');

$ps->recalculate ($repos);
is_deeply (deptree($fs->youngest_rev),
	   ['1: test init tree',
	    '|->2: test init tree',
	    '| `->4: modify D/de',
	    '|   `->5: modify A/be and D/de',
	    '|->3: modify A/be',
	    '| `->5: modify A/be and D/de',
	    '`->6: modify A/qu',
	   ], 'whole tree');
diag join("\n", @{deptree($fs->youngest_rev)},'');



sub node {
    my $rev = shift;
    my $log = $fs->revision_prop ($rev, 'svn:log');
    $log =~ s/\n.*$//s; # first line.
    return { title => "$rev: $log",
	     child => [map {node($_)} sort split /,/, ($fs->revision_prop ($rev, 'svk:children') || '')],
	   };
}

sub deptree {
    my $rev = shift;
    my @list = Text::Thread::formatthread
	('child', 'threadtitle', 'title',
	 # the tree
	 [map {$fs->revision_prop ($_, 'svk:parents') ? () : node($_)}
	  (1..$rev)]);

    for (1..$rev) {
	no warnings;
	print "$_ parents : ".$fs->revision_prop ($_, 'svk:parents')."\n";
	print "$_ children: ".$fs->revision_prop ($_, 'svk:children')."\n";
    }
    print "$_->{threadtitle}\n" foreach @list;
    return [map {$_->{threadtitle}} @list];
}
