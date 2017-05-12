#!/usr/bin/env perl

# from https://github.com/Songmu/p5-Test-Requires-Scanner
use Const::Common 0.01 (
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
    WHITESPACE         => Compiler::Lexer::TokenType::T_WhiteSpace,

    LEFT_PAREN   => Compiler::Lexer::TokenType::T_LeftParenthesis,
    RIGHT_PAREN  => Compiler::Lexer::TokenType::T_RightParenthesis,
    LEFT_BRACE   => Compiler::Lexer::TokenType::T_LeftBrace,
    RIGHT_BRACE  => Compiler::Lexer::TokenType::T_RightBrace,
);
