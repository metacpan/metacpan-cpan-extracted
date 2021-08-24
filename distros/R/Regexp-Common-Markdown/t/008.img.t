#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

## https://regex101.com/r/z0yH2F/10
my $tests = 
[
    {
        img_all  => "![Alt text](/path/to/img.jpg)",
        img_alt  => "Alt text",
        img_url  => "/path/to/img.jpg",
        test     => q{![Alt text](/path/to/img.jpg)},
    },
    {
        img_all     => "![Alt text](/path/to/img.jpg \"Optional title\")",
        img_alt     => "Alt text",
        img_title   => "Optional title",
        img_title_container => "\"",
        img_url     => "/path/to/img.jpg ",
        test        => q{![Alt text](/path/to/img.jpg "Optional title")},
    },
    {
        img_all  => "![alt text](/url/)",
        img_alt  => "alt text",
        img_url  => "/url/",
        test => q{Inline within a paragraph: ![alt text](/url/).},
    },
    {
        img_all     => "![alt text](/url/  \"title preceded by two spaces\")",
        img_alt     => "alt text",
        img_title   => "title preceded by two spaces",
        img_title_container => "\"",
        img_url     => "/url/  ",
        test        => q{![alt text](/url/  "title preceded by two spaces")},
    },
    {
        img_all     => "![alt text](/url/  \"title has spaces afterward\"  )",
        img_alt     => "alt text",
        img_title   => "title has spaces afterward",
        img_title_container => "\"",
        img_url     => "/url/  ",
        test        => q{![alt text](/url/  "title has spaces afterward"  )},
    },
    {
        img_all  => "![alt text](</url/>)",
        img_alt  => "alt text",
        img_url  => "/url/",
        test     => q{![alt text](</url/>)},
    },
    {
        img_all     => "![alt text](</url/> \"with a title\")",
        img_alt     => "alt text",
        img_title   => "with a title",
        img_title_container => "\"",
        img_url     => "/url/",
        test        => q{![alt text](</url/> "with a title").},
    },
    {
        img_all  => "![Empty]()",
        img_alt  => "Empty",
        img_url  => "",
        test     => q{![Empty]()},
    },
    {
        img_all  => "![this is a stupid URL](http://example.com/(parens).jpg)",
        img_alt  => "this is a stupid URL",
        img_url  => "http://example.com/(parens).jpg",
        name     => q{Parenthesis in url},
        test     => q{![this is a stupid URL](http://example.com/(parens).jpg)},
    },
    {
        img_all  => "![this is a stupid URL](http://example.com/ (parens).jpg)",
        img_alt  => "this is a stupid URL",
        img_url  => "http://example.com/ (parens).jpg",
        name     => q{Space in url},
        test     => q{![this is a stupid URL](http://example.com/ (parens).jpg)},
    },
    {
        img_all => "![alt text][foo]",
        img_alt => "alt text",
        img_id  => "foo",
        test    => q{![alt text][foo]},
    },
];

run_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{Image},
    type => 'Image',
});


