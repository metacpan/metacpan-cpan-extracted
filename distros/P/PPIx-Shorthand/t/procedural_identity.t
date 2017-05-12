#!/usr/bin/env perl

use utf8;
use 5.008001;

use strict;
use warnings;

use Readonly;

use version; our $VERSION = qv('v1.2.0');

use Test::More;

use PPIx::Shorthand qw< get_ppi_class >;

Readonly my @CLASSES => qw<
   PPI::Element
      PPI::Node
         PPI::Document
            PPI::Document::Fragment
         PPI::Statement
            PPI::Statement::Package
            PPI::Statement::Include
            PPI::Statement::Sub
               PPI::Statement::Scheduled
            PPI::Statement::Compound
            PPI::Statement::Break
            PPI::Statement::Given
            PPI::Statement::When
            PPI::Statement::Data
            PPI::Statement::End
            PPI::Statement::Expression
               PPI::Statement::Variable
            PPI::Statement::Null
            PPI::Statement::UnmatchedBrace
            PPI::Statement::Unknown
         PPI::Structure
            PPI::Structure::Block
            PPI::Structure::Subscript
            PPI::Structure::Constructor
            PPI::Structure::Condition
            PPI::Structure::List
            PPI::Structure::For
            PPI::Structure::Given
            PPI::Structure::When
            PPI::Structure::Unknown
      PPI::Token
         PPI::Token::Whitespace
         PPI::Token::Comment
         PPI::Token::Pod
         PPI::Token::Number
            PPI::Token::Number::Binary
            PPI::Token::Number::Octal
            PPI::Token::Number::Hex
            PPI::Token::Number::Float
               PPI::Token::Number::Exp
            PPI::Token::Number::Version
         PPI::Token::Word
         PPI::Token::DashedWord
         PPI::Token::Symbol
            PPI::Token::Magic
         PPI::Token::ArrayIndex
         PPI::Token::Operator
         PPI::Token::Quote
            PPI::Token::Quote::Single
            PPI::Token::Quote::Double
            PPI::Token::Quote::Literal
            PPI::Token::Quote::Interpolate
         PPI::Token::QuoteLike
            PPI::Token::QuoteLike::Backtick
            PPI::Token::QuoteLike::Command
            PPI::Token::QuoteLike::Regexp
            PPI::Token::QuoteLike::Words
            PPI::Token::QuoteLike::Readline
         PPI::Token::Regexp
            PPI::Token::Regexp::Match
            PPI::Token::Regexp::Substitute
            PPI::Token::Regexp::Transliterate
         PPI::Token::HereDoc
         PPI::Token::Cast
         PPI::Token::Structure
         PPI::Token::Label
         PPI::Token::Separator
         PPI::Token::Data
         PPI::Token::End
         PPI::Token::Prototype
         PPI::Token::Attribute
         PPI::Token::Unknown
>;

Readonly my @TRANSFORMS => (
    sub { return $_[0]         },
    sub { return lc $_[0]      },
    sub { return lcfirst $_[0] },
    sub { return uc $_[0]      },
    sub { return ucfirst $_[0] },
);


plan tests => @TRANSFORMS * @CLASSES;

foreach my $class (@CLASSES) {
    foreach my $transform (@TRANSFORMS) {
        my $transformed = $transform->($class);

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
