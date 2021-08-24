#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

## https://regex101.com/r/xetHV1/4
my $tests = 
[
    {
        img_all     => "![inline image](/img \"title\"){.class #inline-img}",
        img_alt     => "inline image",
        img_attr    => ".class #inline-img",
        img_title   => "title",
        img_title_container => "\"",
        img_url     => "/img ",
        test        => q{This is an ![inline image](/img "title"){.class #inline-img}.},
    },
    {
        img_all  => "![alt text](</url/>) {.class #inline-img}",
        img_alt  => "alt text",
        img_attr => ".class #inline-img",
        img_url  => "/url/",
        test        => q{![alt text](</url/>) {.class #inline-img}},
    },
];

run_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{ExtImage},
    type => 'Image extended',
});
