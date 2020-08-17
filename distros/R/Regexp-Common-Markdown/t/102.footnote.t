#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

## https://regex101.com/r/WuB1FR/2/tests
my $tests = 
[
    {
        footnote_all => "[^first]:  This is the first note.",
        footnote_id => "first",
        footnote_text => "This is the first note.",
        test => q{[^first]:  This is the first note.},
    },
    {
        footnote_all => "[^2]: Content for sixth footnote spaning on \n    three lines, with some span-level markup like\n    _emphasis_, a [link][].\n",
        footnote_id => 2,
        footnote_text => "Content for sixth footnote spaning on \n    three lines, with some span-level markup like\n    _emphasis_, a [link][].\n",
        test => <<EOT,
[^2]: Content for sixth footnote spaning on 
    three lines, with some span-level markup like
    _emphasis_, a [link][].
EOT
    },
    {
        footnote_all => "[^fn-name]:\n    Footnote beginning on the line next to the marker.\n",
        footnote_id => "fn-name",
        footnote_text => "    Footnote beginning on the line next to the marker.\n",
        test => <<EOT,
[^fn-name]:
    Footnote beginning on the line next to the marker.
EOT
    },
    {
        footnote_all => "[^block]:\n\tParagraph.\n\t\n\t*   List item\n\t\n\t> Blockquote\n\t\n\t    Code block\n",
        footnote_id => "block",
        footnote_text => "\tParagraph.\n\t\n\t*   List item\n\t\n\t> Blockquote\n\t\n\t    Code block\n",
        test => <<EOT,
[^block]:
	Paragraph.
	
	*   List item
	
	> Blockquote
	
	    Code block
EOT
    },
    {
        footnote_all => "[^1\$^!\"']: Haha!",
        footnote_id => "1\$^!\"'",
        footnote_text => "Haha!",
        test => q{[^1$^!"']: Haha!},
    },
];

## https://regex101.com/r/3eO7rJ/1/
my $tests_ref =
[
    {
        footnote_all => "[^1]",
        footnote_id => 1,
        test => q{Some paragraph with a footnote[^1]},
    },
    {
        footnote_all => "[^1\$^!\"']",
        footnote_id => "1\$^!\"'",
        test => q{Testing unusual footnote name[^1$^!"']},
    },
    {
        footnote_all => "[^jack](Co-founder of Angels, Inc)",
        footnote_id => "jack",
        footnote_text => "Co-founder of Angels, Inc",
        test => q{I met Jack [^jack](Co-founder of Angels, Inc) at the meet-up.},
    },
    {
        footnote_all => "[^](Co-founder of Angels, Inc)",
        footnote_id => "",
        footnote_text => "Co-founder of Angels, Inc",
        test => q{I met Jack [^](Co-founder of Angels, Inc) at the meet-up.},
    },
    {
        footnote_all => "^[Inlines notes are easier to write, since \nyou don't have to pick an identifier and move down to type the\nnote.]",
        footnote_text => "Inlines notes are easier to write, since \nyou don't have to pick an identifier and move down to type the\nnote.",
        test => <<EOT,
Here is an inline note.^[Inlines notes are easier to write, since 
you don't have to pick an identifier and move down to type the
note.]
EOT
    },
];

run_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{ExtFootnote},
    type => 'Footnote',
});

run_tests( $tests_ref,
{
    debug => 1,
    re => $RE{Markdown}{ExtFootnoteReference},
    type => 'Footnote reference',
});
