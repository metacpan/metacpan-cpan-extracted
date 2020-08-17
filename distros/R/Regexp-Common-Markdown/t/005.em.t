#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

my $tests = 
[
    {
        em_all  => "*test **test*",
        em_text => "test **test",
        em_type => "*",
        test => "*test **test***",
    },
    {
        em_all  => "_test __test_",
        em_text => "test __test",
        em_type => "_",
        test => "_test __test__",
    },
    {
        em_all  => "__test_",
        em_text => "_test",
        em_type => "_",
        test => "*test __test__*",
    },
    {
        em_all  => "*__test__ test*",
        em_text => "__test__ test",
        em_type => "*",
        test => "*__test__ test*",
    },
    {
        em_all  => "**test*",
        em_text => "*test",
        em_type => "*",
        test => "_test **test**_",
    },
    {
        em_all  => "_**test** test_",
        em_text => "**test** test",
        em_type => "_",
        test => "_**test** test_",
    },
    {
        em_all  => "*test  **test*",
        em_text => "test  **test",
        em_type => "*",
        test => "*test  **test*  test**",
    },
    {
        em_all  => "_test  __test_",
        em_text => "test  __test",
        em_type => "_",
        test => "_test  __test_  test__",
    },
    {
        em_all  => "*test   *test*",
        em_text => "test   *test",
        em_type => "*",
        test => "*test   *test*  test*",
    },
    {
        em_all  => "_test   _test_",
        em_text => "test   _test",
        em_type => "_",
        test => "_test   _test_  test_",
    },
    {
        em_all  => "_**some text_",
        em_text => "**some text",
        em_type => "_",
        test => "_**some text_**",
    },
    {
        em_all  => "*__some text*",
        em_text => "__some text",
        em_type => "*",
        test => "*__some text*__",
    },
    {
        fail => 1,
        test => "test*  test  *test",
    },
    {
        fail => 1,
        test => "test_  test  _test",
    },
    {
        em_all  => "***This is strong and em.*",
        em_text => "**This is strong and em.",
        em_type => "*",
        test => "***This is strong and em.***",
    },
    {
        em_all  => "___This is strong and em._",
        em_text => "__This is strong and em.",
        em_type => "_",
        test => "___This is strong and em.___",
    },
    {
        em_all  => "***this*",
        em_text => "**this",
        em_type => "*",
        test => "So is ***this*** word.",
    },
    {
        em_all  => "___this_",
        em_text => "__this",
        em_type => "_",
        test => "So is ___this___ word.",
    }
];

run_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{Em},
    type => 'Emphasis',
});

