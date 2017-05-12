#!/usr/bin/perl -w
use Test::More tests => 2;
use strict;
use SVK::Test;
our $output;
my ($xd, $svk) = build_test();
my ($copath, $corpath) = get_copath ('import-mime');
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);

mkdir ($copath);
chdir ($copath);

# Create some files with different mime types
create_mime_samples('mime');

SKIP: {
    eval { require File::Type };
    skip 'File::Type required for testing import with MIME', 2 if $@;

    $ENV{SVKMIME} = 'File::Type';
    is_output ($svk, 'import', ['-m', 'import', '//import'],
        ["Committed revision 1.",
        'Import path //import initialized.',
        "Committed revision 2.",
        "Directory $corpath imported to depotpath //import as revision 2.",
        ]);
    is_output ($svk, 'pl', ['-v', glob_mime_samples('//import/mime')],
        ['Properties on //import/mime/foo.bin:',
        '  svn:mime-type: application/octet-stream',
        'Properties on //import/mime/foo.html:',
        '  svn:mime-type: text/html',
        'Properties on //import/mime/foo.jpg:',
        '  svn:mime-type: image/jpeg',
        'Properties on //import/mime/not-audio.txt:',
        '  svn:mime-type: audio/x-669-mod',   # wrong, but it's what F::T says
        ]);
}
