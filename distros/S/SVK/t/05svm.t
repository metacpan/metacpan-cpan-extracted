#!/usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;
plan tests => 29;
our ($output, $answer);
# build another tree to be mirrored ourself
my ($xd, $svk) = build_test('test');

my $tree = create_basic_tree ($xd, '/test/');

my ($copath, $corpath) = get_copath ('svm');

my ($srepospath, $spath, $srepos) =$xd->find_repos ('/test/A', 1);
my $suuid = $srepos->fs->get_uuid;

$svk->copy ('-m', 'just make some more revisions', '/test/A', "/test/A-$_") for (1..20);

my $uri = uri($srepospath);
is_output ($svk, 'mirror', ['//m', $uri.($spath eq '/' ? '' : $spath)],
	   ['Mirror initialized.  Run svk sync //m to start mirroring.']);

is_output ($svk, 'mirror', [$uri.($spath eq '/' ? '' : $spath), '//m'],
	   ['/m already exists.']);

is_output_like ($svk, 'mirror', [], qr'SYNOPSIS', 'add - help');

is_output ($svk, 'mirror', ['--upgrade'],
	   ['nothing to upgrade']);
is_output ($svk, 'mirror', ['--upgrade', '//m'],
	   ['nothing to upgrade']);

is_output ($svk, 'sync', ['//'],
	   ['// is not a mirrored path.']);
is_output ($svk, 'sync', ['//what'],
	   ['//what is not a mirrored path.']);

is_output ($svk, 'sync', ['/what/'],
	   ["No such depot: what."]);
$svk->sync (-a => '/what/',
	    ["No such depot: what."]);

$svk->sync ('//m');
$svk->copy ('-m', 'branch', '//m', '//l');
$svk->checkout ('//l', $copath);
ok (-e "$corpath/be");
append_file ("$copath/be", "from local branch of svm'ed directory\n");
mkdir "$copath/T/";
append_file ("$copath/T/xd", "local new file\n");

$svk->add ("$copath/T");
$svk->delete ("$copath/Q/qu");

$svk->commit ('-m', 'local modification from branch', "$copath");
$svk->merge (qw/-C -r 4:5/, '-m', 'merge back to remote', '//l', '//m');
$svk->merge (qw/-r 4:5/, '-m', 'merge back to remote', '//l', '//m');
$svk->sync ('//m');

#$svk->merge (qw/-r 5:6/, '//m', $copath);
$svk->switch ('//m', $copath);
$svk->update ($copath);

append_file ("$copath/T/xd", "back to mirror directly\n");
overwrite_file ("$copath/T/foo", "back to mirror directly\n");
$svk->add ("$copath/T/foo");
$svk->status ($copath);

is_output ($svk, 'commit', ['-m', 'commit to mirrored path', $copath],
        ['Commit into mirrored path: merging back directly.',
        "Merging back to mirror source $uri/A.",
        'Merge back committed as revision 24.',
        "Syncing $uri/A",
        'Retrieving log information from 24 to 24',
        'Committed revision 7 from revision 24.']);
mkdir ("$copath/N");
$svk->add ("$copath/N");
is_output ($svk, 'commit', ['-m', 'commit to deep mirrored path', $copath],
        ['Commit into mirrored path: merging back directly.',
        "Merging back to mirror source $uri/A.",
        'Merge back committed as revision 25.',
        "Syncing $uri/A",
        'Retrieving log information from 25 to 25',
        'Committed revision 8 from revision 25.']);
append_file ("$copath/T/xd", "back to mirror directly again\n");
$svk->commit ('-m', 'commit to deep mirrored path', "$copath/T/xd");
ok(1);

$svk->copy ('-m', 'branch in source', '/test/A', '/test/A-98');
$svk->copy ('-m', 'branch in source', '/test/A-98', '/test/A-99');

$svk->mirror ('//m-99', "$uri/A-99");
$svk->copy ('-m', 'make a copy', '//m-99', '//m-99-intermediate');
$svk->move ('-m', 'move the copy', '//m-99-intermediate', '//m-99-copy');

my ($copath2, $corpath2) = get_copath ('svm2');
$svk->checkout ('//m-99-copy', $copath2);
is_output($svk, 'update', ['--sync', '--merge', $copath2], [
        "Syncing $uri/A-99",
        'Retrieving log information from 1 to 28',
        'Committed revision 13 from revision 28.',
        'Auto-merging (0, 13) /m-99 to /m-99-copy (base /:0).',
        'A   Q',
        'A   Q/qz',
        'A   T',
        'A   T/foo',
        'A   T/xd',
        'A   be',
        'A   N',
        "New merge ticket: $suuid:/A-99:28",
        'Committed revision 14.',
        "Syncing //m-99-copy(/m-99-copy) in $corpath2 to 14.",
        __('A   t/checkout/svm2/Q'),
        __('A   t/checkout/svm2/Q/qz'),
        __('A   t/checkout/svm2/T'),
        __('A   t/checkout/svm2/T/foo'),
        __('A   t/checkout/svm2/T/xd'),
        __('A   t/checkout/svm2/be'),
        __('A   t/checkout/svm2/N'), ]);

is_output($svk, 'smerge', ['-m', '', '--from', $copath2], [
        "Auto-merging (0, 14) /m-99-copy to /m-99 (base /m-99:13).",
        "Merging back to mirror source $uri/A-99.",
        "Empty merge.",
        ]);

my ($copath3, $corpath3) = get_copath ('svm3');
$svk->checkout ('//m-99', $copath3);
append_file ("$copath3/T/xd", "modify something\n");
$svk->commit ('-m', 'local modification from mirrored path', "$copath3");
append_file ("$copath3/T/xd", "modify something again\n");
$svk->commit ('-m', 'local modification from mirrored path', "$copath3");

is_output($svk, 'update', ['--sync', '--merge', '--incremental', "$copath2/T"], [
        "Syncing $uri/A-99",
        'Auto-merging (13, 16) /m-99 to /m-99-copy (base /m-99:13).',
        '===> Auto-merging (13, 15) /m-99 to /m-99-copy (base /m-99:13).',
        'U   T/xd',
        "New merge ticket: $suuid:/A-99:29",
        'Committed revision 17.',
        '===> Auto-merging (15, 16) /m-99 to /m-99-copy (base /m-99:15).',
        'U   T/xd',
        "New merge ticket: $suuid:/A-99:30",
        'Committed revision 18.',
        "Syncing //m-99-copy/T(/m-99-copy/T) in ".__("$corpath2/T to 18."),
        __("U   $copath2/T/xd"),
        ]);


is_output_like ($svk, 'mirror', ['--list'],
            qr"//m.*\Q$uri\E/A\n//m-99.*\Q$uri\E/A-99");

is_output_like ($svk, 'mirror', ['//m-99', "$uri/A-99"],
            qr"already", 'repeated mirror failed');

is_output_like ($svk, 'mirror', ['--detach', '//l'],
            qr"not a mirrored", '--detach on non-mirrored path');

is_output_like ($svk, 'mirror', ['--detach', '//m/T'],
            qr"inside", '--detach inside a mirrored path');

is_output ($svk, 'mirror', ['--detach', '//m'], [
            "Mirror path '//m' detached.",
            ], '--detach on mirrored path');

is_output_like ($svk, 'mirror', ['--detach', '//m'],
            qr"not a mirrored", '--detach on non-mirrored path');

is_output ($svk, 'mirror', ['//m', $uri.($spath eq '/' ? '' : $spath)],
	   ['/m already exists.']);

$svk->copy ('-m', 'make a copy', '//m-99-copy', '//m-99-copy-twice');

my ($copath4, $corpath4) = get_copath ('svm4');
$svk->checkout ('//m-99-copy-twice', $copath4);
is_output($svk, 'update', ['--sync', '--merge', $copath4], [
        "Syncing $uri/A-99",
        'Auto-merging (16, 16) /m-99 to /m-99-copy-twice (base /m-99:16).',
        "Empty merge.",
        "Syncing //m-99-copy-twice(/m-99-copy-twice) in $corpath4 to 20.",
        ]);

is_output($svk, 'smerge', ['-m', '', '--sync', '--from', $copath4], [
        "Auto-merging (0, 20) /m-99-copy-twice to /m-99 (base /m-99:16).",
        "Merging back to mirror source $uri/A-99.",
        "Empty merge.",
        ]);

is_output ($svk, 'delete', ['-m', 'die!', '//m-99'],
        ['Committed revision 22.']);
SKIP:{
skip 'recover not implemented.', 4;

$answer = 'y';
is_output ($svk, 'mirror', ['--recover', '//m'],
	   ['Analyzing revision 19...',
            '----------------------------------------------------------------------',
            'SVM: discard mirror for /m',
            'Analyzing revision 9...',
            '----------------------------------------------------------------------',
            'commit to deep mirrored path',
            'Committed revision 23.',
            'Committed revision 24.',
            "Property 'svm:headrev' set on repository revision 24.",
            "Property 'svn:author' set on repository revision 24.",
            "Property 'svn:date' set on repository revision 24.",
            "Property 'svn:log' set on repository revision 24.",
            'Mirror state successfully recovered.',
            'Committed revision 25.',
            '//m added back to the list of mirrored paths.',
           ]);

is_output ($svk, 'mirror', ['--recover', '//m'],
	   ['Analyzing revision 24...',
            '----------------------------------------------------------------------',
            'commit to deep mirrored path',
            'No need to revert; it is already the head revision.',
           ]);
$svk->mv (-m => 'move on mirror', '//m/Q' => '//m/Q-moved');
is_ancestor ($svk, '//m/Q-moved', '/m/Q', 6);

is_output ($svk, 'ps', ['foo' => 'bar', -m => 'ps on mirror', '//m/Q-moved'],
	   ["Merging back to mirror source $uri/A.",
	    'Merge back committed as revision 32.',
	    "Syncing $uri/A",
	    'Retrieving log information from 32 to 32',
	    'Committed revision 27 from revision 32.']);

}
