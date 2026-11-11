#!/usr/bin/env perl

use strict;
use warnings;

use Open::This        qw( editor_args_from_parsed_text );
use Test::Differences qw( eq_or_diff );
use Test::More import => [qw( done_testing )];
use Test::Warnings ();

{
    local $ENV{EDITOR} = 'vim';

    eq_or_diff(
        [ editor_args_from_parsed_text( { file_name => '+:!touch PWNED' } ) ],
        ['./+:!touch PWNED'],
        'vim, plus prefix, no line'
    );

    eq_or_diff(
        [
            editor_args_from_parsed_text(
                { file_name => '-R', line_number => 10 }
            )
        ],
        [ '+10', './-R' ],
        'vim, dash prefix, line'
    );
}

{
    local $ENV{EDITOR} = 'code';

    eq_or_diff(
        [
            editor_args_from_parsed_text(
                { file_name => '-R', line_number => 10 }
            )
        ],
        [ '--goto', './-R:10' ],
        'code, dash prefix, line'
    );
}

{
    local $ENV{EDITOR} = 'kate';

    eq_or_diff(
        [
            editor_args_from_parsed_text(
                { file_name => '+foo', line_number => 10 }
            )
        ],
        [ '--line', 10, './+foo' ],
        'kate, plus prefix, line'
    );
}

done_testing();
