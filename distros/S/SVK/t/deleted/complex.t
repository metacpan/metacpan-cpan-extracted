#!/usr/bin/perl -w

use strict;

use Test::More tests => 82;
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

$svk->checkout ('//trunk', $copath);
chdir $copath;

overwrite_file('A/Q/qu', "trunk A/Q/qu\n");
overwrite_file('A/be', "trunk A/be\n");
is_output($svk, 'ci', ['-m', 'set files'], ['Committed revision 4.']);

is_output($svk, 'cp', ['-m', 'copy //local from //trunk', '//trunk', '//local'],
    ['Committed revision 5.']
);

is_output($svk, 'switch', ['//local'],
    ["Syncing //trunk(/trunk) in $corpath to 5."]
);
overwrite_file('A/Q/ql', "local A/Q/ql\n");
$svk->add('A/Q/ql');
overwrite_file('A/Q/qu', "local A/Q/qu\n");
overwrite_file('A/be', "local A/be\n");
is_output($svk, 'ci', ['-m', 'set files'], ['Committed revision 6.']);

is_output($svk, 'cp', ['-m', 'copy //local-another from //trunk', '//trunk', '//local-another'],
    ['Committed revision 7.']
);

is_sorted_output($svk, 'switch', ['//local-another'],
    [
        "Syncing //local(/local) in $corpath to 7.",
        __"U   A/Q/qu",
        __"D   A/Q/ql",
        __"U   A/be",
    ]
);
overwrite_file('A/Q/qu', "local-another A/Q/qu\n");
overwrite_file('A/be', "local-another A/be\n");
is_output($svk, 'ci', ['-m', 'set files'],
    ['Committed revision 8.']
);

# here is trick: delete A/Q/ql on //local, then replace A/Q in //local-another
# branch with A/Q from //local branch, then delete Q/, delete A/
# and try to ls/cat A/Q/qu, A/Q/ql and A/be using different revisions

is_output($svk, 'rm', [ '-m', 'remove A/Q/ql in //local', '//local/A/Q/ql'],
    ['Committed revision 9.']
);

is_sorted_output($svk, 'rm', ['A/Q'],
    [
        __"D   A/Q",
        __"D   A/Q/qu",
        __"D   A/Q/qz",
    ]
);
is_sorted_output($svk, 'cp', ['//local/A/Q', 'A/'],
    [
        __"A   A/Q",
        __"A   A/Q/qu",
        __"A   A/Q/qz",
    ]
);
is_output($svk, 'st', [],
    [__('R + A/Q')]
);
is_output($svk, 'ci', ['-m', 'replace A/Q'],
    ['Committed revision 10.']
);
is_output($svk, 'rm', ['-m', 'remove', '//local-another/A'],
    ['Committed revision 11.']
);

# head (rev 11)
{
    is_output($svk, 'ls', ['//local-another'],
        [
            'B/',
            'C/',
            'D/',
            'me',
        ]
    );
    is_output($svk, 'ls', ['-f', '//local-another'],
        [
            '//local-another/B/',
            '//local-another/C/',
            '//local-another/D/',
            '//local-another/me',
        ]
    );
    is_output_like($svk, 'ls', ['//local-another/A'], qr/is not versioned/);
    is_output_like($svk, 'cat', ['//local-another/A/Q/qu'], qr/not found/);
    is_output_like($svk, 'cat', ['//local-another/A/Q/ql'], qr/not found/);
    is_output_like($svk, 'cat', ['//local-another/A/be'], qr/not found/);
}

# -r 10
{
    is_output($svk, 'ls', ['-r', '10', '//local-another'],
        [
            'A/',
            'B/',
            'C/',
            'D/',
            'me',
        ]
    );
    is_output($svk, 'ls', ['-f', '-r', '10', '//local-another'],
        [
            '//local-another/A/',
            '//local-another/B/',
            '//local-another/C/',
            '//local-another/D/',
            '//local-another/me',
        ]
    );
    is_output($svk, 'ls', ['-r', '10', '//local-another/A/'],
        [
            'Q/',
            'be',
        ]
    );
    is_output($svk, 'ls', ['-f', '-r', '10', '//local-another/A/'],
        [
            '//local-another/A/Q/',
            '//local-another/A/be',
        ]
    );
    is_output($svk, 'ls', ['-f', '-r', '10', '//local-another/A/Q/qu'],
        [
            '//local-another/A/Q/qu',
        ]
    );
    is_output($svk, 'cat', ['-r', '10', '//local-another/A/Q/qu'],
        [
            'local A/Q/qu',
        ]
    );
    is_output($svk, 'cat', ['-r', '10', '//local-another/A/be'],
        [
            'local-another A/be',
        ]
    );
    is_output_like($svk, 'ls', ['-f', '-r', '10', '//local-another/A/Q/ql'],
        qr/not found/
    );
    is_output_like($svk, 'cat', ['-r', '10', '//local-another/A/Q/ql'],
        qr/not found/
    );
}

# -r 9 
{
    is_output($svk, 'ls', ['-r', '9', '//local-another'],
        [
            'A/',
            'B/',
            'C/',
            'D/',
            'me',
        ]
    );
    is_output($svk, 'ls', ['-f', '-r', '9', '//local-another'],
        [
            '//local-another/A/',
            '//local-another/B/',
            '//local-another/C/',
            '//local-another/D/',
            '//local-another/me',
        ]
    );
    is_output($svk, 'ls', ['-r', '9', '//local-another/A/'],
        [
            'Q/',
            'be',
        ]
    );
    is_output($svk, 'ls', ['-f', '-r', '9', '//local-another/A/'],
        [
            '//local-another/A/Q/',
            '//local-another/A/be',
        ]
    );
    is_output($svk, 'ls', ['-f', '-r', '9', '//local-another/A/Q/qu'],
        [
            '//local/A/Q/qu',
        ]
    );
    is_output($svk, 'cat', ['-r', '9', '//local-another/A/Q/qu'],
        [
            'local A/Q/qu',
        ]
    );
    is_output($svk, 'cat', ['-r', '9', '//local-another/A/be'],
        [
            'local-another A/be',
        ]
    );
    is_output_like($svk, 'ls', ['-f', '-r', '9', '//local-another/A/Q/ql'],
        qr/is not versioned/
    );
    is_output_like($svk, 'cat', ['-r', '9', '//local-another/A/Q/ql'],
        qr/not found/
    );
}

# PATH@9
{
    is_output($svk, 'ls', ['//local-another@9'],
        [
            'A/',
            'B/',
            'C/',
            'D/',
            'me',
        ]
    );
    is_output($svk, 'ls', ['-f', '//local-another@9'],
        [
            '//local-another/A/',
            '//local-another/B/',
            '//local-another/C/',
            '//local-another/D/',
            '//local-another/me',
        ]
    );
    is_output($svk, 'ls', ['//local-another/A/@9'],
        [
            'Q/',
            'be',
        ]
    );
    is_output($svk, 'ls', ['-f', '//local-another/A/@9'],
        [
            '//local-another/A/Q/',
            '//local-another/A/be',
        ]
    );
    is_output($svk, 'ls', ['-f', '//local-another/A/Q/qu@9'],
        [
            '//local-another/A/Q/qu',
        ]
    );
    is_output($svk, 'cat', ['//local-another/A/Q/qu@9'],
        [
            'local-another A/Q/qu',
        ]
    );
    is_output($svk, 'cat', ['//local-another/A/be@9'],
        [
            'local-another A/be',
        ]
    );
    is_output_like($svk, 'ls', ['-f', '//local-another/A/Q/ql@9'],
        qr/is not versioned/
    );
    is_output_like($svk, 'cat', ['//local-another/A/Q/ql@9'],
        qr/not found/
    );
}

# -r 8
{
    is_output($svk, 'ls', ['-r', '8', '//local-another'],
        [
            'A/',
            'B/',
            'C/',
            'D/',
            'me',
        ]
    );
    is_output($svk, 'ls', ['-f', '-r', '8', '//local-another'],
        [
            '//local-another/A/',
            '//local-another/B/',
            '//local-another/C/',
            '//local-another/D/',
            '//local-another/me',
        ]
    );
    is_output($svk, 'ls', ['-r', '8', '//local-another/A/'],
        [
            'Q/',
            'be',
        ]
    );
    is_output($svk, 'ls', ['-f', '-r', '8', '//local-another/A/'],
        [
            '//local-another/A/Q/',
            '//local-another/A/be',
        ]
    );
    is_output($svk, 'ls', ['-f', '-r', '8', '//local-another/A/Q/qu'],
        [
            '//local/A/Q/qu',
        ]
    );
    is_output($svk, 'cat', ['-r', '8', '//local-another/A/Q/qu'],
        [
            'local A/Q/qu',
        ]
    );
    is_output($svk, 'ls', ['-f', '-r', '8', '//local-another/A/be'],
        [
            '//local-another/A/be',
        ]
    );
    is_output($svk, 'cat', ['-r', '8', '//local-another/A/be'],
        [
            'local-another A/be',
        ]
    );
    is_output($svk, 'ls', ['-f', '-r', '8', '//local-another/A/Q/ql'],
        [
            '//local/A/Q/ql',
        ]
    );
    is_output($svk, 'cat', ['-r', '8', '//local-another/A/Q/ql'],
        [
            'local A/Q/ql',
        ]
    );
}

# -r 7 PATH@8
{
    is_output($svk, 'ls', ['-r', '7', '//local-another@8'],
        [
            'A/',
            'B/',
            'C/',
            'D/',
            'me',
        ]
    );
    is_output($svk, 'ls', ['-f', '-r', '7', '//local-another@8'],
        [
            '//local-another/A/',
            '//local-another/B/',
            '//local-another/C/',
            '//local-another/D/',
            '//local-another/me',
        ]
    );
    is_output($svk, 'ls', ['-r', '7', '//local-another/A/@8'],
        [
            'Q/',
            'be',
        ]
    );
    is_output($svk, 'ls', ['-f', '-r', '7', '//local-another/A/@8'],
        [
            '//local-another/A/Q/',
            '//local-another/A/be',
        ]
    );
    is_output($svk, 'ls', ['-f', '-r', '7', '//local-another/A/Q/qu@8'],
        [
            '//local-another/A/Q/qu',
        ]
    );
    is_output($svk, 'cat', ['-r', '7', '//local-another/A/Q/qu@8'],
        [
            'trunk A/Q/qu',
        ]
    );
    is_output($svk, 'ls', ['-f', '-r', '7', '//local-another/A/be@8'],
        [
            '//local-another/A/be',
        ]
    );
    is_output($svk, 'cat', ['-r', '7', '//local-another/A/be@8'],
        [
            'trunk A/be',
        ]
    );
    is_output_like($svk, 'ls', ['-f', '-r', '7', '//local-another/A/Q/ql@8'],
        qr/not found/
    );
    is_output_like($svk, 'cat', ['-r', '7', '//local-another/A/Q/ql@8'],
        qr/not found/
    );
}


# revision 6
{
    is_output($svk, 'ls', ['-r', '6', '//local-another'],
        [
            'A/',
            'B/',
            'C/',
            'D/',
            'me',
        ]
    );
    is_output($svk, 'ls', ['-f', '-r', '6', '//local-another'],
        [
            '//trunk/A/',
            '//trunk/B/',
            '//trunk/C/',
            '//trunk/D/',
            '//trunk/me',
        ]
    );
    is_output($svk, 'ls', ['-r', '6', '//local-another/A/'],
        [
            'Q/',
            'be',
        ]
    );
    is_output($svk, 'ls', ['-f', '-r', '6', '//local-another/A/'],
        [
            '//trunk/A/Q/',
            '//trunk/A/be',
        ]
    );
    is_output($svk, 'ls', ['-f', '-r', '6', '//local-another/A/Q/qu'],
        [
            '//local/A/Q/qu',
        ]
    );
    is_output($svk, 'cat', ['-r', '6', '//local-another/A/Q/qu'],
        [
            'local A/Q/qu',
        ]
    );
    is_output($svk, 'ls', ['-f', '-r', '6', '//local-another/A/be'],
        [
            '//trunk/A/be',
        ]
    );
    is_output($svk, 'cat', ['-r', '6', '//local-another/A/be'],
        [
            'trunk A/be',
        ]
    );
}

# revision 6 PATH@8
{
    is_output($svk, 'ls', ['-r', '6', '//local-another@8'],
        [
            'A/',
            'B/',
            'C/',
            'D/',
            'me',
        ]
    );
    is_output($svk, 'ls', ['-f', '-r', '6', '//local-another@8'],
        [
            '//trunk/A/',
            '//trunk/B/',
            '//trunk/C/',
            '//trunk/D/',
            '//trunk/me',
        ]
    );
    is_output($svk, 'ls', ['-r', '6', '//local-another/A/@8'],
        [
            'Q/',
            'be',
        ]
    );
    is_output($svk, 'ls', ['-f', '-r', '6', '//local-another/A/@8'],
        [
            '//trunk/A/Q/',
            '//trunk/A/be',
        ]
    );
    is_output($svk, 'ls', ['-f', '-r', '6', '//local-another/A/Q/qu@8'],
        [
            '//trunk/A/Q/qu',
        ]
    );
    is_output($svk, 'cat', ['-r', '6', '//local-another/A/Q/qu@8'],
        [
            'trunk A/Q/qu',
        ]
    );
    is_output($svk, 'ls', ['-f', '-r', '6', '//local-another/A/be@8'],
        [
            '//trunk/A/be',
        ]
    );
    is_output($svk, 'cat', ['-r', '6', '//local-another/A/be@8'],
        [
            'trunk A/be',
        ]
    );
}

