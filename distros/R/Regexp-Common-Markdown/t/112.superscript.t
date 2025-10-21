#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

## https://regex101.com/r/yAcNcX/1
my $tests = 
[
    {
        sup_all     => "^10^",
        sup_text    => 10,
        test        => q{2^10^ is 1024.},
    },
    {
        sup_all     => "^2^",
        sup_text    => 2,
        test        => q{H^2^0},
    },
    {
        fail => 1,
        name => "Space is not allowed",
        test => q{P^a cat^},
    },
    {
        name        => "Escaped space is ok",
        sup_all     => "^a\\ cat^",
        sup_text    => "a\\ cat",
        test        => q{P^a\ cat^},
    },
    {
        fail => 1,
        name => q{Line break is a no-no, even escaped},
        test => <<EOT,
P^a\
 cat^
EOT
    },
    {
        name        => q{Microsoft style},
        sup_all     => "<sup>This is a Microsoft superscript!</sup>",
        sup_text    => "This is a Microsoft superscript!",
        test        => q{Hmm <sup>This is a Microsoft superscript!</sup>},
    },
];

run_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{ExtSuperscript},
    type => 'Superscript extended',
});
