#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

## https://regex101.com/r/M6KCjp/3
my $tests = 
[
    {
        content           => "SB",
        div_close         => "</abbr>",
        div_open          => "<abbr title=\"`first backtick!\" markdown=\"1\">",
        html_markdown_all => "<abbr title=\"`first backtick!\" markdown=\"1\">SB</abbr> \n",
        leading_space     => "",
        mark_pat1         => "<abbr title=\"`first backtick!\" markdown=\"1\">SB</abbr> \n",
        quote             => "\"",
        tag_name          => "abbr",
        test => <<EOT,
<abbr title="`first backtick!" markdown="1">SB</abbr> 
EOT
    },
    {
        content           => "SB",
        div_close         => "</abbr>",
        div_open          => "<abbr markdown=\"1\" title=\"`second backtick!\">",
        html_markdown_all => "<abbr markdown=\"1\" title=\"`second backtick!\">SB</abbr>\n",
        leading_space     => "",
        mark_pat1         => "<abbr markdown=\"1\" title=\"`second backtick!\">SB</abbr>\n",
        quote             => "\"",
        tag_name          => "abbr",
        test => <<EOT,
<abbr markdown="1" title="`second backtick!">SB</abbr>
EOT
    },
    {
        content           => "    This is a code block however:\n\n        </div>\n\n    Funny isn't it? Here is a code span: `</div>`.",
        div_close         => "    </div>",
        div_open          => "    <div markdown=\"1\">\n\n",
        html_markdown_all => "\n    <div markdown=\"1\">\n\n    This is a code block however:\n\n        </div>\n\n    Funny isn't it? Here is a code span: `</div>`.\n\n    </div>\n",
        leading_space     => "    ",
        mark_pat1         => "\n    <div markdown=\"1\">\n\n    This is a code block however:\n\n        </div>\n\n    Funny isn't it? Here is a code span: `</div>`.\n\n    </div>\n",
        quote             => "\"",
        tag_name          => "div",
        test => <<EOT,
<div>
    <div markdown="1">

    This is a code block however:

        </div>

    Funny isn't it? Here is a code span: `</div>`.

    </div>
</div>
EOT
    },
    {
        content           => "test _emphasis_ (span)",
        div_close         => "</td>",
        div_open          => "<td markdown=\"1\">",
        html_markdown_all => "<td markdown=\"1\">test _emphasis_ (span)</td>",
        leading_space     => "",
        mark_pat2         => "<td markdown=\"1\">test _emphasis_ (span)</td>",
        quote             => "\"",
        tag_name          => "td",
        test => <<EOT,
<table>
<tr><td markdown="1">test _emphasis_ (span)</td></tr>
</table>
EOT
    },
    {
        content           => "\n* this is _not_ a list item",
        div_close         => "</td>",
        div_open          => "<td markdown=\"1\">",
        html_markdown_all => "<td markdown=\"1\">\n* this is _not_ a list item</td>",
        leading_space     => "",
        mark_pat2         => "<td markdown=\"1\">\n* this is _not_ a list item</td>",
        quote             => "\"",
        tag_name          => "td",
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
    {
        content           => "    This text is no code block: if it was, the \n    closing `<div>` would be too and the HTML block \n    would be invalid.\n\n    Markdown content in HTML blocks is assumed to be \n    indented the same as the block opening tag.\n\n    **This should be the third paragraph after the header.**",
        div_close         => "    </div>",
        div_open          => "    <div markdown=\"1\">\n",
        html_markdown_all => "\n    <div markdown=\"1\">\n    This text is no code block: if it was, the \n    closing `<div>` would be too and the HTML block \n    would be invalid.\n\n    Markdown content in HTML blocks is assumed to be \n    indented the same as the block opening tag.\n\n    **This should be the third paragraph after the header.**\n    </div>\n",
        leading_space     => "    ",
        mark_pat1         => "\n    <div markdown=\"1\">\n    This text is no code block: if it was, the \n    closing `<div>` would be too and the HTML block \n    would be invalid.\n\n    Markdown content in HTML blocks is assumed to be \n    indented the same as the block opening tag.\n\n    **This should be the third paragraph after the header.**\n    </div>\n",
        quote             => "\"",
        tag_name          => "div",
        test => <<EOT,
<div>
    <div markdown="1">
    This text is no code block: if it was, the 
    closing `<div>` would be too and the HTML block 
    would be invalid.

    Markdown content in HTML blocks is assumed to be 
    indented the same as the block opening tag.

    **This should be the third paragraph after the header.**
    </div>
</div>
EOT
    },
    {
        content           => "    * List item, not a code block\n\nSome text\n\n      This is a code block.",
        div_close         => "  </div>",
        div_open          => "  <div markdown=\"1\">\n",
        html_markdown_all => "\n  <div markdown=\"1\">\n    * List item, not a code block\n\nSome text\n\n      This is a code block.\n  </div>\n",
        leading_space     => "  ",
        mark_pat1         => "\n  <div markdown=\"1\">\n    * List item, not a code block\n\nSome text\n\n      This is a code block.\n  </div>\n",
        quote             => "\"",
        tag_name          => "div",
        test => <<EOT,
<div>
  <div markdown="1">
    * List item, not a code block

Some text

      This is a code block.
  </div>
</div>
EOT
    },
    {
        content           => "    This is not a code block since Markdown parse paragraph \n    content as span. Code spans like `</p>` are allowed though.",
        div_close         => "</p>",
        div_open          => "<p markdown=\"1\">\n",
        html_markdown_all => "<p markdown=\"1\">\n    This is not a code block since Markdown parse paragraph \n    content as span. Code spans like `</p>` are allowed though.\n</p>\n",
        leading_space     => "",
        mark_pat1         => "<p markdown=\"1\">\n    This is not a code block since Markdown parse paragraph \n    content as span. Code spans like `</p>` are allowed though.\n</p>\n",
        quote             => "\"",
        tag_name          => "p",
        test => <<EOT,
<p markdown="1">
    This is not a code block since Markdown parse paragraph 
    content as span. Code spans like `</p>` are allowed though.
</p>
EOT
    },
    {
        content           => "_Hello_ _world_",
        div_close         => "</p>",
        div_open          => "<p markdown=\"1\">",
        html_markdown_all => "<p markdown=\"1\">_Hello_ _world_</p>\n",
        leading_space     => "",
        mark_pat1         => "<p markdown=\"1\">_Hello_ _world_</p>\n",
        quote             => "\"",
        tag_name          => "p",
        test => <<EOT,
<p markdown="1">_Hello_ _world_</p>
EOT
    },
    {
        content           => "Some _span_ content.",
        div_close         => "</p>",
        div_open          => "<p class=\"test\" markdown=\"1\" \nid=\"12\">\n",
        html_markdown_all => "<p class=\"test\" markdown=\"1\" \nid=\"12\">\nSome _span_ content.\n</p>\n",
        leading_space     => "",
        mark_pat1         => "<p class=\"test\" markdown=\"1\" \nid=\"12\">\nSome _span_ content.\n</p>\n",
        quote             => "\"",
        tag_name          => "p",
        test => <<EOT,
<p class="test" markdown="1" 
id="12">
Some _span_ content.
</p>
EOT
    },
    {
        content           => "foo 3",
        div_close         => "</div>",
        div_open          => "<div markdown=1>\n",
        html_markdown_all => "<div markdown=1>\nfoo 3\n</div>\n",
        leading_space     => "",
        mark_pat1         => "<div markdown=1>\nfoo 3\n</div>\n",
        quote             => "",
        tag_name          => "div",
        test => <<EOT,
<div markdown=1>
foo 3
</div>
EOT
    },
];

run_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{ExtHtmlMarkdown},
    type => 'HTML Markdown extended',
});

