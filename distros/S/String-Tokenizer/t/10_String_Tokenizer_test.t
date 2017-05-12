#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 17;

BEGIN { 
    use_ok('String::Tokenizer') 
};

can_ok("String::Tokenizer", 'new');

{
    my $st = String::Tokenizer->new();
    isa_ok($st, 'String::Tokenizer');
    
    can_ok($st, 'tokenize');
    can_ok($st, 'getTokens');
    can_ok($st, 'iterator');
}

# parse a nested expression
my $STRING1 = "((5 + 10)-100) * (15 + (23 / 300))";

# expected output with no delimiters
{
    my $st = String::Tokenizer->new();
    isa_ok($st, 'String::Tokenizer');
        
    $st->tokenize($STRING1);

    my @expected = qw{((5 + 10)-100) * (15 + (23 / 300))};

    is_deeply(
        scalar $st->getTokens(),
        \@expected,
        '... this is the output we would expect');
}

# expected output with () as delimiters
{
    my $st = String::Tokenizer->new();
    isa_ok($st, 'String::Tokenizer');    
    $st->tokenize($STRING1, '()');

    my @expected = qw{( ( 5 + 10 ) -100 ) * ( 15 + ( 23 / 300 ) )};

    is_deeply(
        [ $st->getTokens() ],
        \@expected,
        '... this is the output we would expect');
}
  
# expected output with ()+-*/ as delimiters  
{
    my $st = String::Tokenizer->new($STRING1, '()=-*/');
    isa_ok($st, 'String::Tokenizer');    
    
    my @expected = qw{( ( 5 + 10 ) - 100 ) * ( 15 + ( 23 / 300 ) )};
    
    is_deeply(
        scalar $st->getTokens(),
        \@expected,
        '... this is the output we would expect');  
}

# it can also parse reasonably well formated perl code  
my $STRING2 = <<STRING_TO_TOKENIZE;
sub test {
    my (\$arg) = \@_;
	if (\$arg == 10){
		return 1;
	}
	return 0;
}
STRING_TO_TOKENIZE

# parse without whitespace
{
    my $st = String::Tokenizer->new($STRING2, '();{}');
    isa_ok($st, 'String::Tokenizer');
    
    my @expected = qw(sub test { my ( $arg ) = @_ ; if ( $arg == 10 ) { return 1 ; } return 0 ; });
    
    is_deeply(
        scalar $st->getTokens(),
        \@expected,
        '... this is the output we would expect'); 
}

# check keeping all whitespace
{
    my $st = String::Tokenizer->new($STRING2, '();{}', String::Tokenizer->RETAIN_WHITESPACE);
    isa_ok($st, 'String::Tokenizer');
    
    my @expected = (
    'sub', ' ', 'test', ' ', '{', 
    "\n    ", 'my', ' ', '(', '$arg', ')', ' ', '=', ' ', '@_', ';',
    "\n	", 'if', ' ',  '(', '$arg', ' ', '==', ' ', '10', ')', '{',
    "\n		", 'return', ' ', '1', ';',
    "\n	", '}',
    "\n	", 'return', ' ', '0', ';', "\n",
    '}', "\n"
    );
    
    is_deeply(
        scalar $st->getTokens(),
        \@expected,
        '... this is the output we would expect'); 
        
    $st->handleWhitespace(String::Tokenizer->IGNORE_WHITESPACE);
    $st->tokenize($STRING2);
        
    my @expected2 = qw(sub test { my ( $arg ) = @_ ; if ( $arg == 10 ) { return 1 ; } return 0 ; });
    
    is_deeply(
        scalar $st->getTokens(),
        \@expected2,
        '... this is the output we would expect after changing whitespace handling');         
}
