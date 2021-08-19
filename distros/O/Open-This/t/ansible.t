use strict;
use warnings;

use Open::This qw( parse_text );
use Path::Tiny qw( path );
use Test::More;
use Test::Differences qw( eq_or_diff );
use Test::Warnings ();

# This gets really noisy on Travis if $ENV{EDITOR} is not set
local $ENV{EDITOR} = 'vim';

my $path = path('t/test-data/file-with-numbers-0.000020.txt')->absolute;

my @snippets = (
    qq{The error appears to be in '$path': line 14, column 16, but may be elsewhere in the file depending on the exact syntax problem.},
    qq{n '$path': line 14, column 16},
);

for my $original_text (@snippets) {
    {
        my $text = $original_text;
        my ( $line_number, $column_number )
            = Open::This::_maybe_extract_line_number( \$text );
        is( $line_number,   14, 'line_number' );
        is( $column_number, 16, 'column_number' );
    }

    {
        my $text = $original_text;
        eq_or_diff(
            parse_text($text),
            {
                column_number => 16,
                file_name     => $path->absolute->stringify,
                line_number   => 14,
                original_text => $original_text,
            },
            'parse_text'
        );
    }
}

{
    my $text = qq{'$path': line 14};
    eq_or_diff(
        parse_text($text),
        {
            file_name     => $path->absolute->stringify,
            line_number   => 14,
            original_text => $text,
        },
        'parse_text without column'
    );
}

{
    my $text = qq{'$path': };
    eq_or_diff(
        parse_text($text),
        {
            file_name     => $path->absolute->stringify,
            original_text => $text,
        },
        'parse_text without line'
    );
}

done_testing();
