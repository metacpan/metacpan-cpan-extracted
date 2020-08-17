#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

my $tests = 
[
    {
        html_after   => "\n",
        html_content => "\n    <div>\n        <div>\n        foo\n        </div>\n        <div style=\">\"/>\n    </div>\n    <div>bar</div>\n",
        tag_all      => "<div>\n    <div>\n        <div>\n        foo\n        </div>\n        <div style=\">\"/>\n    </div>\n    <div>bar</div>\n</div>\n",
        tag_close    => "</div>",
        tag_name     => "div",
        test => <<EOT,
<div>
    <div>
        <div>
        foo
        </div>
        <div style=">"/>
    </div>
    <div>bar</div>
</div>
EOT
    },
    {
        html_after     => "\n",
        html_content   => "\n<div class=\"toggleableend\">\nfoo\n</div>\n",
        tag_all        => "<div class=\"inlinepage\">\n<div class=\"toggleableend\">\nfoo\n</div>\n</div>\n",
        tag_attributes => " class=\"inlinepage\"",
        tag_close      => "</div>",
        tag_name       => "div",
        test => <<EOT,
<div class="inlinepage">
<div class="toggleableend">
foo
</div>
</div>
EOT
    }
];

run_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{Html},
    type => 'HTML',
});

