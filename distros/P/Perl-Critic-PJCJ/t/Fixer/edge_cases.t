#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0 qw( done_testing subtest );

use lib             qw( lib t/lib );
use ViolationFinder qw( fixes unchanged );

subtest "Unparsable and empty sources pass through" => sub {
  unchanged "",   "empty source is returned as is";
  unchanged "\0", "unparsable source is returned as is";
};

subtest "Line endings are preserved in accepted source" => sub {
  unchanged qq(my \$x = 1;\r\n), "clean CRLF source is byte-identical";
  unchanged "my \@w = qw/( [ < { \\\\/;\r\n",
    "CRLF source whose only fix is declined is byte-identical";
};

subtest "Line endings are preserved in fixed source" => sub {
  fixes qq(my \$x = 'hello';\r\n), qq(my \$x = "hello";\r\n),
    "a fixed CRLF file keeps CRLF endings";
  fixes qq(my \$a = 'one';\r\nmy \$b = 'two';\r\n),
    qq(my \$a = "one";\r\nmy \$b = "two";\r\n),
    "every line keeps CRLF when any line is fixed";
  fixes qq(my \$x = 'a';\nmy \$y = 'b';\r\n),
    qq(my \$x = "a";\nmy \$y = "b";\n),
    "mixed endings are normalised to LF when a fix applies";
};

subtest "Delimiters are escaped when no clean delimiter exists" => sub {
  fixes 'my @w = qw/) ( ] > }/;', 'my @w = qw[) ( \] > }];',
    "unbalanced content is escaped for the best delimiter";
};

subtest "Unsafe fixes are declined" => sub {
  unchanged 'my @w = qw/( [ < { \\\\/;',
    "content with a backslash and every delimiter is left alone";
  unchanged "use Foo 'a b';",
    "an import name containing a space cannot become a qw word";
};

subtest "Fallback re-delimiting inside use statements" => sub {
  fixes 'use Foo qw[ a ], "b$x";', 'use Foo qw( a ), "b$x";',
    "interpolating argument restricts the fix to the qw token";
  fixes 'use Foo qw[ a ], qw{ b }, $v;', 'use Foo qw( a ), qw( b ), $v;',
    "every qw token is re-delimited when a full rewrite is unsafe";
  unchanged 'use Foo qw[ a\( ], $v;',
    "a qw token whose re-delimiting is unsafe is left alone";
};

subtest "Unterminated quote tokens pass through" => sub {
  unchanged 'my $x = \'ab',      "unterminated single quote keeps b";
  unchanged 'my @w = qw( a b',   "unterminated qw keeps b";
  unchanged 'my $t = qq(ab',     "unterminated qq keeps b";
  unchanged "use Foo 'a', 'bcd", "unterminated use argument keeps d";
};

subtest "Whitespace oddities" => sub {
  fixes "use Foo 'a' ;", "use Foo qw( a ) ;",
    "trailing whitespace before the semicolon survives";
};

done_testing
