#!/usr/bin/perl -w
use Test::More tests => 24;
use strict;
use File::Path;
use Cwd;
use SVK::Test;


my ($xd, $svk) = build_test();
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
my $uuid = $repos->fs->get_uuid;

our ($output, $answer);

$svk->mkdir(-m => 'trunk', '//trunk');
my ($copath, $corpath) = get_copath ('smerge-tree');
$svk->checkout ('//trunk', $copath);
chdir($copath);

$svk->mkdir('dir');
overwrite_file('dir/file', "foo\n");
$svk->add('dir');
$svk->ci(-m => 'add tree');

$svk->copy (-m => 'local', '//trunk', '//local');
$svk->switch('//local');
overwrite_file('dir/file', "bar\n");
$svk->ci(-m => 'change file in local');

$svk->rm(-m => 'remove dir with the file in trunk' => '//trunk/dir');

is_output ($svk, 'smerge', ['-C' => '//trunk' => '//local'], [
    'Auto-merging (2, 5) /trunk to /local (base /trunk:2).',
	'C   dir',
	'C   dir/file',
    "New merge ticket: $uuid:/trunk:5",
	'Empty merge.',
    '2 conflicts found.',
]);

$ENV{SVKRESOLVE} = 't'; # thiers(delete //local/dir/file)
is_output ($svk, 'smerge', ['-m' => 'smerge tree conflict', '//trunk' => '//local'], [
    'Auto-merging (2, 5) /trunk to /local (base /trunk:2).',
	'D   dir',
    "New merge ticket: $uuid:/trunk:5",
	'Committed revision 6.',
]);

$svk->switch('//trunk');
is_output ($svk, 'st', [], []);

{
    mkdir 'dir';
    overwrite_file('dir/file', "foo\n");
    $svk->add('dir');
    $svk->ci(-m => 'add tree');

    $svk->sm (-m => 'smerge', '//trunk', '//local');

    $svk->switch('//local');
    is_output ($svk, 'cat', ['//local/dir/file'], [ 'foo' ]);
    is_output ($svk, 'cat', ['dir/file'], [ 'foo' ]);
#    overwrite_file('dir/file', 'bar');
#    { local $TODO = "something strange happens here";
#        is_output ($svk, 'st', [], [ 'M   dir/file' ]);
#        is_output ($svk, 'ci', [-m => 'change the file in local', 'dir/file'], [ 'M   dir/file' ]);
#    }
    overwrite_file('dir/file', "foobar\n");
    is_output ($svk, 'st', [], [ __('M   dir/file') ]);
    is_output ($svk, 'ci', [-m => 'change the file in local', 'dir/file'], [ 'Committed revision 9.' ]);

    $svk->rm(-m => 'remove the dir in trunk' => '//trunk/dir');

    is_output ($svk, 'smerge', [-C => '//trunk' => '//local'], [
        'Auto-merging (7, 10) /trunk to /local (base /trunk:7).',
        'C   dir',
        'C   dir/file',
        "New merge ticket: $uuid:/trunk:10",
        'Empty merge.',
        '2 conflicts found.',
    ]);
    $ENV{'SVKRESOLVE'} = 'y';
    is_output ($svk, 'smerge', [-m => 'merge', '//trunk' => '//local'], [
        'Auto-merging (7, 10) /trunk to /local (base /trunk:7).',
        'G   dir',
        'G   dir/file',
        "New merge ticket: $uuid:/trunk:10",
	    'Committed revision 11.',
    ]);
    is_output ($svk, 'cat', ['//local/dir/file'], [ 'foobar' ]);

    $svk->rm(-m => 'remove manually', '//local/dir');
    $svk->sm(-m => 'smerge', '//trunk' => '//local');

    $svk->switch('//trunk');
    is_output ($svk, 'st', [], []);
}

{
    $svk->mkdir('dir');
    overwrite_file('dir/file', "foo\n");
    $svk->add('dir');
    $svk->ci(-m => 'add tree');

    $svk->sm (-m => 'smerge', '//trunk', '//local');

    $svk->switch('//local');
    overwrite_file('dir/new_local_file', "bar\n");
    $svk->add('dir/new_local_file');
    $svk->ci(-m => 'add new file in local');
    is_output ($svk, 'cat', ['//local/dir/new_local_file'], [ 'bar' ]);

    $svk->rm(-m => 'remove the dir in trunk' => '//trunk/dir');

    is_output ($svk, 'smerge', [-C => '//trunk' => '//local'], [
        'Auto-merging (13, 16) /trunk to /local (base /trunk:13).',
        'C   dir',
        'D   dir/file',
        'C   dir/new_local_file',
        "New merge ticket: $uuid:/trunk:16",
        'Empty merge.',
        '2 conflicts found.',
    ]);
    $ENV{'SVKRESOLVE'} = 'y';
    is_output ($svk, 'smerge', [-m => 'merge', '//trunk' => '//local'], [
        'Auto-merging (13, 16) /trunk to /local (base /trunk:13).',
        'G   dir',
        'D   dir/file',
        'G   dir/new_local_file',
        "New merge ticket: $uuid:/trunk:16",
        'Committed revision 17.',
    ]);
    is_output ($svk, 'cat', ['//local/dir/new_local_file'], [ 'bar' ]);

    $svk->rm(-m => 'remove manually', '//local/dir');
    $svk->sm(-m => 'smerge', '//trunk' => '//local');

    $svk->switch('//trunk');
    is_output ($svk, 'st', [], []);
}

{
    $svk->mkdir('dir');
    overwrite_file('dir/file', "foo\n");
    $svk->add('dir');
    $svk->ci(-m => 'add tree');

    $svk->sm (-m => 'smerge', '//trunk', '//local');

    $svk->switch('//local');
    overwrite_file('dir/new_local_file', "bar\n");
    $svk->add('dir/new_local_file');
    $svk->ci(-m => 'add new file in local');

    $svk->rm(-m => 'remove the dir in trunk' => '//trunk/dir');

    is_output ($svk, 'smerge', [-C => '//trunk' => '//local'], [
        'Auto-merging (19, 22) /trunk to /local (base /trunk:19).',
        'C   dir',
        'D   dir/file',
        'C   dir/new_local_file',
        "New merge ticket: $uuid:/trunk:22",
        'Empty merge.',
        '2 conflicts found.',
    ]);
    { local $TODO = "not yet implemented";
        # their - empty, base - empty, yours - our content
        # SVK::Resolve thinks we have no conflict and leave the
        # content even if we want to delete it :)
        $ENV{'SVKRESOLVE'} = 't';
        is_output ($svk, 'smerge', [-m => 'merge', '//trunk' => '//local'], [
            'Auto-merging (19, 22) /trunk to /local (base /trunk:19).',
            'D   dir',
            'D   dir/file',
            'D   dir/new_local_file',
            "New merge ticket: $uuid:/trunk:22",
            'Committed revision 23.',
        ]);
        is_output ($svk, 'ls', ['//local'], [ '' ]);
        # XXX: delete this lines when you'll drop TODO
        $svk->rm(-m => 'remove manually', '//local/dir');
        $svk->sm(-m => 'smerge', '//trunk' => '//local');
    }

    $svk->switch('//trunk');
    is_output ($svk, 'st', [], []);
}

{
    $svk->mkdir(-p => 'dir/sub');
    $svk->ci(-m => 'add tree');

    $svk->sm (-m => 'smerge', '//trunk', '//local');

    $svk->switch('//local');
    $svk->rm('dir/sub');
    $svk->ci(-m => 'delete subdir in local');
    overwrite_file('dir/sub', "bar\n");
    $svk->add('dir/sub');
    $svk->ci(-m => 'add file in place of subdir');

    $svk->rm(-m => 'remove the dir in trunk' => '//trunk/dir');

    is_output ($svk, 'smerge', [-C => '//trunk' => '//local'], [
        'Auto-merging (25, 29) /trunk to /local (base /trunk:25).',
        'C   dir',
        'C   dir/sub',
        "New merge ticket: $uuid:/trunk:29",
        'Empty merge.',
        '2 conflicts found.',
    ]);
    { local $TODO = "not yet implemented";
        $ENV{'SVKRESOLVE'} = 't';
        is_output ($svk, 'smerge', [-m => 'merge', '//trunk' => '//local'], [
            'Auto-merging (25, 29) /trunk to /local (base /trunk:25).',
            'D   dir',
            'D   dir/sub',
            "New merge ticket: $uuid:/trunk:29",
            'Committed revision 30.',
        ]);
        is_output ($svk, 'ls', ['//local'], [ '' ]);
        # XXX: delete this lines when you'll drop TODO
        $svk->rm(-m => 'remove manually', '//local/dir');
        $svk->sm(-m => 'smerge', '//trunk' => '//local');
    }

    $svk->switch('//trunk');
    is_output ($svk, 'st', [], []);
}

