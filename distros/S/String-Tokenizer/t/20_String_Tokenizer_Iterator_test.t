#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 100;

BEGIN { 
    use_ok('String::Tokenizer') 
};

# first check that our inner class 
# cannot be called from outside
eval {
    String::Tokenizer::Iterator->new();
};
like($@, qr/Insufficient Access Priviledges/, '... this should have died');

# it can also parse reasonably well formated perl code  
my $STRING = <<STRING_TO_TOKENIZE;
sub test {
    my (\$arg) = \@_;
	if (\$arg == 10){
		return 1;
	}
	return 0;
}

STRING_TO_TOKENIZE

my @expected = qw(sub test { my ( $arg ) = @_ ; if ( $arg == 10 ) { return 1 ; } return 0 ; });

my $st = String::Tokenizer->new($STRING, '();{}');
isa_ok($st, "String::Tokenizer");  

can_ok("String::Tokenizer::Iterator", 'new');

my $i = $st->iterator();
isa_ok($i, "String::Tokenizer::Iterator");

can_ok($i, 'reset');
can_ok($i, 'hasNextToken');
can_ok($i, 'hasPrevToken');
can_ok($i, 'nextToken');
can_ok($i, 'prevToken');
can_ok($i, 'currentToken');
can_ok($i, 'lookAheadToken');
can_ok($i, 'skipToken');
can_ok($i, 'skipTokens');
can_ok($i, 'skipTokensUntil');
can_ok($i, 'collectTokensUntil');

my @iterator_output;
push @iterator_output => $i->nextToken() while $i->hasNextToken();

ok(!defined($i->nextToken()), '... this is undefined');
ok(!defined($i->lookAheadToken()), '... this is undefined');

is_deeply(
    \@iterator_output,
    \@expected,
    '... this is the output we would expect'); 
  
my @reverse_iterator_output;
push @reverse_iterator_output => $i->prevToken() while $i->hasPrevToken();  

ok(!defined($i->prevToken()), '... this is undefined');
ok(!defined($i->lookAheadToken()), '... this is undefined');
  
is_deeply(
    \@reverse_iterator_output,
    [ reverse @expected ],
    '... this is the output we would expect'); 

my $look_ahead;
while ($i->hasNextToken()) {  
    my $next = $i->nextToken();
    my $current = $i->currentToken();
    is($look_ahead, $next, '... our look ahead matches out next') if defined $look_ahead;
    is($current, $next, '... our current matches out next');
    $look_ahead = $i->lookAheadToken();  
}

$i->reset();
            
my @expected5 = qw({ ( ) @_ if $arg 10 { 1 } 0 });              
  
my @skip_output;
$i->skipTokens(2); 
while ($i->hasNextToken()) {
    push @skip_output => $i->nextToken();
    $i->skipToken();    
}

is_deeply(
        \@skip_output,
        \@expected5,
        '... this is the output we would expect');  
  
# test the skipTokensUntil and collectTokensUntil function with a double quoted string

{
    my $st = String::Tokenizer->new('this "is a good way" to "test a double quoted" string' , '"');
    isa_ok($st, "String::Tokenizer");  
        
    my $i = $st->iterator();
    
    isa_ok($i, "String::Tokenizer::Iterator");  

    is($i->nextToken(), 'this', '... got the right start token');
    ok($i->skipTokensUntil('"'), '... this will successfully skip');
    is($i->nextToken(), 'is', '... got the right token next expected');
    ok($i->skipTokensUntil('"'), '... this will successfully skip');
    is($i->nextToken(), 'to', '... got the right token next expected');
    is($i->nextToken(), '"', '... got the right token next expected');    
    is_deeply(
        [ $i->collectTokensUntil('"') ],
        [ qw/test a double quoted/ ],
        '... got the collection we expected');
    is($i->nextToken(), 'string', '... got the right token next expected');      
}

{
    my $st = String::Tokenizer->new('this "is a good way" to "test a double quoted" string' , '"');
    isa_ok($st, "String::Tokenizer");  
        
    my $i = $st->iterator();
    
    isa_ok($i, "String::Tokenizer::Iterator");  

    is($i->nextToken(), 'this', '... got the right start token');
    ok(!$i->skipTokensUntil('?'), '... this will not successfully match and so not skip');   
    is_deeply(
        [ $i->collectTokensUntil('"') ],
        [ ],
        '... got the collection (or lack thereof) we expected');
    is_deeply(
        [ $i->collectTokensUntil('"') ],
        [ qw/is a good way/ ],
        '... got the collection (or lack thereof) we expected');
    is($i->nextToken(), 'to', '... got the right token next expected'); 
    is_deeply(
        [ $i->collectTokensUntil('not found') ],
        [ ],
        '... got the collection (or lack thereof) we expected');    
    is($i->nextToken(), '"', '... got the right token next expected');                          
}

{
    my $st = String::Tokenizer->new(
                    'this is "a     good way" to "test a   double quoted  " string' , 
                    '"', 
                    String::Tokenizer->RETAIN_WHITESPACE
                    );
    isa_ok($st, "String::Tokenizer");  
        
    my $i = $st->iterator();
    
    isa_ok($i, "String::Tokenizer::Iterator");  

    is($i->nextToken(), 'this', '... got the right start token');
    $i->skipTokenIfWhitespace();
    is($i->lookAheadToken(), 'is', '... got the right start token');
    $i->skipTokenIfWhitespace();
    is($i->nextToken(), 'is', '... got the right start token');    
    $i->skipTokenIfWhitespace();
    is($i->nextToken(), '"', '... got the right start token');
    
    is_deeply(
        [ $i->collectTokensUntil('"') ],
        [ "a", "     ", "good", " ", "way" ],
        '... got the collection (or lack thereof) we expected');
        
    is($i->lookAheadToken(), ' ', '... our next token is whitespace');
    $i->skipTokenIfWhitespace();    
    is($i->nextToken(), 'to', '... got the right token next expected'); 
    
    # this is enough for now, we dont need to test the rest of the string
}
  