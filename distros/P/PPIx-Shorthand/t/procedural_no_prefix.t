#!/usr/bin/env perl

use utf8;
use 5.008001;

use strict;
use warnings;

use Readonly;

use version; our $VERSION = qv('v1.2.0');

use Test::More;

use PPIx::Shorthand qw< get_ppi_class >;

# Note that Structure is not included below because it doesn't have a
# unique base name.
Readonly my @NON_PREFIXED_CLASSES => qw<
    Element
        Node
        Document
            Document::Fragment
        Statement
            Statement::Package
            Statement::Include
            Statement::Sub
                Statement::Scheduled
            Statement::Compound
            Statement::Break
            Statement::Given
            Statement::When
            Statement::Data
            Statement::End
            Statement::Expression
                Statement::Variable
            Statement::Null
            Statement::UnmatchedBrace
            Statement::Unknown

            Structure::Block
            Structure::Subscript
            Structure::Constructor
            Structure::Condition
            Structure::List
            Structure::For
            Structure::Given
            Structure::When
            Structure::Unknown
        Token
        Token::Whitespace
        Token::Comment
        Token::Pod
        Token::Number
            Token::Number::Binary
            Token::Number::Octal
            Token::Number::Hex
            Token::Number::Float
                Token::Number::Exp
            Token::Number::Version
        Token::Word
        Token::DashedWord
        Token::Symbol
            Token::Magic
        Token::ArrayIndex
        Token::Operator
        Token::Quote
            Token::Quote::Single
            Token::Quote::Double
            Token::Quote::Literal
            Token::Quote::Interpolate
        Token::QuoteLike
            Token::QuoteLike::Backtick
            Token::QuoteLike::Command
            Token::QuoteLike::Regexp
            Token::QuoteLike::Words
            Token::QuoteLike::Readline
        Token::Regexp
            Token::Regexp::Match
            Token::Regexp::Substitute
            Token::Regexp::Transliterate
        Token::HereDoc
        Token::Cast
        Token::Structure
        Token::Label
        Token::Separator
        Token::Data
        Token::End
        Token::Prototype
        Token::Attribute
        Token::Unknown
>;

Readonly my @TRANSFORMS => (
    sub { return $_[0]         },
    sub { return lc $_[0]      },
    sub { return lcfirst $_[0] },
    sub { return uc $_[0]      },
    sub { return ucfirst $_[0] },
);


plan tests => @TRANSFORMS * @NON_PREFIXED_CLASSES;

foreach my $non_prefixed_class (@NON_PREFIXED_CLASSES) {
    foreach my $transform (@TRANSFORMS) {
        my $class = "PPI::$non_prefixed_class";
        my $transformed = $transform->($non_prefixed_class);

        is(
            get_ppi_class($transformed),
            $class,
            "$transformed should map to $class",
        );
    } # end foreach
} # end foreach


# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
