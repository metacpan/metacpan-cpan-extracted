#!perl

use Test::More 0.98;
use PERLANCAR::ShellQuote::Any;

{
    local $^O = "MSWin32";
    is(shell_quote("foo bar", '"baz"', "qux"), q["foo bar" "\\"baz\\"" "qux"]);
}

{
    local $^O = "linux";
    is(shell_quote("foo bar", '"baz"', "qux"), q['foo bar' '"baz"' qux]);
}

done_testing;
