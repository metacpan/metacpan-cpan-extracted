package Perl::PrereqScanner::Lite::Constants;
use strict;
use warnings;
use utf8;
use Compiler::Lexer::Constants;

use parent qw(Exporter);

our @EXPORT = qw(
    REQUIRE_DECL REQUIRED_NAME NAMESPACE_RESOLVER NAMESPACE
    SEMI_COLON USE_DECL USED_NAME REG_LIST REG_EXP LEFT_PAREN
    RIGHT_PAREN STRING RAW_STRING VERSION_STRING INT DOUBLE KEY
    METHOD WHITESPACE COMMENT LEFT_BRACE RIGHT_BRACE
    LEFT_BRACKET RIGHT_BRACKET BUILTIN_FUNC
    IF_STMT COMMA
);

use constant {
    REQUIRE_DECL       => Compiler::Lexer::TokenType::T_RequireDecl,
    REQUIRED_NAME      => Compiler::Lexer::TokenType::T_RequiredName,
    NAMESPACE_RESOLVER => Compiler::Lexer::TokenType::T_NamespaceResolver,
    NAMESPACE          => Compiler::Lexer::TokenType::T_Namespace,
    SEMI_COLON         => Compiler::Lexer::TokenType::T_SemiColon,
    USE_DECL           => Compiler::Lexer::TokenType::T_UseDecl,
    USED_NAME          => Compiler::Lexer::TokenType::T_UsedName,
    REG_LIST           => Compiler::Lexer::TokenType::T_RegList,
    REG_EXP            => Compiler::Lexer::TokenType::T_RegExp,
    STRING             => Compiler::Lexer::TokenType::T_String,
    RAW_STRING         => Compiler::Lexer::TokenType::T_RawString,
    VERSION_STRING     => Compiler::Lexer::TokenType::T_VersionString,
    INT                => Compiler::Lexer::TokenType::T_Int,
    DOUBLE             => Compiler::Lexer::TokenType::T_Double,
    KEY                => Compiler::Lexer::TokenType::T_Key,
    METHOD             => Compiler::Lexer::TokenType::T_Method,
    WHITESPACE         => Compiler::Lexer::TokenType::T_WhiteSpace,
    COMMENT            => Compiler::Lexer::TokenType::T_Comment,
    IF_STMT            => Compiler::Lexer::TokenType::T_IfStmt,
    COMMA              => Compiler::Lexer::TokenType::T_Comma,

    LEFT_PAREN   => Compiler::Lexer::TokenType::T_LeftParenthesis,
    RIGHT_PAREN  => Compiler::Lexer::TokenType::T_RightParenthesis,
    LEFT_BRACE   => Compiler::Lexer::TokenType::T_LeftBrace,
    RIGHT_BRACE   => Compiler::Lexer::TokenType::T_RightBrace,
    LEFT_BRACKET => Compiler::Lexer::TokenType::T_LeftBracket,
    RIGHT_BRACKET => Compiler::Lexer::TokenType::T_RightBracket,

    BUILTIN_FUNC => Compiler::Lexer::TokenType::T_BuiltinFunc,
};

1;

