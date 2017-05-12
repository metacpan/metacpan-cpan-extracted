#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 13;

# working copy initialization
our $output;
my ($xd, $svk) = build_test('test');
my ($copath, $corpath) = get_copath ('log-xml');
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
$svk->checkout ('//', $copath);
chdir ($copath);

# create some files, copy them and set a property
mkdir ('A');
overwrite_file ("A/foo", "foobar\nfnord\n");
overwrite_file ("A/bar", "foobar\n");
$svk->add ('A');
$svk->commit ('-m', 'init');
$svk->cp ('//A/foo', 'foo-cp');
$svk->cp ('//A/bar', 'bar-cp');
overwrite_file ("foo-cp", "foobar\nfnord\nnewline");
$svk->ps ('mmm', 'xxx', 'A/foo');
$svk->commit ('-m', 'cp & ps <bad>xml</bad>');

# check the output so far
is_output (
    $svk, 'log', ['--xml'],
    [
        '<?xml version="1.0" encoding="utf-8"?>',
        '<log>',
        '<logentry revision="2">',
        qr{<author>.*?</author>},
        qr{<date>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z</date>},
        '<msg>cp &amp; ps &lt;bad&gt;xml&lt;/bad&gt;</msg>',
        '</logentry>',
        '<logentry revision="1">',
        qr{<author>.*?</author>},
        qr{<date>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z</date>},
        '<msg>init</msg>',
        '</logentry>',
        '</log>',
    ],
);
{
    local $ENV{SVKLOGOUTPUT} = 'xml';
    is_output(
        $svk, 'log', ['--quiet'],
        [
            '<?xml version="1.0" encoding="utf-8"?>',
            '<log>',
            '<logentry revision="2">',
            qr{<author>.*?</author>},
            qr{<date>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z</date>},
            '</logentry>',
            '<logentry revision="1">',
            qr{<author>.*?</author>},
            qr{<date>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z</date>},
            '</logentry>',
            '</log>',
        ],
    );
}
is_output(
    $svk, 'log', ['--output', 'junk', '--xml', '-v'],
    [
        'Ignoring --output junk. Using --xml.',
        '<?xml version="1.0" encoding="utf-8"?>',
        '<log>',
        '<logentry revision="2">',
        qr{<author>.*?</author>},
        qr{<date>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z</date>},
        '<paths>',
        '<path action="M">/A/foo</path>',
        '<path copyfrom-path="/A/bar" copyfrom-rev="1" action="A">/bar-cp</path>',
        '<path copyfrom-path="/A/foo" copyfrom-rev="1" action="M">/foo-cp</path>',
        '</paths>',
        '<msg>cp &amp; ps &lt;bad&gt;xml&lt;/bad&gt;</msg>',
        '</logentry>',
        '<logentry revision="1">',
        qr{<author>.*?</author>},
        qr{<date>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z</date>},
        '<paths>',
        '<path action="A">/A</path>',
        '<path action="A">/A/bar</path>',
        '<path action="A">/A/foo</path>',
        '</paths>',
        '<msg>init</msg>',
        '</logentry>',
        '</log>',
    ],
);

# delete the author property
$svk->pd ('--revprop', '-r' => 2 , 'svn:author');

$svk->mirror ('/test/A', uri("$repospath/A"));
$svk->sync ('/test/A');

# check the "no author" behavior, etc
is_output(
    $svk, 'log', ['--xml', '-v', '-l1', '/test/'],
    [
        '<?xml version="1.0" encoding="utf-8"?>',
        '<log>',
        '<logentry revision="3" original="2">',
        qr{<date>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z</date>},
        '<paths>',
        '<path action="M">/A/foo</path>',
        '</paths>',
        '<msg>cp &amp; ps &lt;bad&gt;xml&lt;/bad&gt;</msg>',
        '</logentry>',
        '</log>',
    ],
);
is_output(
    $svk, 'log', ['--xml', '-v', '-l1', '/test/A/'],
    [
        '<?xml version="1.0" encoding="utf-8"?>',
        '<log>',
        '<logentry revision="3" original="2">',
        qr{<date>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z</date>},
        '<paths>',
        '<path action="M">/A/foo</path>',
        '</paths>',
        '<msg>cp &amp; ps &lt;bad&gt;xml&lt;/bad&gt;</msg>',
        '</logentry>',
        '</log>',
    ],
);
is_output (
    $svk, 'log', ['--xml', '-q', '--verbose', '--limit', '1' ,'/test/A/'],
    [
        '<?xml version="1.0" encoding="utf-8"?>',
        '<log>',
        '<logentry revision="3" original="2">',
        qr{<date>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z</date>},
        '<paths>',
        '<path action="M">/A/foo</path>',
        '</paths>',
        '</logentry>',
        '</log>',
    ]
);
is_output(
    $svk, 'log', ['--xml', '-v', '-r2@', '/test/A/'],
    [
        '<?xml version="1.0" encoding="utf-8"?>',
        '<log>',
        '<logentry revision="3" original="2">',
        qr{<date>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z</date>},
        '<paths>',
        '<path action="M">/A/foo</path>',
        '</paths>',
        '<msg>cp &amp; ps &lt;bad&gt;xml&lt;/bad&gt;</msg>',
        '</logentry>',
        '</log>',
    ]
);

# try some bad revisions
is_output (
    $svk, 'log', ['--xml', '-v', '-r5@', '/test/A/'],
    ["Can't find local revision for 5 on /A."]
);

is_output (
    $svk, 'log', ['--xml', -r => 16384, -l1 => '/test/A'],
    [
        'Revision too large, show log from 3.',
        '<?xml version="1.0" encoding="utf-8"?>',
        '<log>',
        '<logentry revision="3" original="2">',
        qr{<date>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z</date>},
        '<msg>cp &amp; ps &lt;bad&gt;xml&lt;/bad&gt;</msg>',
        '</logentry>',
        '</log>',
    ]
);

is_output (
    $svk, 'log', ['--xml', -r => 'asdf', '/test/A'],
    ['asdf is not a number.']
);

# remove A from the repo
$svk->update ('A');
$svk->rm (-m => 'bye', '//A');

is_output(
    $svk, 'log', [ '--xml', -l1 => 'A' ],
    [
        '<?xml version="1.0" encoding="utf-8"?>',
        '<log>',
        '<logentry revision="2">',
        qr{<date>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z</date>},
        '<msg>cp &amp; ps &lt;bad&gt;xml&lt;/bad&gt;</msg>',
        '</logentry>',
        '</log>',
    ],
);

# mangle a revision
$svk->pd(qw{ --revprop -r 3 svn:date });
$svk->pd(qw{ --revprop -r 3 svn:log });
$svk->update();
is_output (
    $svk, 'log', [ '--xml', '-l1', '-v'],
    [
        '<?xml version="1.0" encoding="utf-8"?>',
        '<log>',
        '<logentry revision="3">',
        qr{<author>.*?</author>},
        '<paths>',
        '<path action="D">/A</path>',
        '</paths>',
        '</logentry>',
        '</log>',
    ],
);


# make sure non-existent filters die correctly.
is_output(
    $svk, 'log', ['--output', 'bzzz'],
    [
        q{Can't load log filter 'bzzz'.},
    ]
);
