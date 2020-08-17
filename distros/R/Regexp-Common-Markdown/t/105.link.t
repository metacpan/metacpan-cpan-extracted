#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

## https://regex101.com/r/7mLssJ/2
my $tests = 
[
    {
        link_all             => "[inline link](/url \"title\"){.class #inline-link}",
        link_attr            => ".class #inline-link",
        link_name            => "inline link",
        link_title           => "title",
        link_title_container => "\"",
        link_url             => "/url",
        test => q{This is an [inline link](/url "title"){.class #inline-link}.},
    },
];

## https://regex101.com/r/hVfXCe/2/
my $tests_def =
[
    {
        link_all   => "[refid]: /path/to/something (Title) { .class #ref data-key=val }",
        link_attr  => ".class #ref data-key=val",
        link_id    => "refid",
        link_title => "Title",
        link_url   => "/path/to/something",
        test => q{[refid]: /path/to/something (Title) { .class #ref data-key=val }},
    },
];

run_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{ExtLink},
    type => 'Link extended',
});

run_tests( $tests_def,
{
    debug => 1,
    re => $RE{Markdown}{ExtLinkDefinition},
    type => 'Link definition extended',
});
