#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

## https://regex101.com/r/Jp2Kos/2/tests

my $tests = 
[
    {
        bold_all  => "***test test***",
        bold_text => "*test test*",
        bold_type => "**",
        test => "***test test***",
    },

    {
        bold_all  => "___test test___",
        bold_text => "_test test_",
        bold_type => "__",
        test => "___test test___",
    },

    {
        bold_all => "**test***",
        bold_text => "test*",
        bold_type => "**",
        test => "*test **test***",
    },

    {
        bold_all  => "**test *test***",
        bold_text => "test *test*",
        bold_type => "**",
        test => "**test *test***",
    },

    {
        bold_all  => "***test* test**",
        bold_text => "*test* test",
        bold_type => "**",
        test => "***test* test**",
    },

    {
        bold_all => "***test**",
        bold_text => "*test",
        bold_type => "**",
        test => "***test** test*",
    },

    {
        bold_all => "__test___",
        bold_text => "test_",
        bold_type => "__",
        test => "_test __test___",
    },

    {
        bold_all  => "__test _test___",
        bold_text => "test _test_",
        bold_type => "__",
        test => "__test _test___",
    },

    {
        bold_all  => "___test_ test__",
        bold_text => "_test_ test",
        bold_type => "__",
        test => "___test_ test__",
    },

    {
        bold_all => "___test__",
        bold_text => "_test",
        bold_type => "__",
        test => "___test__ test_",
    },

    {
        bold_all  => "**test _test_**",
        bold_text => "test _test_",
        bold_type => "**",
        test => "**test _test_**",
    },

    {
        bold_all  => "**_test_ test**",
        bold_text => "_test_ test",
        bold_type => "**",
        test => "**_test_ test**",
    },

    {
        bold_all => "**test**",
        bold_text => "test",
        bold_type => "**",
        test => "_test **test**_",
    },

    {
        bold_all  => "__test *test*__",
        bold_text => "test *test*",
        bold_type => "__",
        test => "__test *test*__",
    },

    {
        bold_all  => "__*test* test__",
        bold_text => "*test* test",
        bold_type => "__",
        test => "__*test* test__",
    },

    {
        bold_all => "**test**",
        bold_text => "test",
        bold_type => "**",
        test => "_**test** test_",
    },

    {
        bold_all  => "**test*  test**",
        bold_text => "test*  test",
        bold_type => "**",
        test => "*test  **test*  test**",
    },

    {
        bold_all  => "__test_  test__",
        bold_text => "test_  test",
        bold_type => "__",
        test => "_test  __test_  test__",
    },

    {
        bold_all  => "**test  *test**",
        bold_text => "test  *test",
        bold_type => "**",
        test => "**test  *test** test*",
    },

    {
        bold_all  => "__test  _test__",
        bold_text => "test  _test",
        bold_type => "__",
        test => "__test  _test__ test_",
    },

    {
        bold_all  => "**test **test**",
        bold_text => "test **test",
        bold_type => "**",
        test => "**test **test** test**",
    },

    {
        bold_all  => "__test __test__",
        bold_text => "test __test",
        bold_type => "__",
        test => "__test __test__ test__",
    },

    {
        bold_all  => "**some text_**",
        bold_text => "some text_",
        bold_type => "**",
        test => "_**some text_**",
    },

    {
        bold_all  => "__some text*__",
        bold_text => "some text*",
        bold_type => "__",
        test => "*__some text*__",
    },

    {
        bold_all  => "**_some text**",
        bold_text => "_some text",
        bold_type => "**",
        test => "**_some text**_",
    },

    {
        bold_all => "**a**",
        bold_text => "a",
        bold_type => "**",
        test => "**a**b",
    },

    {
        bold_all => "**b**",
        bold_text => "b",
        bold_type => "**",
        test => "a**b**",
    },

    {
        bold_all => "**b**",
        bold_text => "b",
        bold_type => "**",
        test => "a**b**c",
    },

    {
        bold_all => "__a__",
        bold_text => "a",
        bold_type => "__",
        test => "__a__b",
    },

    {
        bold_all => "__b__",
        bold_text => "b",
        bold_type => "__",
        test => "a__b__",
    },

    {
        bold_all => "__b__",
        bold_text => "b",
        bold_type => "__",
        test => "a__b__c",
    },

    {
        bold_all  => "***This is strong and em.***",
        bold_text => "*This is strong and em.*",
        bold_type => "**",
        test => "***This is strong and em.***",
    },

    {
        bold_all => "***this***",
        bold_text => "*this*",
        bold_type => "**",
        test => "So is ***this*** word.",
    },

    {
        bold_all  => "___This is strong and em.___",
        bold_text => "_This is strong and em._",
        bold_type => "__",
        test => "___This is strong and em.___",
    },

    {
        bold_all => "___this___",
        bold_text => "_this_",
        bold_type => "__",
        test => "So is ___this___ word.",
    },

    {
        bold_all => "**. **Test**",
        bold_text => ". **Test",
        bold_type => "**",
        test => "E**. **Test** TestTestTest",
    },

    {
        bold_all => "____________",
        bold_text => "________",
        bold_type => "__",
        test => "Name: ____________",
    },

    {
        bold_all => "_____",
        bold_text => "_",
        bold_type => "__",
        test => "_____Cut here_____",
    },

    {
    bold_all  => "____Cut here____",
    bold_text => "__Cut here__",
    bold_type => "__",
    test => "____Cut here____",
    },

    ## Fail
    {
    fail => 1,
    test => "test** test **test",
    },
    
    {
    fail => 1,
    test => "test__ test __test",
    },
    
    {
    fail => 1,
    test => "Organisation: ____",
    },
];

run_tests( $tests,
{
    type => 'Bold',
    re => $RE{Markdown}{Bold},
});
