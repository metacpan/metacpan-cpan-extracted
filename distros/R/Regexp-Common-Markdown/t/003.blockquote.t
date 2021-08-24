#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

## https://regex101.com/r/TdKq0K/1

my $tests = 
[
    {
        bquote_all      => "> foo\n>\n> > bar\n>\n> foo\n",
        bquote_other    => "> foo\n",
        test            => <<EOT,
> foo
>
> > bar
>
> foo
EOT
    },

    {
        bquote_all      => "> A list within a blockquote:\n> \n> *\tasterisk 1\n> *\tasterisk 2\n> *\tasterisk 3\n",
        bquote_other    => "> *\tasterisk 3\n",
        test            => <<EOT,
> A list within a blockquote:
> 
> *	asterisk 1
> *	asterisk 2
> *	asterisk 3
EOT
    },
    
    {
        bquote_all  => "> Blockquoted: <http://example.com/>\n\n",
        test        => <<EOT,

> Blockquoted: <http://example.com/>

EOT
    },
];

run_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{Blockquote},
    type => 'Blockquote',
});

