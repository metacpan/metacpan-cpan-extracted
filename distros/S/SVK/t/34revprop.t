#!/usr/bin/perl -w
use Test::More tests => 12;
use strict;
use File::Temp;
use SVK::Test;

my ($xd, $svk) = build_test();
our $output;
my ($copath, $corpath) = get_copath ('revprop');
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
$svk->checkout ('//', $copath);
mkdir "$copath/A";
overwrite_file ("$copath/A/foo", "foobar1");
$svk->add("$copath/A");
$svk->commit('-m' => 'log1', "$copath/A");
overwrite_file ("$copath/A/foo", "foobar2");
$svk->commit('-m' => 'log2', "$copath/A");
is_output ($svk, 'pl', ['--revprop'],
	   ['Revision required.']);
is_output_like(
    $svk, 'proplist', ['-r' => 2, '--revprop'],
    qr{Unversioned properties on revision 2:\n.*  svn:date\n.*  svn:log}s,
);
is_output(
    $svk, 'propget', ['-r' => 1, '--revprop', 'svn:log'],
    ['log1']
);
is_output(
    $svk, 'propget', ['-r' => 2, '--revprop', 'svn:log'],
    ['log2']
);

is_output(
    $svk, 'propset', ['--quiet', '-r2', '--revprop', 'svn:log', 'log2.new'],
    [   ]
);
is_output(
    $svk, 'propset', ['-r2', '--revprop', 'svn:log', 'log2.new'],
    ["Property 'svn:log' set on repository revision 2."]
);
is_output(
    $svk, 'propget', ['-r2', '--revprop', 'svn:log'],
    ['log2.new']
);

is_output(
    $svk, 'propdel', ['-q', '-r2', '--revprop', 'svn:log'],
    [   ]
);
is_output(
    $svk, 'propdel', ['-r2', '--revprop', 'svn:log'],
    ["Property 'svn:log' deleted from repository revision 2."]
);
is_output_like(
    $svk, 'proplist', ['-r2', '--revprop'],
    qr{(?!.*svn:log)Unversioned properties on revision 2:\n.*  svn:date\n}s,
);

set_editor(<< 'TMP');
$_ = shift;
open _ or die $!;
@_ = ("prepended_prop\n", <_>);
close _;
unlink $_;
open _, '>', $_ or die $!;
print _ @_;
close _;
TMP

is_output(
    $svk, 'propedit', ['-r' => 1, '--revprop', 'svn:log'],
    ['Waiting for editor...', "Property 'svn:log' set on repository revision 1."]
);
is_output(
    $svk, 'propget', ['-r' => 1, '--revprop', 'svn:log'],
    ['prepended_prop', 'log1']
);
