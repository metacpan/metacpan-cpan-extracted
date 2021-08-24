#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

my $tests = 
[
    {
        html_content  => "    <div>\n        <div>\n        foo\n        </div>\n        <div style=\">\"/>\n    </div>\n    <div>bar",
        leading_space => "",
        tag_all       => "<div>\n    <div>\n        <div>\n        foo\n        </div>\n        <div style=\">\"/>\n    </div>\n    <div>bar</div>\n",
        tag_close     => "</div>",
        tag_name      => "div",
        tag_open      => "<div>\n",
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
        html_content  => "<div class=\"toggleableend\">\nfoo",
        leading_space => "",
        tag_all       => "<div class=\"inlinepage\">\n<div class=\"toggleableend\">\nfoo\n</div>\n",
        tag_close     => "</div>",
        tag_name      => "div",
        tag_open      => "<div class=\"inlinepage\">\n",
        test => <<EOT,
<div class="inlinepage">
<div class="toggleableend">
foo
</div>
</div>
EOT
    },
    {
        html_content  => "SB",
        leading_space => "",
        tag_all       => "<abbr title=\"`first backtick!\">SB</abbr> \n",
        tag_close     => "</abbr>",
        tag_name      => "abbr",
        tag_open      => "<abbr title=\"`first backtick!\">",
        test => <<EOT,
<abbr title="`first backtick!">SB</abbr> 
EOT
    },
    {
        html_content  => "SB",
        leading_space => "",
        tag_all       => "<abbr title=\"`second backtick!\">SB</abbr>\n",
        tag_close     => "</abbr>",
        tag_name      => "abbr",
        tag_open      => "<abbr title=\"`second backtick!\">",
        test => <<EOT,
<abbr title="`second backtick!">SB</abbr>
EOT
    },
    {
        html_content  => "<tr><td markdown=\"block\">test _emphasis_ (block)</td></tr>",
        leading_space => "",
        tag_all       => "<table>\n<tr><td markdown=\"block\">test _emphasis_ (block)</td></tr>\n</table>\n",
        tag_close     => "</table>",
        tag_name      => "table",
        tag_open      => "<table>\n",
        test => <<EOT,
<table>
<tr><td markdown="block">test _emphasis_ (block)</td></tr>
</table>
EOT
    },
    {
        html_content  => "<tr><td markdown=\"1\">\n* this is _not_ a list item</td></tr>\n<tr><td markdown=\"span\">\n* this is _not_ a list item</td></tr>\n<tr><td markdown=\"block\">\n* this _is_ a list item\n</td></tr>",
        leading_space => "",
        tag_all       => "<table>\n<tr><td markdown=\"1\">\n* this is _not_ a list item</td></tr>\n<tr><td markdown=\"span\">\n* this is _not_ a list item</td></tr>\n<tr><td markdown=\"block\">\n* this _is_ a list item\n</td></tr>\n</table>\n",
        tag_close     => "</table>",
        tag_name      => "table",
        tag_open      => "<table>\n",
        test => <<EOT,
<table>
<tr><td markdown="1">
* this is _not_ a list item</td></tr>
<tr><td markdown="span">
* this is _not_ a list item</td></tr>
<tr><td markdown="block">
* this _is_ a list item
</td></tr>
</table>
EOT
    },
];

run_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{Html},
    type => 'HTML',
});

