#!/usr/bin/perl
#Copyright 2007-8 Arthur S Goldstein
use Test::More tests => 7;
BEGIN { use_ok('Parse::Stallion') };

my %calculator_rules = (
 start_expression => A(
   'expression', 'end_of_string')
,
 expression => A(
   'term', 
    M(A('plus_or_minus', 'term'))
 )
,
 term => A(
   'factor', 
    (M(A('times_or_divide_or_modulo', 'factor')))
  ),
,
 factor => AND(
   'fin_exp', 
    MULTIPLE(AND('power_of', 'fin_exp')))
,
fin_exp => OR(
    AND('left_parenthesis', 'expression', 'right_parenthesis'),
    AND('number'))
,
end_of_string => LEAF(
  qr/\z/)
,
number => LEAF(
  qr/\s*[+-]?(\d+(\.\d*)?|\.\d+)\s*/
 )
,
left_parenthesis => LEAF(
  qr/\s*\(\s*/)
,
right_parenthesis => LEAF(
  qr/\s*\)\s*/
 )
,
power_of => LEAF(
  qr/\s*\*\*\s*/
 )
,
plus_or_minus => OR(
  'plus', 'minus'
 )
,
plus => LEAF(
  qr/\s*\+\s*/)
,
minus => LEAF(
  qr/\s*\-\s*/
 )
,
times_or_divide_or_modulo => 
  OR('times', 'divided_by', 'modulo')
,
modulo => LEAF(
  qr/\s*\%\s*/)
,
times => LEAF(
  qr/\s*\*\s*/
 )
,
divided_by => LEAF(
  qr/\s*\/\s*/
 )
,
);

my $calculator_parser = new Parse::Stallion(
 \%calculator_rules,
 {do_not_compress_eval => 1,
  start_rule=> 'start_expression'});

my $result =
 $calculator_parser->parse_and_evaluate("7+4");
#use Data::Dumper;print "result is ".Dumper($result)."\n";
is_deeply ($result, 
{                            
          'end_of_string' => '',
          'expression' => {
                            'plus_or_minus' => [
                                                 {
                                                   'plus' => '+'
                                                 }
                                               ],
                            'term' => [
                                        {
                                          'factor' => [
                                                        {
                                                          'fin_exp' => [
                                                                         {
                                                                           'number' => '7'
                                                                         }
                                                                       ]
                                                        }
                                                      ]
                                        },
                                        {
                                          'factor' => [
                                                        {
                                                          'fin_exp' => [
                                                                         {
                                                                           'number' => '4'
                                                                         }
                                                                       ]
                                                        }
                                                      ]
                                        }
                                      ]
                          }
        }
, "simple plus");


my %simp_calculator_rules = (
 start_expression => 
   AND('expression')
,
 expression => AND(
   'number', 
    MULTIPLE( AND({plus=>LEAF(qr/\s*\+\s*/)}, 'number')))
,
number => LEAF(
  qr/\d*/
 ),
,
);

#print STDERR "before sett scr are ".Dumper(\%simp_calculator_rules)."\n";
#print STDERR "setting simp\n";
my $simp_calculator_parser =
 new Parse::Stallion(
  \%simp_calculator_rules,
  {do_not_compress_eval => 1,
  start_rule => 'start_expression'});

$result =
 $simp_calculator_parser->
  parse_and_evaluate("7+4");
#use Data::Dumper;print STDERR "1 result is ".Dumper($result)."\n";

is_deeply($result,
{                            
          'expression' => {
                            'plus' => [
                                        '+'
                                      ],
                            'number' => [
                                          '7',
                                          '4'
                                        ]
                          }
        }
,'simple calc');

#print STDERR "setting n simp\n";
my $n_simp_calculator_parser =
 new Parse::Stallion(
  \%simp_calculator_rules,
  {do_not_compress_eval => 0,
   start_rule => 'start_expression'});

#print STDERR "after sett scr are ".Dumper(\%simp_calculator_rules)."\n";

$result =
 $n_simp_calculator_parser->
  parse_and_evaluate("7+4");
#use Data::Dumper;print STDERR "result is ".Dumper($result)."\n";

is_deeply($result,
{                            
                            'plus' => [
                                        '+'
                                      ],
                            'number' => [
                                          '7',
                                          '4'
                                        ]
        }
,'simple calc n');

#print STDERR "setting de simp\n";
my $de_simp_calculator_parser =
 new Parse::Stallion(
  \%simp_calculator_rules,
  {do_not_compress_eval => 1,
  do_evaluation_in_parsing => 1,
  start_rule => 'start_expression'});

$result =
 $de_simp_calculator_parser->
  parse_and_evaluate("7+4");
#use Data::Dumper;print STDERR "de 1 result is ".Dumper($result)."\n";

is_deeply($result,
{                            
          'expression' => {
                            'plus' => [
                                        '+'
                                      ],
                            'number' => [
                                          '7',
                                          '4'
                                        ]
                          }
        }
,'de simple calc');

#print STDERR "setting de n simp\n";
my $de_n_simp_calculator_parser =
 new Parse::Stallion(
  \%simp_calculator_rules,
  {do_not_compress_eval => 0,
  do_evaluation_in_parsing => 1,
  start_rule => 'start_expression'});

$result =
 $de_n_simp_calculator_parser->
  parse_and_evaluate("7+4");
#use Data::Dumper;print STDERR "de result is ".Dumper($result)."\n";

is_deeply($result,
{                            
                            'plus' => [
                                        '+'
                                      ],
                            'number' => [
                                          '7',
                                          '4'
                                        ]
        }
,'de simple calc n');

$result =
 $de_n_simp_calculator_parser->
  parse_and_evaluate("7+4 + 5");
#use Data::Dumper;print STDERR "de mc result is ".Dumper($result)."\n";

is_deeply($result,
{                            
                            'plus' => [
                                        '+',
                                        ' + '
                                      ],
                            'number' => [
                                          '7',
                                          '4',
                                          '5'
                                        ]
        }
,'de simple calc n more complicated');
