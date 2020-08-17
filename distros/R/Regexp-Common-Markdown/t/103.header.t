#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

## https://regex101.com/r/GyzbR2/1/tests
my $tests = 
[
    {
        header_all => "### Header  {#id3 }\n",
        header_attr => "#id3 ",
        header_content => "Header",
        header_level => "###",
        test => qq{### Header  {#id3 }\n},
    },
    {
        header_all => "#### Header ##  { #id4 }\n",
        header_attr => "#id4 ",
        header_content => "Header ##",
        header_level => "####",
        test => qq{#### Header ##  { #id4 }\n},
    },
    {
        header_all => "### Header  {.cl }\n",
        header_attr => ".cl ",
        header_content => "Header",
        header_level => "###",
        test => qq{### Header  {.cl }\n},
    },
    {
        header_all => "### Header  {.cl .class }\n",
        header_attr => ".cl .class ",
        header_content => "Header",
        header_level => "###",
        test => qq{### Header  {.cl .class }\n},
    },
    {
        header_all => "### Header  {.cl.class#id7 }\n",
        header_attr => ".cl.class#id7 ",
        header_content => "Header",
        header_level => "###",
        test => qq{### Header  {.cl.class#id7 }\n},
    },
];

## https://regex101.com/r/berfAR/2
my $tests_line = 
[
    {
        header_all => "Header  {#id1}\n======\n",
        header_attr => "#id1",
        header_content => "Header  ",
        header_type => "======",
        test => <<EOT,
Header  {#id1}
======
EOT
    },
    {
        header_all => "Header  { #id2}\n------\n",
        header_attr => "#id2",
        header_content => "Header  ",
        header_type => "------",
        test => <<EOT,
Header  { #id2}
------
EOT
    },
    {
        header_all => "Header  {.cl}\n======\n",
        header_attr => ".cl",
        header_content => "Header  ",
        header_type => "======",
        test => <<EOT,
Header  {.cl}
======
EOT
    },
    {
        header_all => "Header  { .cl}\n------\n",
        header_attr => ".cl",
        header_content => "Header  ",
        header_type => "------",
        test => <<EOT,
Header  { .cl}
------
EOT
    },
    {
        header_all => "Header  {.cl.class}\n======\n",
        header_attr => ".cl.class",
        header_content => "Header  ",
        header_type => "======",
        test => <<EOT,
Header  {.cl.class}
======
EOT
    },
    {
        header_all => "Header  { .cl .class}\n------\n",
        header_attr => ".cl .class",
        header_content => "Header  ",
        header_type => "------",
        test => <<EOT,
Header  { .cl .class}
------
EOT
    },
    {
        header_all => "Header  {#id5.cl.class}\n======\n",
        header_attr => "#id5.cl.class",
        header_content => "Header  ",
        header_type => "======",
        test => <<EOT,
Header  {#id5.cl.class}
======
EOT
    },
    {
        header_all => "Header  { #id6 .cl .class}\n------\n",
        header_attr => "#id6 .cl .class",
        header_content => "Header  ",
        header_type => "------",
        test => <<EOT,
Header  { #id6 .cl .class}
------
EOT
    },
];

run_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{ExtHeader},
    type => 'Header extended',
});

run_tests( $tests_line,
{
    debug => 1,
    re => $RE{Markdown}{ExtHeaderLine},
    type => 'Header line extended',
});
