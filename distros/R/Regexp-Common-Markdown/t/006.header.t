#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

my $tests = 
[
    {
        header_all => "# Header 1\n",
        header_content => "Header 1",
        header_level => "#",
        test => "# Header 1\n",
    },
    {
        header_all => "# Header 2 #\n",
        header_content => "Header 2",
        header_level => "#",
        test => "# Header 2 #\n",
    },
    {
        header_all => "###### Header 6 ######\n",
        header_content => "Header 6",
        header_level => "######",
        test => "###### Header 6 ######\n",
    },
    {
        header_all => "## Header 2\n",
        header_content => "Header 2",
        header_level => "##",
        test => "## Header 2\n",
    },
    {
        header_all => "### Header 3\n",
        header_content => "Header 3",
        header_level => "###",
        test => "### Header 3\n",
    },
    {
        header_all => "#### Header 4\n",
        header_content => "Header 4",
        header_level => "####",
        test => "#### Header 4\n",
    },
    {
        header_all => "##### Header 5\n",
        header_content => "Header 5",
        header_level => "#####",
        test => "##### Header 5\n",
    },
    {
        header_all => "###### Header 6\n",
        header_content => "Header 6",
        header_level => "######",
        test => "###### Header 6\n",
    },
    {
        header_all => "### Header\n",
        header_content => "Header",
        header_level => "###",
        test => <<EOT,
### Header
Paragraph
EOT
    },
    {
        header_all => "### Header\n",
        header_content => "Header",
        header_level => "###",
        test => <<EOT,
Paragraph
### Header
Paragraph
EOT
    },
];

my $tests_line =
[
    {
        header_all => "Header\n======\n",
        header_content => "Header",
        header_type => "======",
        test => <<EOT,
Paragraph
Header
======
Paragraph
EOT
    },
    {
        header_all => "Header\n------\n",
        header_content => "Header",
        header_type => "------",
        test => <<EOT,
Paragraph
Header
------
Paragraph
EOT
    },
    {
        header_all => "Header\n======\n",
        header_content => "Header",
        header_type => "======",
        test => <<EOT,
Header
======
EOT
    },
    {
        header_all => "Header\n------\n",
        header_content => "Header",
        header_type => "------",
        test => <<EOT,
Header
------
EOT
    },
];

run_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{Header},
    type => 'Header',
});

run_tests( $tests_line,
{
    debug => 1,
    re => $RE{Markdown}{HeaderLine},
    type => 'Header Line',
});

