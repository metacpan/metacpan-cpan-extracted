#!/usr/bin/perl -w

use strict;

use Test::More tests => 5;
use File::Path;
use Cwd;
use SVK::Test;

my ($xd, $svk) = build_test();
our $output;
my ($copath, $corpath) = get_copath();
my (undef, undef, $repos) = $xd->find_repos ('//', 1);
my $uuid = $repos->fs->get_uuid;

$svk->mkdir ('-m', 'trunk', '//trunk');
$svk->checkout ('//', $copath);

# ok, we add A/a_file and commit as rev2 and play with it

is_output($svk, 'mkdir', [__"$copath/A"],
    [
        __"A   $copath/A",
    ]
);
overwrite_file(__"$copath/A/a_file", "a file\n");
is_output($svk, 'add', [__"$copath/A/a_file"],
    [
        __"A   $copath/A/a_file",
    ]
);
is_output($svk, 'ci', ['-m', 'add file and dir', __"$copath"],
    [
        "Committed revision 2.",
    ]
);

# desc command
{
    is_output($svk, 'desc', ['2', '//trunk'],
        [
            '----------------------------------------------------------------------',
            qr/^r2:.*/,
            '',
            'add file and dir',
            '----------------------------------------------------------------------',
            "=== A\t(new directory)",
            "==================================================================",
            "=== A/a_file",
            "==================================================================",
            "--- A/a_file\t(revision 1)",
            "+++ A/a_file\t(revision 2)",
            "@@ -0,0 +1 @@",
            "+a file",
        ]
    );
}

# diff command
{
    TODO: { local $TODO = 'even simple diff doesnt work :(';
    is_output($svk, 'di', ['-r', '1:2', '//trunk'],
        [
            __"=== A\t(new directory)",
            __"==================================================================",
            __"=== A/a_file",
            __"==================================================================",
            __"--- A/a_file\t(revision 1)",
            __"+++ A/a_file\t(local)",
            __"@@ -0,0 +1 @@",
            __"+a file",
        ]
    );
    }
}

