#!/usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;
plan tests => 4;

our ($output, $answer);

# build another tree to be mirrored ourself
my ($xd, $svk) = build_test('remote');

diag "create branches 1.0, 2.0 (copy of 1.0) on remote" if $ENV{'TEST_VERBOSE'};
{
    $svk->mkdir ('-m', '1.0', '/remote/1.0');
    $svk->copy ('-m', '2.0', '/remote/1.0' => '/remote/2.0');
    is_output ($svk, 'info', ['/remote/2.0'],
        ['Depot Path: /remote/2.0',
        'Revision: 2',
        'Last Changed Rev.: 2',
        qr'Last Changed Date: .*',
        'Copied From: /1.0, Rev. 1',
        'Merged From: /1.0, Rev. 1',
        '',]
    ) or diag $output;
}

diag "create mirror of 1.0 in //" if $ENV{'TEST_VERBOSE'};
{
    my ($srepospath, $spath, $srepos) = $xd->find_repos ('/remote/1.0', 1);
    my $uri = uri($srepospath);
    is_output ($svk, 'mirror', ['//1.0', $uri.($spath eq '/' ? '' : $spath)],
           ['Mirror initialized.  Run svk sync //1.0 to start mirroring.']);
}

diag "create mirror of 2.0 in //" if $ENV{'TEST_VERBOSE'};
{
    my ($srepospath, $spath, $srepos) = $xd->find_repos ('/remote/2.0', 2);
    my $uri = uri($srepospath);
    is_output ($svk, 'mirror', ['//2.0', $uri.($spath eq '/' ? '' : $spath)],
           ['Mirror initialized.  Run svk sync //2.0 to start mirroring.']);
}
$svk->sync ('-a', '//');

TODO: {
local $TODO = 'annotated copy info.';
is_output ($svk, 'info', ['//2.0'],
    ['Depot Path: //2.0',
    'Revision: 4',
    'Last Changed Rev.: 4',
    qr'Last Changed Date: .*',
    qr'Mirrored From: .*',
    'Copied From: /1.0, Rev. 3',
    'Merged From: /1.0, Rev. 3',
    '',]
) or diag $output;


}
