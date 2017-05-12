#!/usr/bin/perl
#Copyright 2007 Arthur S Goldstein
use Test::More tests => 4;
BEGIN { use_ok('Parse::Stallion') };

my %calculator_rules = (
 start_expression => A(
   'expression', 'end_of_string',
   E(sub {return $_[0]->{expression}})
  )
,
 expression => A
   ('term',
    M(A('plus_or_minus', 'term')),
   E(sub {my $to_combine = $_[0]->{term};
    my $plus_or_minus = $_[0]->{plus_or_minus};
#use Data::Dumper; print STDERR "Parameters are ".Dumper(\@_)."\n";
    my $value = shift @$to_combine;
    for my $i (0..$#{$to_combine}) {
      if ($plus_or_minus->[$i] eq '+') {
        $value += $to_combine->[$i];
      }
      else {
        $value -= $to_combine->[$i];
      }
    }
    return $value;
   })
  ),
,
 term =>
   A('factor', 
    M(A('times_or_divide_or_modulo', 'factor')),
   E(sub {my $to_combine = $_[0]->{factor};
    my $times_or_divide_or_modulo = $_[0]->{times_or_divide_or_modulo};
    my $value = shift @$to_combine;
    for my $i (0..$#{$to_combine}) {
      if ($times_or_divide_or_modulo->[$i] eq '*') {
        $value *= $to_combine->[$i];
      }
      elsif ($times_or_divide_or_modulo->[$i] eq '%') {
        $value = $value % $to_combine->[$i];
      }
      else {
#could check for zero
        $value /= $to_combine->[$i];
      }
    }
    return $value;
   })
  )
,
 factor => A(
   'fin_exp', 
    M(A('power_of', 'fin_exp')),
   E(sub {my $to_combine = $_[0]->{fin_exp};
    my $value = pop @$to_combine;
    while ($#{$to_combine} > -1) {
      $value = (pop @$to_combine) ** $value;
    }
    return $value;
   })
  ),
,
fin_exp =>
  OR(
    AND('left_parenthesis', 'expression', 'right_parenthesis',
     EVALUATION(sub {return $_[0]->{expression} })
    ),
    AND('number',
     EVALUATION(sub {return $_[0]->{number} })
    ),
   ),
,
end_of_string => qr/\z/
,
number => qr/\s*[+-]?(\d+(\.\d*)?|\.\d+)\s*/,
,
left_parenthesis => qr/\s*\(\s*/
,
right_parenthesis => qr/\s*\)\s*/
,
power_of => qr/\s*\*\*\s*/
,
plus_or_minus => OR('plus', 'minus')
,
plus => qr/\s*\+\s*/
,
minus => qr/\s*\-\s*/
,
times_or_divide_or_modulo =>
  OR('times', 'divided_by', 'modulo')
,
modulo => qr/\s*\%\s*/
,
times => qr/\s*\*\s*/
,
divided_by => qr/\s*\/\s*/
,
);

my $calculator_parser = new Parse::Stallion(
  \%calculator_rules,
  {start_rule => 'start_expression'});

my $result =
 $calculator_parser->parse_and_evaluate("7+4");
print "Result is $result\n";
is ($result, 11, "simple plus");


$result =
 $calculator_parser->parse_and_evaluate("7*4");
print "Result is $result\n";
is ($result, 28, "simple multiply");

$result =
 $calculator_parser->parse_and_evaluate("3+7*4");
print "Result is $result\n";
is ($result, 31, "simple plus and multiply");


print "\nAll done\n";


