#!/usr/bin/perl -w

use strict;

use Test::More tests => 18;
use File::Path;
use Cwd;
use SVK::Test;

my ($xd, $svk) = build_test();
our $output;
my ($copath, $corpath) = get_copath();
my (undef, undef, $repos) = $xd->find_repos ('//', 1);
my $uuid = $repos->fs->get_uuid;

$svk->mkdir ('-m', 'trunk', '//trunk');
my $tree = create_basic_tree ($xd, '//trunk');
is_output($svk, 'ls', ['//trunk/'],
    [
        'A/',
        'B/',
        'C/',
        'D/',
        'me',
    ]
);
is_output($svk, 'ls', ['//trunk/A'],
    [
        'Q/',
        'be',
    ]
);
is_output($svk, 'ls', ['-R', '//trunk/'],
    [
        'A/',
        ' Q/',
        '  qu',
        '  qz',
        ' be',
        'B/',
        ' S/',
        '  P/',
        '   pe',
        '  Q/',
        '   qu',
        '   qz',
        '  be',
        ' fe',
        'C/',
        ' R/',
        'D/',
        ' de',
        'me',
    ]
);

is_output($svk, 'cat', ['//trunk/A/Q/qu'],
    [
        'first line in qu',
        '2nd line in qu',
    ]
);

is_output($svk, 'ann', ['//trunk/A/Q/qu'],
    [
        'Annotations for /trunk/A/Q/qu (1 active revisions):',
        '****************',
        qr{     2\t\(     \w+ \d{4}-\d{2}-\d{2}\):\t\tfirst line in qu},
        qr{     2\t\(     \w+ \d{4}-\d{2}-\d{2}\):\t\t2nd line in qu},
    ]
);

is_output($svk, 'ls', ['-R', '-r', '3', '//trunk/A'],
    [
        'Q/',
        ' qu',
        ' qz',
        'be',
    ]
);

is_output($svk, 'cat', ['-r', '3', '//trunk/A/Q/qu'],
    [
        'first line in qu',
        '2nd line in qu',
    ]
);

is_output($svk, 'ann', ['-r', '3', '//trunk/A/Q/qu'],
    [
        'Annotations for /trunk/A/Q/qu (1 active revisions):',
        '****************',
        qr{     2\t\(     \w+ \d{4}-\d{2}-\d{2}\):\t\tfirst line in qu},
        qr{     2\t\(     \w+ \d{4}-\d{2}-\d{2}\):\t\t2nd line in qu},
    ]
);

is_output($svk, 'rm', ['-m', 'remove //trunk/A', '//trunk/A'],
    [
        'Committed revision 4.',
    ]
);

is_output($svk, 'cp', ['-m', 'copy //local from //trunk', '//trunk', '//local'],
    [
        'Committed revision 5.',
    ]
);

is_output($svk, 'ls', ['//local/'],
    [
        'B/',
        'C/',
        'D/',
        'me',
    ]
);
is_output($svk, 'ls', ['-R', '//local/'],
    [
        'B/',
        ' S/',
        '  P/',
        '   pe',
        '  Q/',
        '   qu',
        '   qz',
        '  be',
        ' fe',
        'C/',
        ' R/',
        'D/',
        ' de',
        'me',
    ]
);

is_output($svk, 'ls', ['-r', '3', '//local/'],
    [
        'A/',
        'B/',
        'C/',
        'D/',
        'me',
    ]
);

is_output($svk, 'ls', ['-r', '3', '//local/A'],
    [
        'Q/',
        'be',
    ]
);

is_output($svk, 'ls', ['-R', '-r', '3', '//local/'],
    [
        'A/',
        ' Q/',
        '  qu',
        '  qz',
        ' be',
        'B/',
        ' S/',
        '  P/',
        '   pe',
        '  Q/',
        '   qu',
        '   qz',
        '  be',
        ' fe',
        'C/',
        ' R/',
        'D/',
        ' de',
        'me',
    ]
);

is_output($svk, 'ls', ['-R', '-r', '3', '//local/A'],
    [
        'Q/',
        ' qu',
        ' qz',
        'be',
    ]
);

is_output($svk, 'cat', ['-r', '3', '//local/A/Q/qu'],
    [
        'first line in qu',
        '2nd line in qu',
    ]
);

is_output($svk, 'ann', ['-r', '3', '//local/A/Q/qu'],
    [
        'Annotations for /trunk/A/Q/qu (1 active revisions):',
        '****************',
        qr{     2\t\(     \w+ \d{4}-\d{2}-\d{2}\):\t\tfirst line in qu},
        qr{     2\t\(     \w+ \d{4}-\d{2}-\d{2}\):\t\t2nd line in qu},
    ]
);

