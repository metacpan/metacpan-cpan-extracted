#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

## https://regex101.com/r/Y9lPAz/9
my $tests = 
[
    {
        code_all                => "~~~\n<div>\n~~~\n",
        code_content            => "<div>",
        code_start              => "~~~",
        with_tilde              => "~~~",
        test                    => <<EOT,
~~~
<div>
~~~
EOT
    },
    {
        code_all                => "~~~\nSome text\n\n\tIndented code block sample code\n~~~\n",
        code_content            => "Some text\n\n\tIndented code block sample code",
        code_start              => "~~~",
        with_tilde              => "~~~",
        test                    => <<EOT,
~~~
Some text

	Indented code block sample code
~~~
EOT
    },
    {
        code_all                => "~~~~~~~~~~~~~~~~~~\nFenced\n~~~~~~~~~~~~~~~~~~\n",
        code_content            => "Fenced",
        code_start              => "~~~~~~~~~~~~~~~~~~",
        with_tilde              => "~~~~~~~~~~~~~~~~~~",
        test                    => <<EOT,
~~~~~~~~~~~~~~~~~~
Fenced
~~~~~~~~~~~~~~~~~~
EOT
    },
    {
        code_all                => "~~~~\nIn code block\n~~~\nStill in code block\n~~~~~\nStill in code block\n~~~~\n",
        code_content            => "In code block\n~~~\nStill in code block\n~~~~~\nStill in code block",
        code_start              => "~~~~",
        with_tilde              => "~~~~",
        test                    => <<EOT,
~~~~
In code block
~~~
Still in code block
~~~~~
Still in code block
~~~~
EOT
    },
    {
        code_all                => "~~~~~html\n<b>bold</b>\n~~~~~\n",
        code_class              => "html",
        code_content            => "<b>bold</b>",
        code_start              => "~~~~~",
        with_tilde              => "~~~~~",
        test                    => <<EOT,
~~~~~html
<b>bold</b>
~~~~~
EOT
    },
    {
        code_all                => "~~~~~ html\n<b>bold</b>\n~~~~~\n",
        code_class              => "html",
        code_content            => "<b>bold</b>",
        code_start              => "~~~~~",
        with_tilde              => "~~~~~",
        test                    => <<EOT,
~~~~~ html
<b>bold</b>
~~~~~
EOT
    },
    {
        code_all                => "~~~~~.html\n<b>bold</b>\n~~~~~\n",
        code_class              => ".html",
        code_content            => "<b>bold</b>",
        code_start              => "~~~~~",
        with_tilde              => "~~~~~",
        test                    => <<EOT,
~~~~~.html
<b>bold</b>
~~~~~
EOT
    },
    {
        code_all                => "~~~~~ .html\n<b>bold</b>\n~~~~~\n",
        code_class              => ".html",
        code_content            => "<b>bold</b>",
        code_start              => "~~~~~",
        with_tilde              => "~~~~~",
        test                    => <<EOT,
~~~~~ .html
<b>bold</b>
~~~~~
EOT
    },
    {
        code_all                => "~~~~~ {.html #codeid}\n<b>bold</b>\n~~~~~\n",
        code_attr               => ".html #codeid",
        code_content            => "<b>bold</b>",
        code_start              => "~~~~~",
        with_tilde              => "~~~~~",
        test                    => <<EOT,
~~~~~ {.html #codeid}
<b>bold</b>
~~~~~
EOT
    },
    {
        code_all               => "~~~~~ .html{.bold}\n<div>\n~~~~~\n",
        code_attr              => ".bold",
        code_class             => ".html",
        code_content           => "<div>",
        code_start             => "~~~~~",
        with_tilde             => "~~~~~",
        test                    => <<EOT,
~~~~~ .html{.bold}
<div>
~~~~~
EOT
    },
];

run_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{ExtCodeBlock},
    type => 'Code extended',
});
