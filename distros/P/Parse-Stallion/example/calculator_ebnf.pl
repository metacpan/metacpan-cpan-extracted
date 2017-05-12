#!/usr/bin/perl
#Copyright 2009 Arthur S Goldstein
use Parse::Stallion::EBNF;

my $calculator=<<'END';

 start_expression = expression;

 expression = (term {plus_or_minus term})
  S{my $value = shift @$term;
    for my $i (0..$#{$term}) {
      if ($plus_or_minus->[$i] eq '+') {
        $value += $term->[$i];
      }
      else {
        $value -= $term->[$i];
      }
    }
    return $value;}S ;

 term = (factor {times_or_divide_or_modulo factor})
  S{my $value = shift @$factor;
    for my $i (0..$#{$factor}) {
      if ($times_or_divide_or_modulo->[$i] eq '*') {
        $value *= $factor->[$i];
      }
      elsif ($times_or_divide_or_modulo->[$i] eq '%') {
        $value = $value % $factor->[$i];
      }
      else {
#could check for zero
        $value /= $factor->[$i];
      }
    }
    return $value;
   }S ;

 factor = (fin_exp {power_of fin_exp})
    S{
    my $value = pop @$fin_exp;
    while ($#{$fin_exp} > -1) {
      $value = (pop @$fin_exp) ** $value;
    }
    return $value;
   }S ;

 fin_exp = 
   ((left_parenthesis expression right_parenthesis) S{$expression}S)
    | ((number) S{$number}S) ;

 number =
  (qr/\s*[+-]?(\d+(\.\d*)?|\.\d+)\s*/) S{return $_}S;

 left_parenthesis = qr/\s*\(\s*/;

 right_parenthesis = qr/\s*\)\s*/;

 power_of = qr/\s*\*\*\s*/;

 plus_or_minus = qr/\s*([-+])\s*/;

 times_or_divide_or_modulo = qr.\s*([\*/])\s*.;
END

my $calculator_parser = ebnf_new Parse::Stallion::EBNF($calculator);

my $result = $calculator_parser->parse_and_evaluate("7+4");
print "should be 11, result is $result\n";

$result = $calculator_parser->parse_and_evaluate("7 *4");
print "should be 28, Result is $result\n";

$result = $calculator_parser->parse_and_evaluate("3 + 7*4*2+5");
print "should be 64, result is $result\n";

$result = $calculator_parser->parse_and_evaluate(
 "(6** 3) * 5 + 7*4*2+1 * (9-8)");
print "should be 1137, result is $result\n";

$result = $calculator_parser->parse_and_evaluate("3+-+7*4",{parse_info=>$parse_info = {}});

print "should be 0, Parse succeeded: ".$parse_info->{parse_succeeded}."\n";

print "\nAll done\n";


