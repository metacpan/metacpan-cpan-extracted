# Test origin: AI
use v5.36;
use Test2::V0;

use Review::Helper::Split;

my $CLASS = 'Review::Helper::Split';

subtest kind_for => sub {
    is($CLASS->kind_for('lib/Foo.pm'),      'perl',       "module");
    is($CLASS->kind_for('t/unit/Foo.t'),    'perl',       "test");
    is($CLASS->kind_for('Makefile.PL'),     'perl',       "extension case is ignored");
    is($CLASS->kind_for('share/js/app.js'), 'javascript', "javascript");
    is($CLASS->kind_for('x.mjs'),           'javascript', "module javascript");
    is($CLASS->kind_for('share/css/a.css'), 'css',        "css");
    is($CLASS->kind_for('index.html'),      'html',       "html");
    is($CLASS->kind_for('README.md'),       'markdown',   "markdown");
    is($CLASS->kind_for('img/logo.PNG'),    'image',      "image");
    is($CLASS->kind_for('img/logo.svg'),    'text',       "svg is text: git diffs it");
    is($CLASS->kind_for('notes.txt'),       'text',       "other text");
    is($CLASS->kind_for('a.dir/README'),    'text',       "dot in a directory is not an extension");

    my %by_ext = (
        'bin/setup.sh'      => 'shell',
        'bin/run.bash'      => 'shell',
        '.zshrc'            => 'shell',
        'lib/app.ts'        => 'typescript',
        'ui/App.tsx'        => 'typescript',
        'ui/App.jsx'        => 'javascript',
        'schema.sql'        => 'sql',
        'package.json'      => 'json',
        'ci.yml'            => 'yaml',
        'conf.YAML'         => 'yaml',
        'dist.ini'          => 'ini',
        'setup.cfg'         => 'ini',
        'Cargo.toml'        => 'toml',
        'tool.py'           => 'python',
        'tasks/db.rake'     => 'ruby',
        'main.go'           => 'go',
        'src/main.rs'       => 'rust',
        'src/a.c'           => 'c',
        'src/a.h'           => 'c',
        'src/a.cpp'         => 'cpp',
        'src/A.java'        => 'java',
        'pom.xml'           => 'xml',
        'fix.patch'         => 'diff',
        'changes.diff'      => 'diff',
        'rules.mk'          => 'makefile',
        'sub/Makefile'      => 'makefile',
        'GNUmakefile'       => 'makefile',
        'docker/Dockerfile' => 'dockerfile',
    );
    is($CLASS->kind_for($_), $by_ext{$_}, "$_ is $by_ext{$_}") for sort keys %by_ext;

    my %by_line = (
        '#!/usr/bin/env perl'       => 'perl',
        '#!/usr/bin/perl -w'        => 'perl',
        '#!/usr/bin/perl5.36'       => 'perl',
        '#!/bin/sh'                 => 'shell',
        '#! /bin/bash -e'           => 'shell',
        '#!/usr/bin/env zsh'        => 'shell',
        '#!/bin/dash'               => 'shell',
        '#!/usr/bin/env node'       => 'javascript',
        '#!/usr/bin/env python3'    => 'python',
        '#!/usr/bin/python3.12'     => 'python',
        '#!/usr/bin/env -S ruby -w' => 'ruby',
        '#!/usr/bin/env FOO=1 perl' => 'perl',
        '#!/usr/bin/awk -f'         => 'text',
        '#!/usr/bin/env'            => 'text',
        '# not a shebang: /bin/sh'  => 'text',
    );
    is($CLASS->kind_for('scripts/tool', $_),              $by_line{$_}, "'$_' gives $by_line{$_}") for sort keys %by_line;
    is($CLASS->kind_for('scripts/tool'),                  'text',       "no first line");
    is($CLASS->kind_for('scripts/tool.cgi', '#!/bin/sh'), 'shell',      "an unknown extension still reads the #! line");
    is($CLASS->kind_for('lib/a.js', '#!/bin/sh'),         'javascript', "a known extension wins over the #! line");
};

subtest lines => sub {
    is($CLASS->lines(''),        [],            "empty");
    is($CLASS->lines("a\nb\n"),  ['a', 'b'],    "final newline");
    is($CLASS->lines("a\nb"),    ['a', 'b'],    "no final newline");
    is($CLASS->lines("a\n\n\n"), ['a', '', ''], "blank lines at the end");
};

subtest assemble => sub {
    my $units = [
        {name => 'b', package => 'P', ranges => [[3, 4]], doc_ranges => [[6, 6]]},
        {name => 'a', package => 'P', ranges => [[2, 2]], doc_ranges => [[1, 1]]},
    ];

    is(
        $CLASS->assemble($units, [('x') x 4, '', 'doc', '']),
        [
            {name => 'a', package => 'P', ranges => [[2, 2]], doc_ranges => [[1, 1]]},
            {name => 'b', package => 'P', ranges => [[3, 5]], doc_ranges => [[6, 7]]},
        ],
        "sections in file order; a blank run joins the code or documentation before it",
    );
    is($units->[0]->{ranges}, [[3, 4]], "the units given are not changed");

    is(
        $CLASS->assemble([{name => 'a', package => undef, ranges => [[3, 3]], doc_ranges => []}], ['', ' ', 'a']),
        [{name => 'a', package => undef, ranges => [[1, 3]], doc_ranges => []}],
        "a blank run at the top of the file joins the section after it",
    );

    like(
        dies { $CLASS->assemble([{name => 'a', package => undef, ranges => [[1, 1]], doc_ranges => []}], ['a', '', 'b']) },
        qr/Line 3 is in no section/,
        "a line with text in no section is an error, named by that line",
    );
    is($CLASS->assemble([], ['a', '', 'b']), [], "no units: the file is left whole");
    is($CLASS->assemble([], []),             [], "empty text has no sections");

    is($CLASS->to_ranges(5, 1, 3, 2), [[1, 3], [5, 5]], "to_ranges sorts and joins lines");
};

done_testing;
