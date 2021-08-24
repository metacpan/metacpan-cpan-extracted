#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN
{
    use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" );
};

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

## https://regex101.com/r/toEboU/3
my $tests_line = 
[
    {
        code_after => "",
        code_all => "\tcode block on the first line\n\t\n",
        code_content => "\n",
        code_prefix => "\t",
        test => <<EOT,
	code block on the first line
	
EOT
    },
    {
        code_after => "",
        code_all => "    code block indented by spaces\n\n",
        code_content => "code block indented by spaces\n\n",
        code_prefix => "    ",
        test => <<EOT,
    code block indented by spaces

EOT
    },
    {
        code_after => "",
        code_all => "\tthe lines in this block  \n\tall contain trailing spaces  \n\n",
        code_content => "all contain trailing spaces  \n\n",
        code_prefix => "\t",
        test => <<EOT,
	the lines in this block  
	all contain trailing spaces  

EOT
    },
    {
        fail => 1,
        test => "	code block on the last line",
    },
    {
        code_after => "",
        code_all => "\t```\n\t<Fenced>\n\t```\n\n",
        code_content => "```\n\n",
        code_prefix => "\t",
        test => <<EOT,
Indented code block containing fenced code block sample:

	```
	<Fenced>
	```

EOT
    },
];

## https://regex101.com/r/M6W99K/7
my $tests_block =
[
    {
        code_all => "```\nSome text\n\n\tIndented code block sample code\n```\n",
        code_content => "Some text\n\n\tIndented code block sample code",
        code_start => "```",
        test => <<EOT,

```
Some text

	Indented code block sample code
```

EOT
    },
    {
        code_all => "```\n<Fenced>\n```\n",
        code_content => "<Fenced>",
        code_start => "```",
        test => <<EOT,
```
<Fenced>
```

EOT
    },
    {
        code_all => "```\n\n\n<Fenced>\n\n\n```\n",
        code_content => "<Fenced>",
        code_start => "```",
        test => <<EOT,
Code block starting and ending with empty lines:

```


<Fenced>


```

EOT
    },
    {
        code_all => "```\nSome text\n\n\tIndented code block sample code\n```\n",
        code_content => "Some text\n\n\tIndented code block sample code",
        code_start => "```",
        test => <<EOT,
```
Some text

	Indented code block sample code
```

EOT
    },
    {
        code_all => "``````````````````\nFenced\n``````````````````\n",
        code_content => "Fenced",
        code_start => "``````````````````",
        test => <<EOT,
Fenced code block with long markers:

``````````````````
Fenced
``````````````````

EOT
    },
    {
        code_all => "````\nIn code block\n```\nStill in code block\n`````\nStill in code block\n````\n",
        code_content => "In code block\n```\nStill in code block\n`````\nStill in code block",
        code_start => "````",
        test => <<EOT,
Fenced code block with fenced code block markers of different length in it:

````
In code block
```
Still in code block
`````
Still in code block
````

EOT
    },
    {
        code_all => "```\n[example]: http://example.com/\n\n[^1]: Footnote def\n\n*[HTML]: HyperText Markup Language\n```\n",
        code_content => "[example]: http://example.com/\n\n[^1]: Footnote def\n\n*[HTML]: HyperText Markup Language",
        code_start => "```",
        test => <<EOT,
Fenced code block with link definitions, footnote definition and
abbreviation definitions:

```
[example]: http://example.com/

[^1]: Footnote def

*[HTML]: HyperText Markup Language
```
EOT
    }
];

my $tests_inline =
[
    {
        code_all => "`bar`",
        code_content => "bar",
        code_start => "`",
        test => "foo `bar`",
    },
    {
        fail => 1,
        test => <<EOT,
```
<p>```
~~~
<p>```
```
EOT
    },
    {
        code_all => "`<test a=\"`",
        code_content => "<test a=\"",
        code_start => "`",
        test => "`<test a=\"` content of attribute `\">`",
    },
    {
        code_all => "`ticks`",
        code_content => "ticks",
        code_start => "`",
        test => "Fix for backticks within HTML tag: <span attr='`ticks`'>like this</span>",
    },
    {
        code_all => "`` `backticks` ``",
        code_content => " `backticks` ",
        code_start => "``",
        test => "Here's how you put `` `backticks` `` in a code span.",
    },
];

run_tests( $tests_line,
{
    debug => 1,
    re => $RE{Markdown}{CodeLine},
    type => 'Code Line',
});

run_tests( $tests_block,
{
    debug => 1,
    re => $RE{Markdown}{CodeBlock},
    type => 'Code Block',
});

run_tests( $tests_inline,
{
    debug => 1,
    re => $RE{Markdown}{CodeSpan},
    type => 'Code Span',
});

