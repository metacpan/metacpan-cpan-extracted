#!/usr/bin/perl
#Copyright 2008 Arthur S Goldstein
use Test::More tests => 2;
  use Parse::Stallion;

   my %basic_grammar = (
    expression =>
     AND('number',
      qr/\s*\+\s*/,
      'number',
      EVALUATION(
       sub {return $_[0]->{number}->[0] + $_[0]->{number}->[1]})
    ),
    number => LEAF(qr/\d+/)
   );

   my $parser = new Parse::Stallion(\%basic_grammar);

   my $result = $parser->parse_and_evaluate('7+4');
   #$result should contain 11
   is ($result, 11, 'first');

   my %grammar_2 = (
    expression =>
     A('number',
      qr/\s*\+\s*/,
      {right_number => 'number'},
      E(sub {return $_[0]->{number} + $_[0]->{right_number}})
    ),
    number => L(qr/\d+/,
      EVALUATION(sub{return $_[0];}))
   );

   my $parser_2 = new Parse::Stallion(
   \%grammar_2, {start_rule => 'expression'});

   my $result_2 = $parser_2->parse_and_evaluate('8+5');
   #$result_2 should contain 13
   is ($result_2, 13, 'first');

print "\nAll done\n";
