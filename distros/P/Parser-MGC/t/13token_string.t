#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

package TestParser;
use base qw( Parser::MGC );

sub parse
{
   my $self = shift;

   return $self->token_string;
}

package StringPairParser;
use base qw( Parser::MGC );

sub parse
{
   my $self = shift;

   return [ $self->token_string, $self->token_string ];
}

package main;

my $parser = TestParser->new;

is( $parser->from_string( q['single'] ), "single", 'Single quoted string' );
is( $parser->from_string( q["double"] ), "double", 'Double quoted string' );

is( $parser->from_string( q["foo 'bar'"] ), "foo 'bar'", 'Double quoted string containing single substr' );
is( $parser->from_string( q['foo "bar"'] ), 'foo "bar"', 'Single quoted string containing double substr' );

is( $parser->from_string( q["tab \t"]       ), "tab \t",       '\t' );
is( $parser->from_string( q["newline \n"]   ), "newline \n",   '\n' );
is( $parser->from_string( q["return \r"]    ), "return \r",    '\r' );
is( $parser->from_string( q["form feed \f"] ), "form feed \f", '\f' );
is( $parser->from_string( q["backspace \b"] ), "backspace \b", '\b' );
is( $parser->from_string( q["bell \a"]      ), "bell \a",      '\a' );
is( $parser->from_string( q["escape \e"]    ), "escape \e",    '\e' );

# ord('A') == 65 == 0101 == 0x41 
#  TODO: This is ASCII dependent. If anyone on EBCDIC cares, do let me know...
is( $parser->from_string( q["null \0"] ),         "null \0",         'Octal null' );
is( $parser->from_string( q["octal \101BC"] ),    "octal ABC",       'Octal' );
is( $parser->from_string( q["hex \x41BC"] ),      "hex ABC",         'Hexadecimal' );
is( $parser->from_string( q["unihex \x{263a}"] ), "unihex \x{263a}", 'Unicode hex' );

$parser = TestParser->new(
   patterns => { string_delim => qr/"/ }
);

is( $parser->from_string( q["double"] ), "double", 'Double quoted string still passes' );
ok( !eval { $parser->from_string( q['single'] ) }, 'Single quoted string now fails' );

$parser = StringPairParser->new;

is_deeply( $parser->from_string( q["foo" "bar"] ),
           [ "foo", "bar" ],
           'String-matching pattern is non-greedy' );

done_testing;
