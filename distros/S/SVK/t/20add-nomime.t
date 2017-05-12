#!/usr/bin/perl -w
use Test::More tests => 2;
use strict;
use SVK::Test;

our $output;
my ($xd, $svk) = build_test();
my ($copath, $corpath) = get_copath();
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
$svk->checkout ('//', $copath);

chdir ($copath);

# Create some files with different mime types
create_mime_samples('mime');

# make sure that simple binary/not-binary detection is done
delete $ENV{SVKMIME};
is_output ($svk, 'add', ['mime'],
	   [__('A   mime'),
	    __('A   mime/empty.txt'),
        __('A   mime/false.bin'),
	    __('A   mime/foo.bin - (bin)'),
	    __('A   mime/foo.c'),
	    __('A   mime/foo.html'),
	    __('A   mime/foo.jpg - (bin)'),
	    __('A   mime/foo.pl'),
	    __('A   mime/foo.txt'),
        __('A   mime/not-audio.txt'),
	   ]);
is_output ($svk, 'pl', ['-v', glob("mime/*")],
	   [__('Properties on mime/foo.bin:'),
	    '  svn:mime-type: application/octet-stream',
	    __('Properties on mime/foo.jpg:'),
	    '  svn:mime-type: application/octet-stream',
	   ]);
