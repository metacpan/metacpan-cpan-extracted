#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

my $tests = 
[
    {
        em_all  => "*test test*",
        em_text => "test test",
        em_type => "*",
        test    => "*test test*",
    },
    {
        em_all  => "_test test_",
        em_text => "test test",
        em_type => "_",
        test    => "_test test_",
    },
    {
        fail => 1,
        test => "test*",
    },
    {
        em_all  => "*test*",
        em_text => "test",
        em_type => "*",
        test    => "test *test*",
    },
    {
        em_all  => "*test*",
        em_text => "test",
        em_type => "*",
        test    => "*test* test",
    },
    {
        fail => 1,
        test => "*test",
    },
    {
        fail => 1,
        test => "test_",
    },
    {
        em_all  => "_test_",
        em_text => "test",
        em_type => "_",
        test    => "test _test_",
    },
    {
        em_all  => "_test_",
        em_text => "test",
        em_type => "_",
        test    => "_test_ test",
    },
    {
        fail => 1,
        test => "_test",
    },
    {
        em_all  => "_test_",
        em_text => "test",
        em_type => "_",
        test    => "test _test_",
    },
    {
        em_all  => "_test_",
        em_text => "test",
        em_type => "_",
        test    => "_test_ test",
    },
    {
        em_all  => "*test*",
        em_text => "test",
        em_type => "*",
        test    => "test *test*",
    },
    {
        em_all  => "*test*",
        em_text => "test",
        em_type => "*",
        test    => "*test* test",
    },
    {
        em_all  => "*This is strong and em.*",
        em_text => "This is strong and em.",
        em_type => "*",
        test    => "*This is strong and em.*",
    },
    {
        em_all  => "*this*",
        em_text => "this",
        em_type => "*",
        test    => "*this*",
    },
    {
        em_all  => "_This is strong and em._",
        em_text => "This is strong and em.",
        em_type => "_",
        test    => "_This is strong and em._",
    },
    {
        em_all  => "_this_",
        em_text => "this",
        em_type => "_",
        test    => "_this_",
    },
    {
        em_all  => "*test test*",
        em_text => "test test",
        em_type => "*",
        test    => "*test test*",
    },
    {
        em_all  => "*__test__ test*",
        em_text => "__test__ test",
        em_type => "*",
        test    => "*__test__ test*",
    },
    {
        em_all  => "_**test** test_",
        em_text => "**test** test",
        em_type => "_",
        test    => "_**test** test_",
    },
    {
        em_all  => "*test   *test*",
        em_text => "test   *test",
        em_type => "*",
        test    => "*test   *test*  test*",
    },
    {
        em_all  => "_test   _test_",
        em_text => "test   _test",
        em_type => "_",
        test => "_test   _test_  test_",
    },
    {
        fail => 1,
        test => "test*  test  *test",
    },
    {
        fail => 1,
        test => "test_  test  _test",
    },
];

run_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{Em},
    type => 'Emphasis',
});

