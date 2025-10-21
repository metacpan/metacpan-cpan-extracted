#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

## https://regex101.com/r/gF6wVe/2
my $tests = 
[
    {
        sub_all     => "~10~",
        sub_text    => 10,
        test        => q{log~10~100 is 2.},
    },
    {
        sub_all     => "~2~",
        sub_text    => 2,
        test        => q{H~2~0},
    },
    {
        fail        => 1,
        name        => q{Space is not allowed},
        test        => q{P~a cat~},
    },
    {
        name        => q{Escaped space is ok},
        sub_all     => "~a\\ cat~",
        sub_text    => "a\\ cat",
        test        => q{P~a\ cat~},
    },
    {
        fail        => 1,
        name        => q{Line breaks are forbidden},
        test        => <<EOT,
P~a\
 cat~
EOT
    },
    {
        name        => q{Microsoft style},
        sub_all     => "<sub>This is a Microsoft subscript!</sub>",
        sub_text    => "This is a Microsoft subscript!",
        test        => q{<sub>This is a Microsoft subscript!</sub>},
    },
];

run_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{ExtSubscript},
    type => 'Subscript extended',
});
