#!/usr/bin/perl -w
use Test::More tests => 2;
use strict;
use SVK::Test;
our $output;
my ($xd, $svk) = build_test();
my ($copath, $corpath) = get_copath ('import-nomime');
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);

mkdir ($copath);
chdir ($copath);

# Create some files with different mime types
create_mime_samples('mime');

delete $ENV{SVKMIME};
is_output ($svk, 'import', ['-m', 'import', '//import'],
    ["Committed revision 1.",
    'Import path //import initialized.',
    "Committed revision 2.",
    "Directory $corpath imported to depotpath //import as revision 2.",
    ]);
is_output ($svk, 'pl', ['-v', glob_mime_samples('//import/mime')],
    ['Properties on //import/mime/foo.bin:',
        '  svn:mime-type: application/octet-stream',
        'Properties on //import/mime/foo.jpg:',
        '  svn:mime-type: application/octet-stream',
    ]);
