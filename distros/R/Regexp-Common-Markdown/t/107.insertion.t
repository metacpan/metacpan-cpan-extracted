#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

## https://regex101.com/r/4Z3h4F/1/
my $tests = 
[
    {
        ins_all         => "++10 euros++",
        ins_content     => "10 euros",
        test            => q{Tickets for the event are ~~5 euros~~ ++10 euros++},
    },
    {
        ins_all         => "++has a\n\nnew paragraph++",
        ins_content     => "has a\n\nnew paragraph",
        test            => <<EOT,
This ++has a

new paragraph++.
EOT
    },
    {
        fail => 1,
        test => q{++Not ok unless + is escaped++},
    },
    {
        ins_all         => "++Not ok unless \\+ is escaped++",
        ins_content     => "Not ok unless \\+ is escaped",
        test            => q{++Not ok unless \+ is escaped++},
    },
];

run_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{ExtInsertion},
    type => 'Insertion extended',
});
