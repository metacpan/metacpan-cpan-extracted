use strict;
use warnings;
use Parse::RecDescent;
use Test::More tests => 2;

my $grammar = <<'END_OF_GRAMMAR';
    lex:             token(s)
    token:           'reject' <reject> { print "REJECT";} | identifier | include
    include:         /#\s*include\s+/ identifier { $text = $::includes->{$item[2]} . $text;
                                                   $return = "INCLUDED_$item[2]"; }
    identifier:      /[a-z_]\w*/i
END_OF_GRAMMAR

our $includes = {
    inc_0 => "\nSome included\n tokens\n\n",
    inc_1 => " And some without newlines",
    inc_2 => "more includes here",
    inc_3 => 'post reject',
};

my $text = <<'END_OF_TEXT';
some tokens

#include inc_0

other tokens

#include inc_1

#include inc_2

yet more tokens

#include inc_3

reject

another value

END_OF_TEXT

my $parser = Parse::RecDescent->new($grammar);
ok($parser, 'got a parser');

my $parse = $parser->lex($text);
is_deeply $parser->lex($text), [
    qw(some tokens
       INCLUDED_inc_0
       Some included tokens
       other tokens
       INCLUDED_inc_1
       And some without newlines
       INCLUDED_inc_2
       more includes here
       yet more tokens
       INCLUDED_inc_3
       post reject
       reject
       another value
   )] => 'text modification ok';
