#!/usr/bin/env perl

use strict;
use warnings;

use Open::This qw( to_editor_args );
use Test::Differences qw( eq_or_diff );
use Test::More;

local $ENV{EDITOR} = 'kate';

eq_or_diff(
    [ to_editor_args('t/git.t') ],
    [
        't/git.t',
    ],
    'filename'
);

eq_or_diff(
    [ to_editor_args('t/git.t:10') ],
    [
        '--line',
        '10',
        't/git.t',
    ],
    'line'
);

eq_or_diff(
    [ to_editor_args('t/git.t:10:22') ],
    [
        '--line',
        '10',
        '--column',
        '22',
        't/git.t',
    ],
    'line and column'
);

done_testing();
