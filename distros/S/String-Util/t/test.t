#!/usr/bin/perl -w
use strict;
use warnings;
use String::Util ':all';
use Test::More;

# general purpose variable
my $val;

#------------------------------------------------------------------------------
# crunch
#

# basic crunching
ok(collapse("  Starflower \n\n\t  Miko     ") eq 'Starflower Miko', 'Basic collapse');
# collapse on undef returns undef
ok(!defined collapse(undef), 'collapse undef should return undef');

#
# crunch
#------------------------------------------------------------------------------

is(crunchlines("x\n\n\nx"), "x\nx", "crunchlines with three \\ns");
is(crunchlines("x\nx")    , "x\nx", "crunchlines with one \\ns");
is(crunchlines(undef)     , undef , "crunchlines with undef");

#------------------------------------------------------------------------------
# hascontent
#
is(hascontent(undef), 0, "hascontent undef");

ok(!hascontent('')                               , "hascontent ''");
ok(!hascontent("   \t   \n\n  \r   \n\n\r     ") , "hascontent whitespace string");
ok(hascontent("0")                               , "hascontent zero");
ok(hascontent(" x ")                             , "hascontent string with x");

ok(nocontent("")     , "nocontent ''");
ok(nocontent(" ")    , "nocontent space");
ok(nocontent(undef)  , "nocontent undef");
ok(!nocontent('a')   , "nocontent char");
ok(!nocontent(' b ') , "nocontent char with spaces");
ok(!nocontent('word'), "nocontent word");

#
# hascontent
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# trim
#

# basic trimming
is(trim(undef)                 , undef      , 'trim undef');
is(trim("   Perl    ")         , "Perl"     , 'trim spaces');
is(trim("\t\tPerl\t\t")        , "Perl"     , 'trim tabs');
is(trim("\n\n\nPerl")          , "Perl"     , 'trim \n');
is(trim("\n\n\t\nPerl   \t\n") , "Perl"     , 'trim all three');

is(ltrim("\n\n\t\nPerl   "), "Perl   "  , 'ltrim');
is(ltrim(undef)            , undef, 'ltrim undef');
is(rtrim("\n\tPerl   ")    , "\n\tPerl" , 'rtrim');
is(rtrim(undef)            , undef, 'rtrim undef');

#
# trim
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# no_space
#

is(nospace("  ok \n fine     "), 'okfine', 'nospace with whitespace');
is(nospace("Perl")             , 'Perl'  , 'nospace no whitespace');
is(nospace(undef)              , undef   , 'nospace undef');

#
# no_space
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# startswith
$val = "Quick brown fox";

ok(startswith("Quick brown fox" , 'Q')     , "Startswidth char");
ok(startswith("Quick brown fox" , 'Quick') , "Startswidth word");
ok(!startswith("Quick brown fox", 'z')     , "Does NOT start with char");
ok(!startswith("Quick brown fox", 'Qqq')   , "Does NOT start with string");
is(startswith(undef, 'foo')     , undef    , "Startswidth undef");
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# endswith
$val = "Quick brown fox";

ok(endswith($val, 'x')    , "Endswith char");
ok(endswith($val, 'fox')  , "Endswith word");
ok(endswith($val, ' fox') , "Endswith space word");
ok(!endswith($val, 'foq') , "Does not end with string");
is(endswith(undef, 'foo'), undef    , "Endswith undef");
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# contains
$val = "Quick brown fox";
ok(contains($val, 'brown') , "Contains word");
ok(contains($val, 'uick')  , "Contains word 2");
ok(contains($val, 'n f')   , "Contains word with space");
ok(!contains($val, 'bri')  , "Does not contains word");
is(contains(undef, 'foo')  , undef    , "Contains undef");
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# htmlesc
#

# basic operation of htmlesc
is(htmlesc('<>"&') , '&lt;&gt;&quot;&amp;' , 'htmlesc special chars');
is(htmlesc(undef)  , ''                    , 'htmlesc undef');

#
# htmlesc
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# cellfill
#

# space-only string
#is(cellfill('  '), '&nbsp;', 'cellfill spaces');
# undef string
#is(cellfill(undef), '&nbsp;', 'cellfill undef');
# string with content
#is(cellfill('x'), 'x', 'cellfill undef');

#
# cellfill
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# eqq, neqq
#
ok(eqq('a'   , 'a')     , 'eqq same');
ok(eqq(undef , undef)   , 'eqq undef');
ok(!eqq('a'  , 'b')     , 'eqq diff');
ok(!eqq('a'  , undef)   , 'eqq a and undef');

ok(!neqq('a'   , 'a')     , 'neqq same');
ok(!neqq(undef , undef)   , 'neqq undef');
ok(neqq('a'    , 'b')     , 'neqq diff');
ok(neqq('a'    , undef)   , 'neqq a and undef');

#
# eq_undef, neqq
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# define
#

# define an undef
#is(define(undef), '', 'define undef');
# define an already defined value
#is(define('x'), 'x', 'define string');

#
# define
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# unquote
#

# single quotes
is(unquote("'Starflower'")     , 'Starflower'      , 'unquote single quotes');
# double quotes
is(unquote('"Starflower"')     , 'Starflower'      , 'unquote double quotes');
# no quotes
is(unquote('Starflower')       , 'Starflower'      , 'unquote no quotes');
# Quote in middle
is(unquote("Don't lets start") , "Don't lets start", 'unquote with quote in middle');

#
# unquote
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# jsquote
#

is(jsquote("'yeah\n</script>'"), q|'\'yeah\n<' + '/script>\''|, 'jsquote');

#
# jsquote
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# fullchomp
#

# scalar context
#is(fullchomp("Starflower\n\r\r\r\n"), 'Starflower', 'fullchomp');

#
# fullchomp
#------------------------------------------------------------------------------

is(sanitize("http://www.google.com/"), 'http_www_google_com', 'Sanitize URL');
is(sanitize("foo_bar()")             , 'foo_bar'            , 'Sanitize function name');
is(sanitize("/path/to/file.txt")     , 'path_to_file_txt'   , 'Sanitize path');

is(sanitize("Hello there!!!", '.')   , 'Hello.there'        , 'Sanitize with a custom separator');

#
# randword
#------------------------------------------------------------------------------

# file_get_contents()
$val    = file_get_contents(__FILE__);
my @arr = file_get_contents(__FILE__, 1);

ok(length($val) > 100, "file_get_contents string");
ok(@arr > 10         , "file_get_contents array");

done_testing();
