#!/usr/bin/perl -w

use strict;

use Test::More tests => 16;
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

# ok, we add A/a_file in the checkout and play with it

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


# status command
{
    is_output($svk, 'st', [__"$copath"],
        [
            __"A   $copath/A",
            __"A   $copath/A/a_file",
        ]
    );
    is_output($svk, 'st', [__"$copath/A"],
        [
            __"A   $copath/A",
            __"A   $copath/A/a_file",
        ]
    );
    TODO: { local $TODO = "shouldn't report parent dir";
    is_output($svk, 'st', [__"$copath/A/a_file"],
        [
            __"A   $copath/A/a_file",
        ]
    );
    }
    is_output($svk, 'st', ['-N', __"$copath"],
        [
            __"A   $copath/A",
        ]
    );
    is_output($svk, 'st', ['-N', __"$copath/A"],
        [
            __"A   $copath/A",
            __"A   $copath/A/a_file",
        ]
    );
    TODO: { local $TODO = "shouldn't report parent dir";
    is_output($svk, 'st', ['-N', __"$copath/A/a_file"],
        [
            __"A   $copath/A/a_file",
        ]
    );
    }
}

# diff command
{
    is_output($svk, 'di', [__"$copath"],
        [
            __"=== $copath/A\t(new directory)",
            __"==================================================================",
            __"=== $copath/A/a_file",
            __"==================================================================",
            __"--- $copath/A/a_file\t(revision 1)",
            __"+++ $copath/A/a_file\t(local)",
            __"@@ -0,0 +1 @@",
            __"+a file",
        ]
    );
    is_output($svk, 'di', ['-N', __"$copath"],
        [
            __"=== $copath/A\t(new directory)",
            __"==================================================================",
        ]
    );
    is_output($svk, 'di', [__"$copath/A"],
        [
            __"=== $copath/A\t(new directory)",
            __"==================================================================",
            __"=== $copath/A/a_file",
            __"==================================================================",
            __"--- $copath/A/a_file\t(revision 1)",
            __"+++ $copath/A/a_file\t(local)",
            __"@@ -0,0 +1 @@",
            __"+a file",
        ]
    );
    is_output($svk, 'di', ['-N', __"$copath/A"],
        [
            __"=== $copath/A\t(new directory)",
            __"==================================================================",
            __"=== $copath/A/a_file",
            __"==================================================================",
            __"--- $copath/A/a_file\t(revision 1)",
            __"+++ $copath/A/a_file\t(local)",
            __"@@ -0,0 +1 @@",
            __"+a file",
        ]
    );
    TODO: { local $TODO = "shouldn't report parent dir";
    is_output($svk, 'di', [__"$copath/A/a_file"],
        [
            __"==================================================================",
            __"=== $copath/A/a_file",
            __"==================================================================",
            __"--- $copath/A/a_file        (revision 1)",
            __"+++ $copath/A/a_file        (local)",
            __"@@ -0,0 +1 @@",
            __"+a file",
        ]
    );
    is_output($svk, 'di', ['-N', __"$copath/A/a_file"],
        [
            __"==================================================================",
            __"=== $copath/A/a_file",
            __"==================================================================",
            __"--- $copath/A/a_file        (revision 1)",
            __"+++ $copath/A/a_file        (local)",
            __"@@ -0,0 +1 @@",
            __"+a file",
        ]
    );
    }
}

# chdir into added path and run status
{
    chdir __"$copath/A";
    is_output($svk, 'st', [],
        [
            __"A   ../A",
            __"A   ../A/a_file",
        ]
    );
    TODO: { local $TODO = "shouldn't report parent dir";
    is_output($svk, 'st', ['a_file'],
        [
            __"A   ../A/a_file",
        ]
    );
    }
}

