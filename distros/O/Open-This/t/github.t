use strict;
use warnings;

use Open::This qw( parse_text to_editor_args );
use Test::More;
use Test::Differences;

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
            'https://github.com/oalders/open-this/blob/master/lib/Open/This.pm#L75x'
        )
    ],
    ['lib/Open/This.pm'],
    'full https GitHub URL with invalid fragment'
);

done_testing();

