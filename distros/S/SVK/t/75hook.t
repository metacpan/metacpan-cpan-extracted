#!/usr/bin/perl -w
use strict;
use SVK::Util qw( is_executable );
use SVK::Test;
plan tests => 2;
our $output;

mkpath ["t/checkout/repos-hook"], 0, 0700 unless -d "t/checkout/repos-hook";

my ($xd, $svk) = build_test('test');

is_output_like ($svk, 'verify', [], qr'SYNOPSIS', 'help');

my $tree = create_basic_tree ($xd, '/test/');

my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/A', 1);

# install pre-commit hook

my $hook = install_perl_hook($srepospath, 'pre-commit', "warn \"foo\\n\";\nexit 1\n");

my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);

my $uri = uri($srepospath);
$svk->mirror ('//m', $uri.($spath eq '/' ? '' : $spath));
$svk->sync ('//m');

my ($copath, $corpath) = get_copath ('repos-hook');

$svk->checkout ('//m', $copath);
overwrite_file ("$copath/newfile", "new file to add\n");
$svk->add ("$copath/newfile");

is_output ($svk, 'ci', ['-m', 'test commit', $copath],
	   ['Commit into mirrored path: merging back directly.',
	    "Merging back to mirror source $uri/A.",
	    qr"A repository hook failed: .*'?pre-commit'? hook .* output.*:",
	    'foo', ''
	   ]);
1;
