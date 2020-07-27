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
is(trim(undef)                 , ""         , 'trim undef');
is(trim("   Perl    ")         , "Perl"     , 'trim spaces');
is(trim("\t\tPerl\t\t")        , "Perl"     , 'trim tabs');
is(trim("\n\n\nPerl")          , "Perl"     , 'trim \n');
is(trim("\n\n\t\nPerl   \t\n") , "Perl"     , 'trim all three');

is(ltrim("\n\n\t\nPerl   ")    , "Perl   "  , 'ltrim');
is(rtrim("\n\tPerl   ")        , "\n\tPerl" , 'rtrim');

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

ok(startswith("Quick brown fox", 'Q')     , "Startswidth char");
ok(startswith("Quick brown fox", 'Quick') , "Startswidth word");
ok(!startswith("Quick brown fox", 'z')    , "Does NOT start with char");
ok(!startswith("Quick brown fox", 'Qqq')  , "Does NOT start with string");
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# endswith
$val = "Quick brown fox";

ok(endswith($val, 'x')    , "Endswidth char");
ok(endswith($val, 'fox')  , "Endswidth word");
ok(endswith($val, ' fox') , "Endswidth space word");
ok(!endswith($val, 'foq') , "Does not end width string");
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# contains
$val = "Quick brown fox";
ok(contains($val, 'brown') , "Contains word");
ok(contains($val, 'uick')  , "Contains word 2");
ok(contains($val, 'n f')   , "Contains word with space");
ok(!contains($val, 'bri')  , "Does not contains word");
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
# eq_undef, neundef
#
ok(equndef('a'   , 'a')     , 'equndef same');
ok(equndef(undef , undef)   , 'equndef undef');
ok(!equndef('a'  , 'b')     , 'equndef diff');
ok(!equndef('a'  , undef)   , 'equndef a and undef');

ok(!neundef('a'   , 'a')     , 'nequndef same');
ok(!neundef(undef , undef)   , 'nequndef undef');
ok(neundef('a'    , 'b')     , 'nequndef diff');
ok(neundef('a'    , undef)   , 'nequndef a and undef');

#
# eq_undef, neundef
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

#------------------------------------------------------------------------------
# randword
# Not sure how to test this besides making sure it actually runs.
#

$val = randword(20);
ok(defined($val) && (length($val) == 20), 'randword');

#
# randword
#------------------------------------------------------------------------------

# file_get_contents()
$val    = file_get_contents(__FILE__);
my @arr = file_get_contents(__FILE__, 1);

ok(length($val) > 100, "file_get_contents string");
ok(@arr > 10         , "file_get_contents array");

done_testing();
