#!/usr/bin/perl
#Copyright 2007-8 Arthur S Goldstein
use Parse::Stallion;

my %calculator_rules = (
 start_expression => A(
   'expression', 'end_of_string',
   E(sub {return $_[0]->{expression}})
  )
,
 expression =>
   A('term', 
    M(A('plus_or_minus', 'term')),
    E(sub {my $to_combine = $_[0]->{term};
    my $plus_or_minus = $_[0]->{plus_or_minus};
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
    M (A('times_or_divide_or_modulo', 'factor')),
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
  ),
,
 factor =>
   A('fin_exp', 
    M (A( 'power_of', 'fin_exp')),
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
  O(A('left_parenthesis', 'expression', 'right_parenthesis',
     E(sub {return $_[0]->{expression} })
    ),
    A('number',
     E(sub {return $_[0]->{number} })
    ),
   )
,
end_of_string => qr/\z/,
number => qr/\s*[+-]?(\d+(\.\d*)?|\.\d+)\s*/,
,
left_parenthesis => qr/\s*(\()\s*/,
right_parenthesis => qr/\s*(\))\s*/,
power_of => qr/\s*(\*\*)\s*/,
plus_or_minus =>
  O('plus', 'minus'),
plus => qr/\s*(\+)\s*/,
minus => qr/\s*(\-)\s*/,
times_or_divide_or_modulo =>
  O('times', 'divided_by', 'modulo')
,
modulo => qr/\s*(\%)\s*/,
times => qr/\s*(\*)\s*/,
divided_by => qr/\s*(\/)\s*/
);

my $calculator_parser = new Parse::Stallion(\%calculator_rules);
#$calculator_parser->generate_evaluate_subroutines;

my $result = $calculator_parser->parse_and_evaluate("7+4");
print "should be 11, result is $result\n";

$result = $calculator_parser->parse_and_evaluate("7*4");
print "should be 28, Result is $result\n";

$result = $calculator_parser->parse_and_evaluate("3+7*4");
print "should be 31, result is $result\n";

$result = $calculator_parser->parse_and_evaluate("3+-+7*4",{parse_info=>$parse_info = {}});

print "should be 0, Parse succeeded: ".$parse_info->{parse_succeeded}."\n";

print "\nAll done\n";


