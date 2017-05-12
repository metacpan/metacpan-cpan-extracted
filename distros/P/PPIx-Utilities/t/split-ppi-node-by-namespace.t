#!/usr/bin/env perl

use 5.006001;

use strict;
use warnings;

our $VERSION = '1.001000';


use Readonly;


use Data::Dumper qw< >;
use PPI::Document qw< >;
use PPI::Dumper qw< >;
use PPIx::Utilities::Node qw< split_ppi_node_by_namespace >;


use Test::Deep qw< cmp_deeply >;
use Test::More tests => 10;


Readonly::Scalar my $DUMP_INDENT => 4;


{
    my $source = <<'END_SOURCE';
package Foo;
$x = 1;
while (1) { $y = 2 }
until (1) { $z = 3 }
if (1) { $w = 4 }
unless (1) { $v = 5 }
for (1) { $u = 6 }
foreach (1) { $t = 7 }
given (1) { $s = 8 }
when (1) { $r = 9 }
END_SOURCE

    my %expected = (
        Foo => [ <<'END_EXPECTED' ],
                    PPI::Document
                        PPI::Statement::Package
[    1,   1,   1 ]         PPI::Token::Word     'package'
[    1,   8,   8 ]         PPI::Token::Whitespace   ' '
[    1,   9,   9 ]         PPI::Token::Word     'Foo'
[    1,  12,  12 ]         PPI::Token::Structure    ';'
[    1,  13,  13 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement
[    2,   1,   1 ]         PPI::Token::Symbol   '$x'
[    2,   3,   3 ]         PPI::Token::Whitespace   ' '
[    2,   4,   4 ]         PPI::Token::Operator     '='
[    2,   5,   5 ]         PPI::Token::Whitespace   ' '
[    2,   6,   6 ]         PPI::Token::Number   '1'
[    2,   7,   7 ]         PPI::Token::Structure    ';'
[    2,   8,   8 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement::Compound
[    3,   1,   1 ]         PPI::Token::Word     'while'
[    3,   6,   6 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::Condition   ( ... )
                                PPI::Statement::Expression
[    3,   8,   8 ]                 PPI::Token::Number   '1'
[    3,  10,  10 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::Block   { ... }
[    3,  12,  12 ]             PPI::Token::Whitespace   ' '
                                PPI::Statement
[    3,  13,  13 ]                 PPI::Token::Symbol   '$y'
[    3,  15,  15 ]                 PPI::Token::Whitespace   ' '
[    3,  16,  16 ]                 PPI::Token::Operator     '='
[    3,  17,  17 ]                 PPI::Token::Whitespace   ' '
[    3,  18,  18 ]                 PPI::Token::Number   '2'
[    3,  19,  19 ]             PPI::Token::Whitespace   ' '
[    3,  21,  21 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement::Compound
[    4,   1,   1 ]         PPI::Token::Word     'until'
[    4,   6,   6 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::Condition   ( ... )
                                PPI::Statement::Expression
[    4,   8,   8 ]                 PPI::Token::Number   '1'
[    4,  10,  10 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::Block   { ... }
[    4,  12,  12 ]             PPI::Token::Whitespace   ' '
                                PPI::Statement
[    4,  13,  13 ]                 PPI::Token::Symbol   '$z'
[    4,  15,  15 ]                 PPI::Token::Whitespace   ' '
[    4,  16,  16 ]                 PPI::Token::Operator     '='
[    4,  17,  17 ]                 PPI::Token::Whitespace   ' '
[    4,  18,  18 ]                 PPI::Token::Number   '3'
[    4,  19,  19 ]             PPI::Token::Whitespace   ' '
[    4,  21,  21 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement::Compound
[    5,   1,   1 ]         PPI::Token::Word     'if'
[    5,   3,   3 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::Condition   ( ... )
                                PPI::Statement::Expression
[    5,   5,   5 ]                 PPI::Token::Number   '1'
[    5,   7,   7 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::Block   { ... }
[    5,   9,   9 ]             PPI::Token::Whitespace   ' '
                                PPI::Statement
[    5,  10,  10 ]                 PPI::Token::Symbol   '$w'
[    5,  12,  12 ]                 PPI::Token::Whitespace   ' '
[    5,  13,  13 ]                 PPI::Token::Operator     '='
[    5,  14,  14 ]                 PPI::Token::Whitespace   ' '
[    5,  15,  15 ]                 PPI::Token::Number   '4'
[    5,  16,  16 ]             PPI::Token::Whitespace   ' '
[    5,  18,  18 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement::Compound
[    6,   1,   1 ]         PPI::Token::Word     'unless'
[    6,   7,   7 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::Condition   ( ... )
                                PPI::Statement::Expression
[    6,   9,   9 ]                 PPI::Token::Number   '1'
[    6,  11,  11 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::Block   { ... }
[    6,  13,  13 ]             PPI::Token::Whitespace   ' '
                                PPI::Statement
[    6,  14,  14 ]                 PPI::Token::Symbol   '$v'
[    6,  16,  16 ]                 PPI::Token::Whitespace   ' '
[    6,  17,  17 ]                 PPI::Token::Operator     '='
[    6,  18,  18 ]                 PPI::Token::Whitespace   ' '
[    6,  19,  19 ]                 PPI::Token::Number   '5'
[    6,  20,  20 ]             PPI::Token::Whitespace   ' '
[    6,  22,  22 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement::Compound
[    7,   1,   1 ]         PPI::Token::Word     'for'
[    7,   4,   4 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::List    ( ... )
                                PPI::Statement
[    7,   6,   6 ]                 PPI::Token::Number   '1'
[    7,   8,   8 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::Block   { ... }
[    7,  10,  10 ]             PPI::Token::Whitespace   ' '
                                PPI::Statement
[    7,  11,  11 ]                 PPI::Token::Symbol   '$u'
[    7,  13,  13 ]                 PPI::Token::Whitespace   ' '
[    7,  14,  14 ]                 PPI::Token::Operator     '='
[    7,  15,  15 ]                 PPI::Token::Whitespace   ' '
[    7,  16,  16 ]                 PPI::Token::Number   '6'
[    7,  17,  17 ]             PPI::Token::Whitespace   ' '
[    7,  19,  19 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement::Compound
[    8,   1,   1 ]         PPI::Token::Word     'foreach'
[    8,   8,   8 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::List    ( ... )
                                PPI::Statement
[    8,  10,  10 ]                 PPI::Token::Number   '1'
[    8,  12,  12 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::Block   { ... }
[    8,  14,  14 ]             PPI::Token::Whitespace   ' '
                                PPI::Statement
[    8,  15,  15 ]                 PPI::Token::Symbol   '$t'
[    8,  17,  17 ]                 PPI::Token::Whitespace   ' '
[    8,  18,  18 ]                 PPI::Token::Operator     '='
[    8,  19,  19 ]                 PPI::Token::Whitespace   ' '
[    8,  20,  20 ]                 PPI::Token::Number   '7'
[    8,  21,  21 ]             PPI::Token::Whitespace   ' '
[    8,  23,  23 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement::Given
[    9,   1,   1 ]         PPI::Token::Word     'given'
[    9,   6,   6 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::Given   ( ... )
                                PPI::Statement::Expression
[    9,   8,   8 ]                 PPI::Token::Number   '1'
[    9,  10,  10 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::Block   { ... }
[    9,  12,  12 ]             PPI::Token::Whitespace   ' '
                                PPI::Statement
[    9,  13,  13 ]                 PPI::Token::Symbol   '$s'
[    9,  15,  15 ]                 PPI::Token::Whitespace   ' '
[    9,  16,  16 ]                 PPI::Token::Operator     '='
[    9,  17,  17 ]                 PPI::Token::Whitespace   ' '
[    9,  18,  18 ]                 PPI::Token::Number   '8'
[    9,  19,  19 ]             PPI::Token::Whitespace   ' '
[    9,  21,  21 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement::When
[   10,   1,   1 ]         PPI::Token::Word     'when'
[   10,   5,   5 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::When    ( ... )
                                PPI::Statement::Expression
[   10,   7,   7 ]                 PPI::Token::Number   '1'
[   10,   9,   9 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::Block   { ... }
[   10,  11,  11 ]             PPI::Token::Whitespace   ' '
                                PPI::Statement
[   10,  12,  12 ]                 PPI::Token::Symbol   '$r'
[   10,  14,  14 ]                 PPI::Token::Whitespace   ' '
[   10,  15,  15 ]                 PPI::Token::Operator     '='
[   10,  16,  16 ]                 PPI::Token::Whitespace   ' '
[   10,  17,  17 ]                 PPI::Token::Number   '9'
[   10,  18,  18 ]             PPI::Token::Whitespace   ' '
[   10,  20,  20 ]     PPI::Token::Whitespace   '\n'
END_EXPECTED
    );

    _test($source, \%expected, 'Single namespace.');
} # end scope block


{
    my $source = <<'END_SOURCE';
$x = 1;
END_SOURCE

    my %expected = (
        main => [ <<'END_EXPECTED' ],
                    PPI::Document
                        PPI::Statement
[    1,   1,   1 ]         PPI::Token::Symbol   '$x'
[    1,   3,   3 ]         PPI::Token::Whitespace   ' '
[    1,   4,   4 ]         PPI::Token::Operator     '='
[    1,   5,   5 ]         PPI::Token::Whitespace   ' '
[    1,   6,   6 ]         PPI::Token::Number   '1'
[    1,   7,   7 ]         PPI::Token::Structure    ';'
[    1,   8,   8 ]     PPI::Token::Whitespace   '\n'
END_EXPECTED
    );

    _test($source, \%expected, 'Default namespace.');
} # end scope block


{
    my $source = <<'END_SOURCE';
$x = 1;

package Foo;

$y = 2;
END_SOURCE

    my %expected = (
        main => [ <<'END_EXPECTED_MAIN' ],
                    PPI::Document::Fragment
                        PPI::Statement
[    1,   1,   1 ]         PPI::Token::Symbol   '$x'
[    1,   3,   3 ]         PPI::Token::Whitespace   ' '
[    1,   4,   4 ]         PPI::Token::Operator     '='
[    1,   5,   5 ]         PPI::Token::Whitespace   ' '
[    1,   6,   6 ]         PPI::Token::Number   '1'
[    1,   7,   7 ]         PPI::Token::Structure    ';'
[    1,   8,   8 ]     PPI::Token::Whitespace   '\n'
[    2,   1,   1 ]     PPI::Token::Whitespace   '\n'
END_EXPECTED_MAIN

        Foo => [ <<'END_EXPECTED_FOO' ],
                    PPI::Document::Fragment
                        PPI::Statement::Package
[    3,   1,   1 ]         PPI::Token::Word     'package'
[    3,   8,   8 ]         PPI::Token::Whitespace   ' '
[    3,   9,   9 ]         PPI::Token::Word     'Foo'
[    3,  12,  12 ]         PPI::Token::Structure    ';'
[    3,  13,  13 ]     PPI::Token::Whitespace   '\n'
[    4,   1,   1 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement
[    5,   1,   1 ]         PPI::Token::Symbol   '$y'
[    5,   3,   3 ]         PPI::Token::Whitespace   ' '
[    5,   4,   4 ]         PPI::Token::Operator     '='
[    5,   5,   5 ]         PPI::Token::Whitespace   ' '
[    5,   6,   6 ]         PPI::Token::Number   '2'
[    5,   7,   7 ]         PPI::Token::Structure    ';'
[    5,   8,   8 ]     PPI::Token::Whitespace   '\n'
END_EXPECTED_FOO
    );

    _test($source, \%expected, 'Simple multiple namespaces: default followed by non-default.');
} # end scope block


{
    my $source = <<'END_SOURCE';
package Foo;
$x = 1;

package main;

$y = 2;
END_SOURCE

    my %expected = (
        main => [ <<'END_EXPECTED_MAIN' ],
                    PPI::Document::Fragment
                        PPI::Statement::Package
[    4,   1,   1 ]         PPI::Token::Word     'package'
[    4,   8,   8 ]         PPI::Token::Whitespace   ' '
[    4,   9,   9 ]         PPI::Token::Word     'main'
[    4,  13,  13 ]         PPI::Token::Structure    ';'
[    4,  14,  14 ]     PPI::Token::Whitespace   '\n'
[    5,   1,   1 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement
[    6,   1,   1 ]         PPI::Token::Symbol   '$y'
[    6,   3,   3 ]         PPI::Token::Whitespace   ' '
[    6,   4,   4 ]         PPI::Token::Operator     '='
[    6,   5,   5 ]         PPI::Token::Whitespace   ' '
[    6,   6,   6 ]         PPI::Token::Number   '2'
[    6,   7,   7 ]         PPI::Token::Structure    ';'
[    6,   8,   8 ]     PPI::Token::Whitespace   '\n'
END_EXPECTED_MAIN

        Foo => [ <<'END_EXPECTED_FOO' ],
                    PPI::Document::Fragment
                        PPI::Statement::Package
[    1,   1,   1 ]         PPI::Token::Word     'package'
[    1,   8,   8 ]         PPI::Token::Whitespace   ' '
[    1,   9,   9 ]         PPI::Token::Word     'Foo'
[    1,  12,  12 ]         PPI::Token::Structure    ';'
[    1,  13,  13 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement
[    2,   1,   1 ]         PPI::Token::Symbol   '$x'
[    2,   3,   3 ]         PPI::Token::Whitespace   ' '
[    2,   4,   4 ]         PPI::Token::Operator     '='
[    2,   5,   5 ]         PPI::Token::Whitespace   ' '
[    2,   6,   6 ]         PPI::Token::Number   '1'
[    2,   7,   7 ]         PPI::Token::Structure    ';'
[    2,   8,   8 ]     PPI::Token::Whitespace   '\n'
[    3,   1,   1 ]     PPI::Token::Whitespace   '\n'
END_EXPECTED_FOO
    );

    _test($source, \%expected, 'Simple multiple namespaces: non-default followed by default.');
} # end scope block


{
    my $source = <<'END_SOURCE';
$x = 1;
package Foo;
$y = 2;
package main;
$z = 3;
package Foo;
$w = 4;
package main;
$v = 5;
END_SOURCE

    my %expected = (
        main => [ <<'END_EXPECTED_MAIN' ],
                    PPI::Document::Fragment
                        PPI::Statement
[    1,   1,   1 ]         PPI::Token::Symbol   '$x'
[    1,   3,   3 ]         PPI::Token::Whitespace   ' '
[    1,   4,   4 ]         PPI::Token::Operator     '='
[    1,   5,   5 ]         PPI::Token::Whitespace   ' '
[    1,   6,   6 ]         PPI::Token::Number   '1'
[    1,   7,   7 ]         PPI::Token::Structure    ';'
[    1,   8,   8 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement::Package
[    4,   1,   1 ]         PPI::Token::Word     'package'
[    4,   8,   8 ]         PPI::Token::Whitespace   ' '
[    4,   9,   9 ]         PPI::Token::Word     'main'
[    4,  13,  13 ]         PPI::Token::Structure    ';'
[    4,  14,  14 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement
[    5,   1,   1 ]         PPI::Token::Symbol   '$z'
[    5,   3,   3 ]         PPI::Token::Whitespace   ' '
[    5,   4,   4 ]         PPI::Token::Operator     '='
[    5,   5,   5 ]         PPI::Token::Whitespace   ' '
[    5,   6,   6 ]         PPI::Token::Number   '3'
[    5,   7,   7 ]         PPI::Token::Structure    ';'
[    5,   8,   8 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement::Package
[    8,   1,   1 ]         PPI::Token::Word     'package'
[    8,   8,   8 ]         PPI::Token::Whitespace   ' '
[    8,   9,   9 ]         PPI::Token::Word     'main'
[    8,  13,  13 ]         PPI::Token::Structure    ';'
[    8,  14,  14 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement
[    9,   1,   1 ]         PPI::Token::Symbol   '$v'
[    9,   3,   3 ]         PPI::Token::Whitespace   ' '
[    9,   4,   4 ]         PPI::Token::Operator     '='
[    9,   5,   5 ]         PPI::Token::Whitespace   ' '
[    9,   6,   6 ]         PPI::Token::Number   '5'
[    9,   7,   7 ]         PPI::Token::Structure    ';'
[    9,   8,   8 ]     PPI::Token::Whitespace   '\n'
END_EXPECTED_MAIN

        Foo => [ <<'END_EXPECTED_FOO' ],
                    PPI::Document::Fragment
                        PPI::Statement::Package
[    2,   1,   1 ]         PPI::Token::Word     'package'
[    2,   8,   8 ]         PPI::Token::Whitespace   ' '
[    2,   9,   9 ]         PPI::Token::Word     'Foo'
[    2,  12,  12 ]         PPI::Token::Structure    ';'
[    2,  13,  13 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement
[    3,   1,   1 ]         PPI::Token::Symbol   '$y'
[    3,   3,   3 ]         PPI::Token::Whitespace   ' '
[    3,   4,   4 ]         PPI::Token::Operator     '='
[    3,   5,   5 ]         PPI::Token::Whitespace   ' '
[    3,   6,   6 ]         PPI::Token::Number   '2'
[    3,   7,   7 ]         PPI::Token::Structure    ';'
[    3,   8,   8 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement::Package
[    6,   1,   1 ]         PPI::Token::Word     'package'
[    6,   8,   8 ]         PPI::Token::Whitespace   ' '
[    6,   9,   9 ]         PPI::Token::Word     'Foo'
[    6,  12,  12 ]         PPI::Token::Structure    ';'
[    6,  13,  13 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement
[    7,   1,   1 ]         PPI::Token::Symbol   '$w'
[    7,   3,   3 ]         PPI::Token::Whitespace   ' '
[    7,   4,   4 ]         PPI::Token::Operator     '='
[    7,   5,   5 ]         PPI::Token::Whitespace   ' '
[    7,   6,   6 ]         PPI::Token::Number   '4'
[    7,   7,   7 ]         PPI::Token::Structure    ';'
[    7,   8,   8 ]     PPI::Token::Whitespace   '\n'
END_EXPECTED_FOO
    );

    _test(
        $source,
        \%expected,
        'Simple multiple namespaces: back and forth between two.',
    );
} # end scope block


{
    my $source = <<'END_SOURCE';
$x = 1;

{
    package Foo;
    $a = 17;
}

$y = 2;
END_SOURCE

    my %expected = (
        main => [ <<'END_EXPECTED_MAIN' ],
                    PPI::Document::Fragment
                        PPI::Statement
[    1,   1,   1 ]         PPI::Token::Symbol   '$x'
[    1,   3,   3 ]         PPI::Token::Whitespace   ' '
[    1,   4,   4 ]         PPI::Token::Operator     '='
[    1,   5,   5 ]         PPI::Token::Whitespace   ' '
[    1,   6,   6 ]         PPI::Token::Number   '1'
[    1,   7,   7 ]         PPI::Token::Structure    ';'
[    1,   8,   8 ]     PPI::Token::Whitespace   '\n'
[    2,   1,   1 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement::Compound
                            PPI::Structure::Block   { ... }
[    3,   2,   2 ]             PPI::Token::Whitespace   '\n'
[    4,   1,   1 ]             PPI::Token::Whitespace   '    '
[    6,   2,   2 ]     PPI::Token::Whitespace   '\n'
[    7,   1,   1 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement
[    8,   1,   1 ]         PPI::Token::Symbol   '$y'
[    8,   3,   3 ]         PPI::Token::Whitespace   ' '
[    8,   4,   4 ]         PPI::Token::Operator     '='
[    8,   5,   5 ]         PPI::Token::Whitespace   ' '
[    8,   6,   6 ]         PPI::Token::Number   '2'
[    8,   7,   7 ]         PPI::Token::Structure    ';'
[    8,   8,   8 ]     PPI::Token::Whitespace   '\n'
END_EXPECTED_MAIN

        Foo => [ <<'END_EXPECTED_FOO' ],
                    PPI::Document::Fragment
                        PPI::Statement::Package
[    4,   5,   5 ]         PPI::Token::Word     'package'
[    4,  12,  12 ]         PPI::Token::Whitespace   ' '
[    4,  13,  13 ]         PPI::Token::Word     'Foo'
[    4,  16,  16 ]         PPI::Token::Structure    ';'
[    4,  17,  17 ]     PPI::Token::Whitespace   '\n'
[    5,   1,   1 ]     PPI::Token::Whitespace   '    '
                        PPI::Statement
[    5,   5,   5 ]         PPI::Token::Symbol   '$a'
[    5,   7,   7 ]         PPI::Token::Whitespace   ' '
[    5,   8,   8 ]         PPI::Token::Operator     '='
[    5,   9,   9 ]         PPI::Token::Whitespace   ' '
[    5,  10,  10 ]         PPI::Token::Number   '17'
[    5,  12,  12 ]         PPI::Token::Structure    ';'
[    5,  13,  13 ]     PPI::Token::Whitespace   '\n'
END_EXPECTED_FOO
    );

    _test($source, \%expected, 'Single lexically scoped namespace: scope block.');
} # end scope block


{
    my $source = <<'END_SOURCE';
$x = 1;

foreach qw< l m n > {
    package Foo;
    $a = 17;
}

$y = 2;
END_SOURCE

    my %expected = (
        main => [ <<'END_EXPECTED_MAIN' ],
                    PPI::Document::Fragment
                        PPI::Statement
[    1,   1,   1 ]         PPI::Token::Symbol   '$x'
[    1,   3,   3 ]         PPI::Token::Whitespace   ' '
[    1,   4,   4 ]         PPI::Token::Operator     '='
[    1,   5,   5 ]         PPI::Token::Whitespace   ' '
[    1,   6,   6 ]         PPI::Token::Number   '1'
[    1,   7,   7 ]         PPI::Token::Structure    ';'
[    1,   8,   8 ]     PPI::Token::Whitespace   '\n'
[    2,   1,   1 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement::Compound
[    3,   1,   1 ]         PPI::Token::Word     'foreach'
[    3,   8,   8 ]         PPI::Token::Whitespace   ' '
[    3,   9,   9 ]         PPI::Token::QuoteLike::Words     'qw< l m n >'
[    3,  20,  20 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::Block   { ... }
[    3,  22,  22 ]             PPI::Token::Whitespace   '\n'
[    4,   1,   1 ]             PPI::Token::Whitespace   '    '
[    6,   2,   2 ]     PPI::Token::Whitespace   '\n'
[    7,   1,   1 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement
[    8,   1,   1 ]         PPI::Token::Symbol   '$y'
[    8,   3,   3 ]         PPI::Token::Whitespace   ' '
[    8,   4,   4 ]         PPI::Token::Operator     '='
[    8,   5,   5 ]         PPI::Token::Whitespace   ' '
[    8,   6,   6 ]         PPI::Token::Number   '2'
[    8,   7,   7 ]         PPI::Token::Structure    ';'
[    8,   8,   8 ]     PPI::Token::Whitespace   '\n'
END_EXPECTED_MAIN

        Foo => [ <<'END_EXPECTED_FOO' ],
                    PPI::Document::Fragment
                        PPI::Statement::Package
[    4,   5,   5 ]         PPI::Token::Word     'package'
[    4,  12,  12 ]         PPI::Token::Whitespace   ' '
[    4,  13,  13 ]         PPI::Token::Word     'Foo'
[    4,  16,  16 ]         PPI::Token::Structure    ';'
[    4,  17,  17 ]     PPI::Token::Whitespace   '\n'
[    5,   1,   1 ]     PPI::Token::Whitespace   '    '
                        PPI::Statement
[    5,   5,   5 ]         PPI::Token::Symbol   '$a'
[    5,   7,   7 ]         PPI::Token::Whitespace   ' '
[    5,   8,   8 ]         PPI::Token::Operator     '='
[    5,   9,   9 ]         PPI::Token::Whitespace   ' '
[    5,  10,  10 ]         PPI::Token::Number   '17'
[    5,  12,  12 ]         PPI::Token::Structure    ';'
[    5,  13,  13 ]     PPI::Token::Whitespace   '\n'
END_EXPECTED_FOO
    );

    _test(
        $source,
        \%expected,
        'Single lexically scoped namespace: foreach loop.',
    );
} # end scope block


{
    my $source = <<'END_SOURCE';
$x = 1;

given qw< l m n > {
    package Foo;
    $a = 17;
}

$y = 2;
END_SOURCE

    my %expected = (
        main => [ <<'END_EXPECTED_MAIN' ],
                    PPI::Document::Fragment
                        PPI::Statement
[    1,   1,   1 ]         PPI::Token::Symbol   '$x'
[    1,   3,   3 ]         PPI::Token::Whitespace   ' '
[    1,   4,   4 ]         PPI::Token::Operator     '='
[    1,   5,   5 ]         PPI::Token::Whitespace   ' '
[    1,   6,   6 ]         PPI::Token::Number   '1'
[    1,   7,   7 ]         PPI::Token::Structure    ';'
[    1,   8,   8 ]     PPI::Token::Whitespace   '\n'
[    2,   1,   1 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement::Given
[    3,   1,   1 ]         PPI::Token::Word     'given'
[    3,   6,   6 ]         PPI::Token::Whitespace   ' '
[    3,   7,   7 ]         PPI::Token::QuoteLike::Words     'qw< l m n >'
[    3,  18,  18 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::Block   { ... }
[    3,  20,  20 ]             PPI::Token::Whitespace   '\n'
[    4,   1,   1 ]             PPI::Token::Whitespace   '    '
[    6,   2,   2 ]     PPI::Token::Whitespace   '\n'
[    7,   1,   1 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement
[    8,   1,   1 ]         PPI::Token::Symbol   '$y'
[    8,   3,   3 ]         PPI::Token::Whitespace   ' '
[    8,   4,   4 ]         PPI::Token::Operator     '='
[    8,   5,   5 ]         PPI::Token::Whitespace   ' '
[    8,   6,   6 ]         PPI::Token::Number   '2'
[    8,   7,   7 ]         PPI::Token::Structure    ';'
[    8,   8,   8 ]     PPI::Token::Whitespace   '\n'
END_EXPECTED_MAIN

        Foo => [ <<'END_EXPECTED_FOO' ],
                    PPI::Document::Fragment
                        PPI::Statement::Package
[    4,   5,   5 ]         PPI::Token::Word     'package'
[    4,  12,  12 ]         PPI::Token::Whitespace   ' '
[    4,  13,  13 ]         PPI::Token::Word     'Foo'
[    4,  16,  16 ]         PPI::Token::Structure    ';'
[    4,  17,  17 ]     PPI::Token::Whitespace   '\n'
[    5,   1,   1 ]     PPI::Token::Whitespace   '    '
                        PPI::Statement
[    5,   5,   5 ]         PPI::Token::Symbol   '$a'
[    5,   7,   7 ]         PPI::Token::Whitespace   ' '
[    5,   8,   8 ]         PPI::Token::Operator     '='
[    5,   9,   9 ]         PPI::Token::Whitespace   ' '
[    5,  10,  10 ]         PPI::Token::Number   '17'
[    5,  12,  12 ]         PPI::Token::Structure    ';'
[    5,  13,  13 ]     PPI::Token::Whitespace   '\n'
END_EXPECTED_FOO
    );

    _test(
        $source,
        \%expected,
        'Single lexically scoped namespace: given.',
    );
} # end scope block


{
    my $source = <<'END_SOURCE';
$x = 1;

when qw< l m n > {
    package Foo;
    $a = 17;
}

$y = 2;
END_SOURCE

    my %expected = (
        main => [ <<'END_EXPECTED_MAIN' ],
                    PPI::Document::Fragment
                        PPI::Statement
[    1,   1,   1 ]         PPI::Token::Symbol   '$x'
[    1,   3,   3 ]         PPI::Token::Whitespace   ' '
[    1,   4,   4 ]         PPI::Token::Operator     '='
[    1,   5,   5 ]         PPI::Token::Whitespace   ' '
[    1,   6,   6 ]         PPI::Token::Number   '1'
[    1,   7,   7 ]         PPI::Token::Structure    ';'
[    1,   8,   8 ]     PPI::Token::Whitespace   '\n'
[    2,   1,   1 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement::When
[    3,   1,   1 ]         PPI::Token::Word     'when'
[    3,   5,   5 ]         PPI::Token::Whitespace   ' '
[    3,   6,   6 ]         PPI::Token::QuoteLike::Words     'qw< l m n >'
[    3,  17,  17 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::Block   { ... }
[    3,  19,  19 ]             PPI::Token::Whitespace   '\n'
[    4,   1,   1 ]             PPI::Token::Whitespace   '    '
[    6,   2,   2 ]     PPI::Token::Whitespace   '\n'
[    7,   1,   1 ]     PPI::Token::Whitespace   '\n'
                        PPI::Statement
[    8,   1,   1 ]         PPI::Token::Symbol   '$y'
[    8,   3,   3 ]         PPI::Token::Whitespace   ' '
[    8,   4,   4 ]         PPI::Token::Operator     '='
[    8,   5,   5 ]         PPI::Token::Whitespace   ' '
[    8,   6,   6 ]         PPI::Token::Number   '2'
[    8,   7,   7 ]         PPI::Token::Structure    ';'
[    8,   8,   8 ]     PPI::Token::Whitespace   '\n'
END_EXPECTED_MAIN

        Foo => [ <<'END_EXPECTED_FOO' ],
                    PPI::Document::Fragment
                        PPI::Statement::Package
[    4,   5,   5 ]         PPI::Token::Word     'package'
[    4,  12,  12 ]         PPI::Token::Whitespace   ' '
[    4,  13,  13 ]         PPI::Token::Word     'Foo'
[    4,  16,  16 ]         PPI::Token::Structure    ';'
[    4,  17,  17 ]     PPI::Token::Whitespace   '\n'
[    5,   1,   1 ]     PPI::Token::Whitespace   '    '
                        PPI::Statement
[    5,   5,   5 ]         PPI::Token::Symbol   '$a'
[    5,   7,   7 ]         PPI::Token::Whitespace   ' '
[    5,   8,   8 ]         PPI::Token::Operator     '='
[    5,   9,   9 ]         PPI::Token::Whitespace   ' '
[    5,  10,  10 ]         PPI::Token::Number   '17'
[    5,  12,  12 ]         PPI::Token::Structure    ';'
[    5,  13,  13 ]     PPI::Token::Whitespace   '\n'
END_EXPECTED_FOO
    );

    _test(
        $source,
        \%expected,
        'Single lexically scoped namespace: when.',
    );
} # end scope block


{
    my $source = <<'END_SOURCE';
given (0) {
    package Foo;
    when (1) {
        package main;
    }
    when (2) {
        package main;
    }
    default {
        package main;
        while (3) {
            package Foo;
            package Bar;
            package Foo;
            package main;
            foreach (4) {
                package Foo;
            }
        }
    }
}
END_SOURCE

    my %expected = (
        main => [
<<'END_EXPECTED_MAIN',
                    PPI::Document::Fragment
                        PPI::Statement::Given
[    1,   1,   1 ]         PPI::Token::Word     'given'
[    1,   6,   6 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::Given   ( ... )
                                PPI::Statement::Expression
[    1,   8,   8 ]                 PPI::Token::Number   '0'
[    1,  10,  10 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::Block   { ... }
[    1,  12,  12 ]             PPI::Token::Whitespace   '\n'
[    2,   1,   1 ]             PPI::Token::Whitespace   '    '
[   21,   2,   2 ]     PPI::Token::Whitespace   '\n'
END_EXPECTED_MAIN
<<'END_EXPECTED_MAIN',
                    PPI::Document::Fragment
                        PPI::Statement::Package
[    4,   9,   9 ]         PPI::Token::Word     'package'
[    4,  16,  16 ]         PPI::Token::Whitespace   ' '
[    4,  17,  17 ]         PPI::Token::Word     'main'
[    4,  21,  21 ]         PPI::Token::Structure    ';'
[    4,  22,  22 ]     PPI::Token::Whitespace   '\n'
[    5,   1,   1 ]     PPI::Token::Whitespace   '    '
END_EXPECTED_MAIN
<<'END_EXPECTED_MAIN',
                    PPI::Document::Fragment
                        PPI::Statement::Package
[    7,   9,   9 ]         PPI::Token::Word     'package'
[    7,  16,  16 ]         PPI::Token::Whitespace   ' '
[    7,  17,  17 ]         PPI::Token::Word     'main'
[    7,  21,  21 ]         PPI::Token::Structure    ';'
[    7,  22,  22 ]     PPI::Token::Whitespace   '\n'
[    8,   1,   1 ]     PPI::Token::Whitespace   '    '
END_EXPECTED_MAIN
<<'END_EXPECTED_MAIN',
                    PPI::Document::Fragment
                        PPI::Statement::Package
[   10,   9,   9 ]         PPI::Token::Word     'package'
[   10,  16,  16 ]         PPI::Token::Whitespace   ' '
[   10,  17,  17 ]         PPI::Token::Word     'main'
[   10,  21,  21 ]         PPI::Token::Structure    ';'
[   10,  22,  22 ]     PPI::Token::Whitespace   '\n'
[   11,   1,   1 ]     PPI::Token::Whitespace   '        '
                        PPI::Statement::Compound
[   11,   9,   9 ]         PPI::Token::Word     'while'
[   11,  14,  14 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::Condition   ( ... )
                                PPI::Statement::Expression
[   11,  16,  16 ]                 PPI::Token::Number   '3'
[   11,  18,  18 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::Block   { ... }
[   11,  20,  20 ]             PPI::Token::Whitespace   '\n'
[   12,   1,   1 ]             PPI::Token::Whitespace   '            '
                                PPI::Statement::Package
[   15,  13,  13 ]                 PPI::Token::Word     'package'
[   15,  20,  20 ]                 PPI::Token::Whitespace   ' '
[   15,  21,  21 ]                 PPI::Token::Word     'main'
[   15,  25,  25 ]                 PPI::Token::Structure    ';'
[   15,  26,  26 ]             PPI::Token::Whitespace   '\n'
[   16,   1,   1 ]             PPI::Token::Whitespace   '            '
                                PPI::Statement::Compound
[   16,  13,  13 ]                 PPI::Token::Word     'foreach'
[   16,  20,  20 ]                 PPI::Token::Whitespace   ' '
                                    PPI::Structure::List    ( ... )
                                        PPI::Statement
[   16,  22,  22 ]                         PPI::Token::Number   '4'
[   16,  24,  24 ]                 PPI::Token::Whitespace   ' '
                                    PPI::Structure::Block   { ... }
[   16,  26,  26 ]                     PPI::Token::Whitespace   '\n'
[   17,   1,   1 ]                     PPI::Token::Whitespace   '                '
[   18,  14,  14 ]             PPI::Token::Whitespace   '\n'
[   19,   1,   1 ]             PPI::Token::Whitespace   '        '
[   19,  10,  10 ]     PPI::Token::Whitespace   '\n'
[   20,   1,   1 ]     PPI::Token::Whitespace   '    '
END_EXPECTED_MAIN
        ],

        Foo => [
<<'END_EXPECTED_FOO',
                    PPI::Document::Fragment
                        PPI::Statement::Package
[    2,   5,   5 ]         PPI::Token::Word     'package'
[    2,  12,  12 ]         PPI::Token::Whitespace   ' '
[    2,  13,  13 ]         PPI::Token::Word     'Foo'
[    2,  16,  16 ]         PPI::Token::Structure    ';'
[    2,  17,  17 ]     PPI::Token::Whitespace   '\n'
[    3,   1,   1 ]     PPI::Token::Whitespace   '    '
                        PPI::Statement::When
[    3,   5,   5 ]         PPI::Token::Word     'when'
[    3,   9,   9 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::When    ( ... )
                                PPI::Statement::Expression
[    3,  11,  11 ]                 PPI::Token::Number   '1'
[    3,  13,  13 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::Block   { ... }
[    3,  15,  15 ]             PPI::Token::Whitespace   '\n'
[    4,   1,   1 ]             PPI::Token::Whitespace   '        '
[    5,   6,   6 ]     PPI::Token::Whitespace   '\n'
[    6,   1,   1 ]     PPI::Token::Whitespace   '    '
                        PPI::Statement::When
[    6,   5,   5 ]         PPI::Token::Word     'when'
[    6,   9,   9 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::When    ( ... )
                                PPI::Statement::Expression
[    6,  11,  11 ]                 PPI::Token::Number   '2'
[    6,  13,  13 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::Block   { ... }
[    6,  15,  15 ]             PPI::Token::Whitespace   '\n'
[    7,   1,   1 ]             PPI::Token::Whitespace   '        '
[    8,   6,   6 ]     PPI::Token::Whitespace   '\n'
[    9,   1,   1 ]     PPI::Token::Whitespace   '    '
                        PPI::Statement::When
[    9,   5,   5 ]         PPI::Token::Word     'default'
[    9,  12,  12 ]         PPI::Token::Whitespace   ' '
                            PPI::Structure::Block   { ... }
[    9,  14,  14 ]             PPI::Token::Whitespace   '\n'
[   10,   1,   1 ]             PPI::Token::Whitespace   '        '
[   20,   6,   6 ]     PPI::Token::Whitespace   '\n'
END_EXPECTED_FOO
<<'END_EXPECTED_FOO',
                    PPI::Document::Fragment
                        PPI::Statement::Package
[   12,  13,  13 ]         PPI::Token::Word     'package'
[   12,  20,  20 ]         PPI::Token::Whitespace   ' '
[   12,  21,  21 ]         PPI::Token::Word     'Foo'
[   12,  24,  24 ]         PPI::Token::Structure    ';'
[   12,  25,  25 ]     PPI::Token::Whitespace   '\n'
[   13,   1,   1 ]     PPI::Token::Whitespace   '            '
                        PPI::Statement::Package
[   14,  13,  13 ]         PPI::Token::Word     'package'
[   14,  20,  20 ]         PPI::Token::Whitespace   ' '
[   14,  21,  21 ]         PPI::Token::Word     'Foo'
[   14,  24,  24 ]         PPI::Token::Structure    ';'
[   14,  25,  25 ]     PPI::Token::Whitespace   '\n'
[   15,   1,   1 ]     PPI::Token::Whitespace   '            '
END_EXPECTED_FOO
<<'END_EXPECTED_FOO',
                    PPI::Document::Fragment
                        PPI::Statement::Package
[   17,  17,  17 ]         PPI::Token::Word     'package'
[   17,  24,  24 ]         PPI::Token::Whitespace   ' '
[   17,  25,  25 ]         PPI::Token::Word     'Foo'
[   17,  28,  28 ]         PPI::Token::Structure    ';'
[   17,  29,  29 ]     PPI::Token::Whitespace   '\n'
[   18,   1,   1 ]     PPI::Token::Whitespace   '            '
END_EXPECTED_FOO
        ],

        Bar => [ <<'END_EXPECTED_BAR' ],
                    PPI::Document::Fragment
                        PPI::Statement::Package
[   13,  13,  13 ]         PPI::Token::Word     'package'
[   13,  20,  20 ]         PPI::Token::Whitespace   ' '
[   13,  21,  21 ]         PPI::Token::Word     'Bar'
[   13,  24,  24 ]         PPI::Token::Structure    ';'
[   13,  25,  25 ]     PPI::Token::Whitespace   '\n'
[   14,   1,   1 ]     PPI::Token::Whitespace   '            '
END_EXPECTED_BAR
    );

    _test(
        $source,
        \%expected,
        'Heavilly nested namespaces.',
    );
} # end scope block


sub _test {
    my ($source, $expected_ref, $test_name) = @_;

    my $document = PPI::Document->new(\$source);

    my %expanded_expected;
    while ( my ($namespace, $strings) = each %{$expected_ref} ) {
        $expanded_expected{$namespace} =
            [ map { [ split m/ \n /xms ] } @{$strings} ];
    } # end while

    my $got = split_ppi_node_by_namespace($document);
    my %got_expanded;
    while ( my ($namespace, $ppi_doms) = each %{$got} ) {
        $got_expanded{$namespace} =
            [
                map {
                        [ map { _expand_tabs($_) } _new_dumper($_)->list() ]
                    }
                    @{$ppi_doms}
            ];
    } # end while

    cmp_deeply(\%got_expanded, \%expanded_expected, $test_name)
        or diag(
            Data::Dumper->Dump(
                [\%got_expanded, \%expanded_expected],
                [ qw<got_expanded expanded_expected> ],
            )
        );

    return;
} # end _test()


sub _new_dumper {
    my ($node) = @_;

    return PPI::Dumper->new($node, indent => $DUMP_INDENT, locations => 1);
} # end _new_dumper()


# Why Adam had to put @#$^@#$&^ hard tabs in his dumper output, I don't know.
sub _expand_tabs {
    my ($string) = @_;

    while (
        $string =~
            s< \A ( [^\t]* ) ( \t+ )                          >
             <$1 . ( ' ' x (length($2) * $DUMP_INDENT - length($1) % $DUMP_INDENT) )>xmse
    ) {
        # Nothing here.
    } # end while

    return $string;
} # end _expand_tabs()


#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/PPIx-Utilities/t/split-ppi-node-by-namespace.t $
#     $Date: 2010-11-13 14:25:12 -0600 (Sat, 13 Nov 2010) $
#   $Author: clonezone $
# $Revision: 3990 $

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
