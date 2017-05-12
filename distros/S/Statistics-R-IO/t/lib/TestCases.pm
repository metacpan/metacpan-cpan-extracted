package TestCases;

use 5.010;

use strict;
use warnings FATAL => 'all';

use Exporter 'import';

our @EXPORT = qw( TEST_CASES );

use ShortDoubleVector;
use ClosureLenientEnv;
use RexpOrUnknown;
use LenientSrcFile;

use Statistics::R::IO::Parser qw( :all );
use Statistics::R::IO::ParserState;
use Statistics::R::REXP::Character;
use Statistics::R::REXP::Complex;
use Statistics::R::REXP::Double;
use Statistics::R::REXP::Integer;
use Statistics::R::REXP::List;
use Statistics::R::REXP::Logical;
use Statistics::R::REXP::Raw;
use Statistics::R::REXP::Language;
use Statistics::R::REXP::Expression;
use Statistics::R::REXP::Closure;
use Statistics::R::REXP::Symbol;
use Statistics::R::REXP::Null;
use Statistics::R::REXP::GlobalEnvironment;
use Statistics::R::REXP::EmptyEnvironment;
use Statistics::R::REXP::BaseEnvironment;
use Statistics::R::REXP::Unknown;
use Statistics::R::REXP::S4;

use Math::Complex qw(cplx);

use constant nan => unpack 'd>', pack 'H*', '7ff8000000000000';
die 'Cannot create a known NaN value' unless
    (1+nan eq nan) && (nan != nan);

use constant ninf => unpack 'd>', pack 'H*', 'fff0000000000000';
die 'Cannot create a known -Inf value' unless
    (1+ninf eq ninf) && (ninf == ninf) && (ninf < 0);

use constant TEST_SRC_FILE => {
    empty_clos => LenientSrcFile->new(
        frame => {
            Enc => Statistics::R::REXP::Character->new(['unknown']),
            filename => Statistics::R::REXP::Character->new(['<text>']),
            fixedNewlines => Statistics::R::REXP::Logical->new([1]),
            isFile => Statistics::R::REXP::Logical->new([0]),
            lines => Statistics::R::REXP::Character->new(['{function() {}}']),
            parseData => Statistics::R::REXP::Integer->new(
                elements => [
                    1, 1, 1, 1, 1, 123, 1, 13, 1, 2, 1, 9, 1, 264, 2, 10, 1,
                    10, 1, 10, 1, 40, 3, 10, 1, 11, 1, 11, 1, 41, 4, 10, 1, 13,
                    1, 13, 1, 123, 5, 7, 1, 14, 1, 14, 1, 125, 6, 7, 1, 13, 1,
                    14, 0, 77, 7, 10, 1, 15, 1, 15, 1, 125, 8, 13, 1, 2, 1, 14,
                    0, 77, 10, 13, 1, 1, 1, 15, 0, 77, 13, 0],
                attributes => {
                    class => Statistics::R::REXP::Character->new(['parseData']),
                    dim => Statistics::R::REXP::Integer->new([8, 10]),
                    text => Statistics::R::REXP::Character->new([
                        '{', 'function', '(', ')', '{', '}', '', '}', '', '']),
                        tokens => Statistics::R::REXP::Character->new([
                            "'{'", 'FUNCTION', "'('", "')'", "'{'", "'}'", 'expr', "'}'", 'expr', 'expr']),
                }),
            timestamp => Statistics::R::REXP::Double->new(
                elements => [12345],
                attributes => {
                    class => Statistics::R::REXP::Character->new(['POSIXct', 'POSIXt']),
                }),
            wd => Statistics::R::REXP::Character->new(['abcd'])
        },
        attributes => {
            class => Statistics::R::REXP::Character->new(['srcfilecopy', 'srcfile'])
        },
        enclosure => Statistics::R::REXP::EmptyEnvironment->new),
    clos_args => LenientSrcFile->new(
        frame => {
            Enc => Statistics::R::REXP::Character->new(['unknown']),
            filename => Statistics::R::REXP::Character->new(['<text>']),
            fixedNewlines => Statistics::R::REXP::Logical->new([1]),
            isFile => Statistics::R::REXP::Logical->new([0]),
            lines => Statistics::R::REXP::Character->new(['{function(a, b) {a - b}}']),
            parseData => Statistics::R::REXP::Integer->new(
                elements => [
                    1, 1, 1, 1, 1, 123, 1, 26, 1, 2, 1, 9, 1, 264, 2, 23, 1, 10, 1,
                    10, 1, 40, 3, 23, 1, 11, 1, 11, 1, 292, 4, 23, 1, 12, 1, 12, 1,
                    44, 5, 23, 1, 14, 1, 14, 1, 292, 7, 23, 1, 15, 1, 15, 1, 41, 8,
                    23, 1, 17, 1, 17, 1, 123, 10, 20, 1, 18, 1, 18, 1, 263, 11, 13,
                    1, 20, 1, 20, 1, 45, 12, 17, 1, 18, 1, 18, 0, 77, 13, 17, 1, 22,
                    1, 22, 1, 263, 14, 16, 1, 23, 1, 23, 1, 125, 15, 20, 1, 22, 1,
                    22, 0, 77, 16, 17, 1, 18, 1, 22, 0, 77, 17, 20, 1, 17, 1, 23, 0,
                    77, 20, 23, 1, 24, 1, 24, 1, 125, 21, 26, 1, 2, 1, 23, 0, 77,
                    23, 26, 1, 1, 1, 24, 0, 77, 26, 0],
                attributes => {
                    class => Statistics::R::REXP::Character->new(['parseData']),
                    dim => Statistics::R::REXP::Integer->new([8, 19]),
                    text => Statistics::R::REXP::Character->new([
                        '{', 'function', '(', 'a', ',', 'b', ')', '{', 'a', '-', '', 'b', '}', '', '', '', '}', '', '']),
                    tokens => Statistics::R::REXP::Character->new([
                        "'{'", 'FUNCTION', "'('", 'SYMBOL_FORMALS', "','", 'SYMBOL_FORMALS', "')'",
                        "'{'", 'SYMBOL', "'-'", 'expr', 'SYMBOL', "'}'", 'expr', 'expr', 'expr', "'}'", 'expr', 'expr']),
                }),
            timestamp => Statistics::R::REXP::Double->new(
                elements => [12345],
                attributes => {
                    class => Statistics::R::REXP::Character->new(['POSIXct', 'POSIXt']),
                }),
            wd => Statistics::R::REXP::Character->new(['abcd'])
        },
        attributes => {
            class => Statistics::R::REXP::Character->new(['srcfilecopy', 'srcfile'])
        },
        enclosure => Statistics::R::REXP::EmptyEnvironment->new),
    clos_defaults => LenientSrcFile->new(
        frame => {
            Enc => Statistics::R::REXP::Character->new(['unknown']),
            filename => Statistics::R::REXP::Character->new(['<text>']),
            fixedNewlines => Statistics::R::REXP::Logical->new([1]),
            isFile => Statistics::R::REXP::Logical->new([0]),
            lines => Statistics::R::REXP::Character->new(['{function(a=3, b) {a + b * pi}}']),
            parseData => Statistics::R::REXP::Integer->new(
                elements => [
                    1, 1, 1, 1, 1, 123, 1, 33, 1, 2, 1, 9, 1, 264, 2, 30, 1, 10,
                    1, 10, 1, 40, 3, 30, 1, 11, 1, 11, 1, 292, 4, 30, 1, 12, 1,
                    12, 1, 293, 5, 30, 1, 13, 1, 13, 1, 261, 6, 7, 1, 13, 1, 13,
                    0, 77, 7, 30, 1, 14, 1, 14, 1, 44, 8, 30, 1, 16, 1, 16, 1,
                    292, 10, 30, 1, 17, 1, 17, 1, 41, 11, 30, 1, 19, 1, 19, 1,
                    123, 13, 27, 1, 20, 1, 20, 1, 263, 14, 16, 1, 22, 1, 22, 1,
                    43, 15, 24, 1, 20, 1, 20, 0, 77, 16, 24, 1, 24, 1, 24, 1,
                    263, 17, 19, 1, 26, 1, 26, 1, 42, 18, 23, 1, 24, 1, 24, 0,
                    77, 19, 23, 1, 28, 1, 29, 1, 263, 20, 22, 1, 30, 1, 30, 1,
                    125, 21, 27, 1, 28, 1, 29, 0, 77, 22, 23, 1, 24, 1, 29, 0,
                    77, 23, 24, 1, 20, 1, 29, 0, 77, 24, 27, 1, 19, 1, 30, 0, 77,
                    27, 30, 1, 31, 1, 31, 1, 125, 28, 33, 1, 2, 1, 30, 0, 77, 30,
                    33, 1, 1, 1, 31, 0, 77, 33, 0],
                attributes => {
                    class => Statistics::R::REXP::Character->new(['parseData']),
                    dim => Statistics::R::REXP::Integer->new([8, 26]),
                    text => Statistics::R::REXP::Character->new([
                        '{', 'function', '(', 'a', '=', '3', '', ',', 'b', ')', '{', 'a', '+', '', 'b', '*', '', 'pi', '}', '', '', '', '', '}', '', '']),
                    tokens => Statistics::R::REXP::Character->new([
                        "'{'", 'FUNCTION', "'('", 'SYMBOL_FORMALS', 'EQ_FORMALS', 'NUM_CONST', 'expr', "','", 'SYMBOL_FORMALS', "')'",
                        "'{'", 'SYMBOL', "'+'", 'expr', 'SYMBOL', "'*'", 'expr', 'SYMBOL', "'}'", 'expr', 'expr', 'expr', 'expr', "'}'", 'expr', 'expr']),
                }),
            timestamp => Statistics::R::REXP::Double->new(
                elements => [12345],
                attributes => {
                    class => Statistics::R::REXP::Character->new(['POSIXct', 'POSIXt']),
                }),
            wd => Statistics::R::REXP::Character->new(['abcd'])
        },
        attributes => {
            class => Statistics::R::REXP::Character->new(['srcfilecopy', 'srcfile'])
        },
        enclosure => Statistics::R::REXP::EmptyEnvironment->new),
    clos_dots => LenientSrcFile->new(
        frame => {
            Enc => Statistics::R::REXP::Character->new(['unknown']),
            filename => Statistics::R::REXP::Character->new(['<text>']),
            fixedNewlines => Statistics::R::REXP::Logical->new([1]),
            isFile => Statistics::R::REXP::Logical->new([0]),
            lines => Statistics::R::REXP::Character->new(['{function(x=3, y, ...) {x * log(y) }}']),
            parseData => Statistics::R::REXP::Integer->new(
                elements => [
                    1, 1, 1, 1, 1, 123, 1, 39, 1, 2, 1, 9, 1, 264, 2, 36, 1, 10,
                    1, 10, 1, 40, 3, 36, 1, 11, 1, 11, 1, 292, 4, 36, 1, 12, 1,
                    12, 1, 293, 5, 36, 1, 13, 1, 13, 1, 261, 6, 7, 1, 13, 1, 13,
                    0, 77, 7, 36, 1, 14, 1, 14, 1, 44, 8, 36, 1, 16, 1, 16, 1,
                    292, 10, 36, 1, 17, 1, 17, 1, 44, 11, 36, 1, 19, 1, 21, 1,
                    292, 13, 36, 1, 22, 1, 22, 1, 41, 14, 36, 1, 24, 1, 24, 1,
                    123, 16, 33, 1, 25, 1, 25, 1, 263, 17, 19, 1, 27, 1, 27, 1,
                    42, 18, 30, 1, 25, 1, 25, 0, 77, 19, 30, 1, 29, 1, 31, 1,
                    296, 20, 22, 1, 32, 1, 32, 1, 40, 21, 28, 1, 29, 1, 31, 0,
                    77, 22, 28, 1, 33, 1, 33, 1, 263, 23, 25, 1, 34, 1, 34, 1,
                    41, 24, 28, 1, 33, 1, 33, 0, 77, 25, 28, 1, 29, 1, 34, 0, 77,
                    28, 30, 1, 36, 1, 36, 1, 125, 29, 33, 1, 25, 1, 34, 0, 77, 30,
                    33, 1, 24, 1, 36, 0, 77, 33, 36, 1, 37, 1, 37, 1, 125, 34, 39,
                    1, 2, 1, 36, 0, 77, 36, 39, 1, 1, 1, 37, 0, 77, 39, 0],
                attributes => {
                    class => Statistics::R::REXP::Character->new(['parseData']),
                    dim => Statistics::R::REXP::Integer->new([8, 29]),
                    text => Statistics::R::REXP::Character->new([
                        '{', 'function', '(', 'x', '=', '3', '', ',', 'y', ',', '...', ')', '{', 'x', '*', '', 'log', '(', '', 'y', ')', '', '', '}', '', '', '}', '', '']),
                    tokens => Statistics::R::REXP::Character->new([
                        "'{'", 'FUNCTION', "'('", 'SYMBOL_FORMALS', 'EQ_FORMALS', 'NUM_CONST', 'expr', "','", 'SYMBOL_FORMALS', "','", 'SYMBOL_FORMALS', "')'",
                        "'{'", 'SYMBOL', "'*'", 'expr', 'SYMBOL_FUNCTION_CALL', "'('", 'expr', 'SYMBOL', "')'", 'expr', 'expr', "'}'", 'expr', 'expr', "'}'", 'expr', 'expr']),
                }),
            timestamp => Statistics::R::REXP::Double->new(
                elements => [12345],
                attributes => {
                    class => Statistics::R::REXP::Character->new(['POSIXct', 'POSIXt']),
                }),
            wd => Statistics::R::REXP::Character->new(['abcd'])
        },
        attributes => {
            class => Statistics::R::REXP::Character->new(['srcfilecopy', 'srcfile'])
        },
        enclosure => Statistics::R::REXP::EmptyEnvironment->new),
};

use constant TEST_CASES => {
    'empty_char' => {
        desc => 'empty char vector',
        expr => 'character()',
        value => Statistics::R::REXP::Character->new()},
    'empty_int' => {
        desc => 'empty int vector',
        expr => 'integer()',
        value => Statistics::R::REXP::Integer->new()},
    'empty_num' => {
        desc => 'empty double vector',
        expr => 'numeric()',
        value => ShortDoubleVector->new()},
    'empty_lgl' => {
        desc => 'empty logical vector',
        expr => 'logical()',
        value => Statistics::R::REXP::Logical->new()},
    'empty_list' => {
        desc => 'empty list',
        expr => 'list()',
        value => Statistics::R::REXP::List->new()},
    'empty_raw' => {
        desc => 'empty raw vector',
        expr => 'raw()',
        value => Statistics::R::REXP::Raw->new()},
    'empty_sym' => {
        desc => 'empty symbol',
        expr => 'bquote()',
        value => Statistics::R::REXP::Symbol->new()},
    'empty_expr' => {
        desc => 'empty expr',
        expr => 'expression()',
        value => Statistics::R::REXP::Expression->new()},
    'null' => {
        desc => 'null',
        expr => 'NULL',
        value => Statistics::R::REXP::Null->new()},
    'char_na' => {
        desc => 'char vector with NAs',
        expr => 'c("foo", "", NA, 23)',
        value => Statistics::R::REXP::Character->new([ 'foo', '', undef, '23' ]) },
    'num_na' => {
        desc => 'double vector with NAs',
        expr => 'c(11.3, NaN, -Inf, NA, 0)',
        value => ShortDoubleVector->new([ 11.3, nan, ninf, undef, 0 ]) },
    'int_na' => {
        desc => 'int vector with NAs',
        expr => 'c(11L, 0L, NA, 0L)',
        value => Statistics::R::REXP::Integer->new([ 11, 0, undef, 0 ]) },
    'lgl_na' => {
        desc => 'logical vector with NAs',
        expr => 'c(TRUE, FALSE, TRUE, NA)',
        value => Statistics::R::REXP::Logical->new([ 1, 0, 1, undef ]) },
    'list_na' => {
        desc => 'list with NAs',
        expr => 'list(1, 1L, list("b", list(letters[4:7], NA, c(44.1, NA)), list()))',
        value => Statistics::R::REXP::List->new([
            ShortDoubleVector->new([ 1 ]),
            Statistics::R::REXP::Integer->new([ 1 ]),
            Statistics::R::REXP::List->new([
                Statistics::R::REXP::Character->new(['b']),
                Statistics::R::REXP::List->new([
                    Statistics::R::REXP::Character->new(['d', 'e', 'f', 'g']),
                    Statistics::R::REXP::Logical->new([undef]),
                    ShortDoubleVector->new([44.1, undef]) ]),
                Statistics::R::REXP::List->new([]) ]) ]) },
    'list_null' => {
        desc => 'list with a single NULL',
        expr => 'list(NULL)',
        value => Statistics::R::REXP::List->new( [
            Statistics::R::REXP::Null->new() ]) },
    'pairlist_untagged' => {
        desc => 'a pairlist with no named elements',
        expr => 'as.pairlist(list(1L, 2L, 3L))',
        skip => 'rds',
        value => Statistics::R::REXP::List->new( [
            Statistics::R::REXP::Integer->new([ 1 ]),
            Statistics::R::REXP::Integer->new([ 2 ]),
            Statistics::R::REXP::Integer->new([ 3 ]),
        ])},
    'pairlist_tagged' => {
        desc => 'a pairlist with named elements',
        expr => 'as.pairlist(list(foo=1L, 2L, c=3L))',
        skip => 'rds',
        value => Statistics::R::REXP::List->new(
            elements => [
                Statistics::R::REXP::Integer->new([ 1 ]),
                Statistics::R::REXP::Integer->new([ 2 ]),
                Statistics::R::REXP::Integer->new([ 3 ]),
            ],
            attributes => {
                names => Statistics::R::REXP::Character->new(['foo', '', 'c'])
            })},
    'expr_null' => {
        desc => 'expression(NULL)',
        expr => 'expression(NULL)',
        value => Statistics::R::REXP::Expression->new([
            Statistics::R::REXP::Null->new()
        ])},
    'expr_int' => {
        desc => 'expression(42L)',
        expr => 'expression(42L)',
        value => Statistics::R::REXP::Expression->new([
            Statistics::R::REXP::Integer->new([42])
        ])},
    'expr_call' => {
        desc => 'expression(1+2)',
        expr => 'expression(1+2)',
        value => Statistics::R::REXP::Expression->new([
            Statistics::R::REXP::Language->new([
                Statistics::R::REXP::Symbol->new('+'),
                ShortDoubleVector->new([1]),
                ShortDoubleVector->new([2]) ])
        ])},
    'expr_many' => {
        desc => 'expression(u, v, 1+0:9)',
        expr => 'expression(u, v, 1+0:9)',
        value => Statistics::R::REXP::Expression->new([
            Statistics::R::REXP::Symbol->new('u'),
            Statistics::R::REXP::Symbol->new('v'),
            Statistics::R::REXP::Language->new([
                Statistics::R::REXP::Symbol->new('+'),
                ShortDoubleVector->new([1]),
                Statistics::R::REXP::Language->new([
                    Statistics::R::REXP::Symbol->new(':'),
                    ShortDoubleVector->new([0]),
                    ShortDoubleVector->new([9]) ])
            ])
        ])},
    'empty_clos' => {
        desc => 'function() {}',
        expr => 'function() {}',
        skip => 'webwork',
        value => ClosureLenientEnv->new(
            body => Statistics::R::REXP::Language->new(
                elements => [
                    Statistics::R::REXP::Symbol->new('{') ],
                attributes => {
                    srcfile => TEST_SRC_FILE->{empty_clos},
                    wholeSrcref => Statistics::R::REXP::Integer->new(
                        elements => [1, 0, 1, 14, 0, 14, 1, 1],
                        attributes => {
                            class => Statistics::R::REXP::Character->new(['srcref']),
                            srcfile => TEST_SRC_FILE->{empty_clos}}),
                    srcref => Statistics::R::REXP::List->new([
                        Statistics::R::REXP::Integer->new(
                            elements => [1, 13, 1, 13, 13, 13, 1, 1],
                            attributes => {
                                class => Statistics::R::REXP::Character->new(['srcref']),
                                srcfile => TEST_SRC_FILE->{empty_clos}}),
                    ])
                }),
            environment => Statistics::R::REXP::GlobalEnvironment->new(),
            attributes => {
                srcref => Statistics::R::REXP::Integer->new(
                    elements => [1, 2, 1, 14, 2, 14, 1, 1],
                    attributes => {
                        class => Statistics::R::REXP::Character->new(['srcref']),
                        srcfile => TEST_SRC_FILE->{empty_clos}})
            })
    },
    'clos_null' => {
        desc => 'function() NULL',
        expr => 'function() NULL',
        skip => 'webwork',
        value => ClosureLenientEnv->new(
            body => Statistics::R::REXP::Null->new,
            environment => Statistics::R::REXP::GlobalEnvironment->new(),
            attributes => {
                srcref => Statistics::R::REXP::Integer->new(
                    elements => [1, 2, 1, 16, 2, 16, 1, 1],
                    attributes => {
                        class => Statistics::R::REXP::Character->new(['srcref']),
                        srcfile => LenientSrcFile->new(
                            frame => {
                                Enc => Statistics::R::REXP::Character->new(['unknown']),
                                filename => Statistics::R::REXP::Character->new(['<text>']),
                                fixedNewlines => Statistics::R::REXP::Logical->new([1]),
                                isFile => Statistics::R::REXP::Logical->new([0]),
                                lines => Statistics::R::REXP::Character->new(['{function() NULL}']),
                                parseData => Statistics::R::REXP::Integer->new(
                                    elements => [
                                        1, 1, 1, 1, 1, 123, 1, 12, 1, 2, 1, 9, 1, 264,
                                        2, 9, 1, 10, 1, 10, 1, 40, 3, 9, 1, 11, 1, 11,
                                        1, 41, 4, 9, 1, 13, 1, 16, 1, 262, 5, 6, 1, 13,
                                        1, 16, 0, 77, 6, 9, 1, 17, 1, 17, 1, 125, 7, 12,
                                        1, 2, 1, 16, 0, 77, 9, 12, 1, 1, 1, 17, 0, 77, 12, 0],
                                    attributes => {
                                        class => Statistics::R::REXP::Character->new(['parseData']),
                                        dim => Statistics::R::REXP::Integer->new([8, 9]),
                                        text => Statistics::R::REXP::Character->new([
                                            '{', 'function', '(', ')', 'NULL', '', '}', '', '']),
                                        tokens => Statistics::R::REXP::Character->new([
                                            "'{'", 'FUNCTION', "'('", "')'", 'NULL_CONST', 'expr', "'}'", 'expr', 'expr']),
                                    }),
                                timestamp => Statistics::R::REXP::Double->new(
                                    elements => [12345],
                                    attributes => {
                                        class => Statistics::R::REXP::Character->new(['POSIXct', 'POSIXt']),
                                    }),
                                wd => Statistics::R::REXP::Character->new(['abcd'])
                            },
                            attributes => {
                                class => Statistics::R::REXP::Character->new(['srcfilecopy', 'srcfile'])
                            },
                            enclosure => Statistics::R::REXP::EmptyEnvironment->new)})
            })
    },
    'clos_int' => {
        desc => 'function() 1L',
        expr => 'function() 1L',
        skip => 'webwork',
        value => ClosureLenientEnv->new(
            body => Statistics::R::REXP::Integer->new([1]),
            environment => Statistics::R::REXP::GlobalEnvironment->new(),
            attributes => {
                srcref => Statistics::R::REXP::Integer->new(
                    elements => [1, 2, 1, 14, 2, 14, 1, 1],
                    attributes => {
                        class => Statistics::R::REXP::Character->new(['srcref']),
                        srcfile => LenientSrcFile->new(
                            frame => {
                                Enc => Statistics::R::REXP::Character->new(['unknown']),
                                filename => Statistics::R::REXP::Character->new(['<text>']),
                                fixedNewlines => Statistics::R::REXP::Logical->new([1]),
                                isFile => Statistics::R::REXP::Logical->new([0]),
                                lines => Statistics::R::REXP::Character->new(['{function() 1L}']),
                                parseData => Statistics::R::REXP::Integer->new(
                                    elements => [
                                        1, 1, 1, 1, 1, 123, 1, 12, 1, 2, 1, 9, 1, 264,
                                        2, 9, 1, 10, 1, 10, 1, 40, 3, 9, 1, 11, 1, 11,
                                        1, 41, 4, 9, 1, 13, 1, 14, 1, 261, 5, 6, 1, 13,
                                        1, 14, 0, 77, 6, 9, 1, 15, 1, 15, 1, 125, 7, 12,
                                        1, 2, 1, 14, 0, 77, 9, 12, 1, 1, 1, 15, 0, 77, 12, 0],
                                    attributes => {
                                        class => Statistics::R::REXP::Character->new(['parseData']),
                                        dim => Statistics::R::REXP::Integer->new([8, 9]),
                                        text => Statistics::R::REXP::Character->new([
                                            '{', 'function', '(', ')', '1L', '', '}', '', '']),
                                        tokens => Statistics::R::REXP::Character->new([
                                            "'{'", 'FUNCTION', "'('", "')'", 'NUM_CONST', 'expr', "'}'", 'expr', 'expr']),
                                    }),
                                timestamp => Statistics::R::REXP::Double->new(
                                    elements => [12345],
                                    attributes => {
                                        class => Statistics::R::REXP::Character->new(['POSIXct', 'POSIXt']),
                                    }),
                                wd => Statistics::R::REXP::Character->new(['abcd'])
                            },
                            attributes => {
                                class => Statistics::R::REXP::Character->new(['srcfilecopy', 'srcfile'])
                            },
                            enclosure => Statistics::R::REXP::EmptyEnvironment->new)})
            })
    },
    'clos_add' => {
        desc => 'function() 1+2',
        expr => 'function() 1+2',
        skip => 'webwork',
        value => ClosureLenientEnv->new(
            body => Statistics::R::REXP::Language->new([
                Statistics::R::REXP::Symbol->new('+'),
                ShortDoubleVector->new([1]),
                ShortDoubleVector->new([2]) ]),
            environment => Statistics::R::REXP::GlobalEnvironment->new(),
            attributes => {
                srcref => Statistics::R::REXP::Integer->new(
                    elements => [1, 2, 1, 15, 2, 15, 1, 1],
                    attributes => {
                        class => Statistics::R::REXP::Character->new(['srcref']),
                        srcfile => LenientSrcFile->new(
                            frame => {
                                Enc => Statistics::R::REXP::Character->new(['unknown']),
                                filename => Statistics::R::REXP::Character->new(['<text>']),
                                fixedNewlines => Statistics::R::REXP::Logical->new([1]),
                                isFile => Statistics::R::REXP::Logical->new([0]),
                                lines => Statistics::R::REXP::Character->new(['{function() 1+2}']),
                                parseData => Statistics::R::REXP::Integer->new(
                                    elements => [
                                        1, 1, 1, 1, 1, 123, 1, 16, 1, 2, 1, 9, 1, 264,
                                        2, 13, 1, 10, 1, 10, 1, 40, 3, 13, 1, 11, 1, 11,
                                        1, 41, 4, 13, 1, 13, 1, 13, 1, 261, 5, 6, 1, 13,
                                        1, 13, 0, 77, 6, 11, 1, 14, 1, 14, 1, 43, 7, 11,
                                        1, 15, 1, 15, 1, 261, 8, 9, 1, 15, 1, 15, 0, 77,
                                        9, 11, 1, 16, 1, 16, 1, 125, 10, 16, 1, 13, 1, 15,
                                        0, 77, 11, 13, 1, 2, 1, 15, 0, 77, 13, 16, 1, 1,
                                        1, 16, 0, 77, 16, 0 ],
                                    attributes => {
                                        class => Statistics::R::REXP::Character->new(['parseData']),
                                        dim => Statistics::R::REXP::Integer->new([8, 13]),
                                        text => Statistics::R::REXP::Character->new([
                                            '{', 'function', '(', ')', '1', '', '+', '2', '', '}', '', '', '']),
                                        tokens => Statistics::R::REXP::Character->new([
                                            "'{'", 'FUNCTION', "'('", "')'", 'NUM_CONST', 'expr',
                                            "'+'", 'NUM_CONST', 'expr', "'}'", 'expr', 'expr', 'expr']),
                                    }),
                                timestamp => Statistics::R::REXP::Double->new(
                                    elements => [12345],
                                    attributes => {
                                        class => Statistics::R::REXP::Character->new(['POSIXct', 'POSIXt']),
                                    }),
                                wd => Statistics::R::REXP::Character->new(['abcd'])
                            },
                            attributes => {
                                class => Statistics::R::REXP::Character->new(['srcfilecopy', 'srcfile'])
                            },
                            enclosure => Statistics::R::REXP::EmptyEnvironment->new)})
            })
    },
    'clos_args' => {
        desc => 'function(a, b) {a - b}',
        expr => 'function(a, b) {a - b}',
        skip => 'webwork',
        value => ClosureLenientEnv->new(
            args => ['a', 'b'],
            body => Statistics::R::REXP::Language->new(
                elements => [
                    Statistics::R::REXP::Symbol->new('{'),
                    Statistics::R::REXP::Language->new([
                        Statistics::R::REXP::Symbol->new('-'),
                        Statistics::R::REXP::Symbol->new('a'),
                        Statistics::R::REXP::Symbol->new('b') ])
                ],
                attributes => {
                    srcfile => TEST_SRC_FILE->{clos_args},
                    wholeSrcref => Statistics::R::REXP::Integer->new(
                        elements => [1, 0, 1, 23, 0, 23, 1, 1],
                        attributes => {
                            class => Statistics::R::REXP::Character->new(['srcref']),
                            srcfile => TEST_SRC_FILE->{clos_args}}),
                    srcref => Statistics::R::REXP::List->new([
                        Statistics::R::REXP::Integer->new(
                            elements => [1, 17, 1, 17, 17, 17, 1, 1],
                            attributes => {
                                class => Statistics::R::REXP::Character->new(['srcref']),
                                srcfile => TEST_SRC_FILE->{clos_args}}),
                        Statistics::R::REXP::Integer->new(
                            elements => [1, 18, 1, 22, 18, 22, 1, 1],
                            attributes => {
                                class => Statistics::R::REXP::Character->new(['srcref']),
                                srcfile => TEST_SRC_FILE->{clos_args}}),
                    ])
                }),
            environment => Statistics::R::REXP::GlobalEnvironment->new(),
            attributes => {
                srcref => Statistics::R::REXP::Integer->new(
                    elements => [1, 2, 1, 23, 2, 23, 1, 1],
                    attributes => {
                        class => Statistics::R::REXP::Character->new(['srcref']),
                        srcfile => TEST_SRC_FILE->{clos_args}})
            })
    },
    'clos_defaults' => {
        desc => 'function(a=3, b) {a + b * pi}',
        expr => 'function(a=3, b) {a + b * pi}',
        skip => 'webwork',
        value => ClosureLenientEnv->new(
            args => ['a', 'b'],
            defaults => [ShortDoubleVector->new([2]), undef],
            body => Statistics::R::REXP::Language->new(
                elements => [
                    Statistics::R::REXP::Symbol->new('{'),
                    Statistics::R::REXP::Language->new([
                        Statistics::R::REXP::Symbol->new('+'),
                        Statistics::R::REXP::Symbol->new('a'),
                        Statistics::R::REXP::Language->new([
                            Statistics::R::REXP::Symbol->new('*'),
                            Statistics::R::REXP::Symbol->new('b'),
                            Statistics::R::REXP::Symbol->new('pi')])
                        ])
                ],
                attributes => {
                    srcfile => TEST_SRC_FILE->{clos_defaults},
                    wholeSrcref => Statistics::R::REXP::Integer->new(
                        elements => [1, 0, 1, 30, 0, 30, 1, 1],
                        attributes => {
                            class => Statistics::R::REXP::Character->new(['srcref']),
                            srcfile => TEST_SRC_FILE->{clos_defaults}}),
                    srcref => Statistics::R::REXP::List->new([
                        Statistics::R::REXP::Integer->new(
                            elements => [1, 19, 1, 19, 19, 19, 1, 1],
                            attributes => {
                                class => Statistics::R::REXP::Character->new(['srcref']),
                                srcfile => TEST_SRC_FILE->{clos_defaults}}),
                        Statistics::R::REXP::Integer->new(
                            elements => [1, 20, 1, 29, 20, 29, 1, 1],
                            attributes => {
                                class => Statistics::R::REXP::Character->new(['srcref']),
                                srcfile => TEST_SRC_FILE->{clos_defaults}}),
                    ])
                }),
            environment => Statistics::R::REXP::GlobalEnvironment->new(),
            attributes => {
                srcref => Statistics::R::REXP::Integer->new(
                    elements => [1, 2, 1, 30, 2, 30, 1, 1],
                    attributes => {
                        class => Statistics::R::REXP::Character->new(['srcref']),
                        srcfile => TEST_SRC_FILE->{clos_defaults}})
            })
    },
    'clos_dots' => {
        desc => 'function(x=3, y, ...) {x * log(y) }',
        expr => 'function(x=3, y, ...) {x * log(y) }',
        skip => 'webwork',
        value => ClosureLenientEnv->new(
            args => ['x', 'y', '...'],
            defaults => [ShortDoubleVector->new([3]), undef, undef],
            body => Statistics::R::REXP::Language->new(
                elements => [
                    Statistics::R::REXP::Symbol->new('{'),
                    Statistics::R::REXP::Language->new([
                        Statistics::R::REXP::Symbol->new('*'),
                        Statistics::R::REXP::Symbol->new('x'),
                        Statistics::R::REXP::Language->new([
                            Statistics::R::REXP::Symbol->new('log'),
                            Statistics::R::REXP::Symbol->new('y')] ) ])
                ],
                attributes => {
                    srcfile => TEST_SRC_FILE->{clos_dots},
                    wholeSrcref => Statistics::R::REXP::Integer->new(
                        elements => [1, 0, 1, 36, 0, 36, 1, 1],
                        attributes => {
                            class => Statistics::R::REXP::Character->new(['srcref']),
                            srcfile => TEST_SRC_FILE->{clos_dots}}),
                    srcref => Statistics::R::REXP::List->new([
                        Statistics::R::REXP::Integer->new(
                            elements => [1, 24, 1, 24, 24, 24, 1, 1],
                            attributes => {
                                class => Statistics::R::REXP::Character->new(['srcref']),
                                srcfile => TEST_SRC_FILE->{clos_dots}}),
                        Statistics::R::REXP::Integer->new(
                            elements => [1, 25, 1, 34, 25, 34, 1, 1],
                            attributes => {
                                class => Statistics::R::REXP::Character->new(['srcref']),
                                srcfile => TEST_SRC_FILE->{clos_dots}}),
                    ])
                }),
            environment => Statistics::R::REXP::GlobalEnvironment->new(),
            attributes => {
                srcref => Statistics::R::REXP::Integer->new(
                    elements => [1, 2, 1, 36, 2, 36, 1, 1],
                    attributes => {
                        class => Statistics::R::REXP::Character->new(['srcref']),
                        srcfile => TEST_SRC_FILE->{clos_dots}})
            })
    },
    'baseenv' => {
        desc => 'baseenv()',
        expr => 'baseenv()',
        value => RexpOrUnknown->new(Statistics::R::REXP::BaseEnvironment->new),
    },
    'emptyenv' => {
        desc => 'emptyenv()',
        expr => 'emptyenv()',
        value => RexpOrUnknown->new(Statistics::R::REXP::EmptyEnvironment->new),
    },
    'globalenv' => {
        desc => 'globalenv()',
        expr => 'globalenv()',
        value => RexpOrUnknown->new(Statistics::R::REXP::GlobalEnvironment->new),
    },
    'env_attr' => {
        desc => 'environment with attributes',
        expr => 'local({ e <- new.env(parent=globalenv()); attributes(e) <- list(foo = "bar", fred = 1:3); e })',
        value => RexpOrUnknown->new(Statistics::R::REXP::Environment->new(
            enclosure => Statistics::R::REXP::GlobalEnvironment->new,
            attributes => {
                foo => Statistics::R::REXP::Character->new(['bar']),
                fred => Statistics::R::REXP::Integer->new([1, 2, 3]),
            })),
    },
    'empty_cpx' => {
        desc => 'empty complex vector',
        expr => 'complex()',
        value => Statistics::R::REXP::Complex->new()},
    'cpx_na' => {
        desc => 'complex vector with NAs',
        expr => 'c(1, NA_complex_, 3i, 0)',
        value => Statistics::R::REXP::Complex->new([1, undef, cplx(0, 3), 0])},
    'noatt-cpx' => {
        desc => 'scalar complex vector',
        expr => '3+2i',
        value => Statistics::R::REXP::Complex->new([cplx(3, 2)])},
    'foo-cpx' => {
        desc => 'complex vector with a name attribute',
        expr => 'c(foo=3+2i)',
        value => Statistics::R::REXP::Complex->new(
            elements => [ cplx(3, 2) ],
            attributes => {
                names => Statistics::R::REXP::Character->new(['foo'])
            },
        )},
    'cpx-1i' => {
        desc => 'imaginary-only complex vector',
        expr => '1i',
        value => Statistics::R::REXP::Complex->new([cplx(0, 1)])},
    'cpx-0i' => {
        desc => 'real-only empty complex vector',
        expr => '5+0i',
        value => Statistics::R::REXP::Complex->new([cplx(5)])},
    'cpx-vector' => {
        desc => 'simple complex vector',
        expr => 'complex(real=1:3, imaginary=4:6)',
        value => Statistics::R::REXP::Complex->new([cplx(1,4), cplx(2, 5), cplx(3, 6)])},
    'df_auto_rownames' => {
        desc => 'automatic compact rownames',
        expr => 'data.frame(a=1:3, b=c("x", "y", "z"), stringsAsFactors=FALSE)',
        value => Statistics::R::REXP::List->new(
            elements => [
                Statistics::R::REXP::Integer->new([ 1, 2, 3 ]),
                Statistics::R::REXP::Character->new([ 'x', 'y', 'z' ]),
            ],
            attributes => {
                names => Statistics::R::REXP::Character->new(['a', 'b']),
                class => Statistics::R::REXP::Character->new(['data.frame']),
                'row.names' => Statistics::R::REXP::Integer->new([1, 2, 3]),
            }
        )},
    'df_expl_rownames' => {
        desc => 'explicit compact rownames',
        expr => 'data.frame(a=1:3, b=c("x", "y", "z"), stringsAsFactors=FALSE)[1:3,]',
        value => Statistics::R::REXP::List->new(
            elements => [
                Statistics::R::REXP::Integer->new([ 1, 2, 3 ]),
                Statistics::R::REXP::Character->new([ 'x', 'y', 'z' ]),
            ],
            attributes => {
                names => Statistics::R::REXP::Character->new(['a', 'b']),
                class => Statistics::R::REXP::Character->new(['data.frame']),
                'row.names' => Statistics::R::REXP::Integer->new([1, 2, 3]),
            }
            )},
    's4' => {
        desc => 'S4 class',
        expr => 'local({
         library(methods)
         track <- setClass("track", slots = c(x="numeric", y="numeric"))
         t1 <- track(x = 1:4, y = 2:4 + 0)
         t1
        })',
        value => Statistics::R::REXP::S4->new(
            class => 'track',
            package => '.GlobalEnv',
            slots => {
                x => Statistics::R::REXP::Integer->new([1, 2, 3, 4]),
                y => ShortDoubleVector->new([2, 3, 4]),
            }),
    },
    's4_subclass' => {
        desc => 'S4 subclass',
        expr => 'local({
         library(methods)
         track <- setClass("track", slots = c(x="numeric", y="numeric"))
         t1 <- track(x = 1:4, y = 2:4 + 0)
         trackCurve <- setClass("trackCurve", slots = c(smooth = "numeric"), contains = "track")
         t1s <- trackCurve(t1, smooth = 1:3)
         t1s
        })',
        value => Statistics::R::REXP::S4->new(
            class => 'trackCurve',
            package => '.GlobalEnv',
            slots => {
                x => Statistics::R::REXP::Integer->new([1, 2, 3, 4]),
                y => ShortDoubleVector->new([2, 3, 4]),
                smooth => Statistics::R::REXP::Integer->new([1, 2, 3]),
            }),
    },
};

1;
