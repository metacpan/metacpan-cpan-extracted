use strict;
use warnings;

use Open::This        qw( to_editor_args );
use Test::Differences qw( eq_or_diff );
use Test::More import => [qw( done_testing )];
use Test::Warnings ();

# This gets really noisy on Travis if $ENV{EDITOR} is not set
local $ENV{EDITOR} = 'vim';

eq_or_diff(
    [
        to_editor_args(
            'https://github.com/oalders/open-this/blob/master/lib/Open/This.pm'
        )
    ],
    ['lib/Open/This.pm'],
    'full https GitHub URL'
);

eq_or_diff(
    [
        to_editor_args(
            'https://github.com/oalders/open-this/blob/master/lib/Open/This.pm#L75'
        )
    ],
    [ '+75', 'lib/Open/This.pm' ],
    'full https GitHub URL with fragment'
);

eq_or_diff(
    [
        to_editor_args(
            'https://github.com/oalders/open-this/blob/master/lib/Open/This.pm#L75-L80'
        )
    ],
    [ '+75', 'lib/Open/This.pm' ],
    'full https GitHub URL with fragment and line range'
);

eq_or_diff(
    [
        to_editor_args(
            'https://github.com/oalders/open-this/blob/master/lib/Open/This.pm#L75x'
        )
    ],
    ['lib/Open/This.pm'],
    'full https GitHub URL with invalid fragment'
);

eq_or_diff(
    [ to_editor_args('HTTP::FakeTestClass') ],
    ['t/lib/HTTP/FakeTestClass.pm'],
    'non-URL package name starting with HTTP gets handled properly'
);

done_testing();
