#!/usr/bin/perl
#Copyright 2007 Arthur S Goldstein
use Test::More tests => 7;
BEGIN { use_ok('Parse::Stallion') };

my %calculator_rules = (
 start_expression => AND(
   'expression', 'end_of_string',
   EVALUATION(sub {return $_[0]->{expression}})
  )
,
 expression => AND(
   'term', 
    MULTIPLE(AND('plus_or_minus', 'term')),
   EVALUATION (sub {my $to_combine = $_[0]->{term};
#use Data::Dumper;print STDERR "to expression is ".Dumper(\@_)."\n";
    my $plus_or_minus = $_[0]->{plus_or_minus};
    my $value = shift @$to_combine;
#print STDERR "to combine count ".$#{$to_combine}."\n";
    for my $i (0..$#{$to_combine}) {
      if ($plus_or_minus->[$i] eq '+') {
        $value += $to_combine->[$i];
      }
      else {
        $value -= $to_combine->[$i];
      }
#print STDERR "I is $i and v $value\n";
    }
    return $value;}
   )
  )
,
 term => AND(
   'factor', 
    MULTIPLE(AND('times_or_divide_or_modulo', 'factor')),
   EVALUATION(sub {my $to_combine = $_[0]->{factor};
#use Data::Dumper;print STDERR "to term is ".Dumper(\@_)."\n";
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
   },
  )),
,
 factor => AND(
   'fin_exp', 
    MULTIPLE( AND('power_of', 'fin_exp')),
   EVALUATION (sub {my $to_combine = $_[0]->{fin_exp};
#use Data::Dumper;print STDERR "to factor is ".Dumper(\@_)."\n";
    my $value = pop @$to_combine;
    while ($#{$to_combine} > -1) {
      $value = (pop @$to_combine) ** $value;
    }
    return $value;
   },
  )),
,
fin_exp => OR(
    AND('left_parenthesis', 'expression', 'right_parenthesis',
     EVALUATION(sub {
#use Data::Dumper;print STDERR "to fin_exp1 is ".Dumper(\@_)."\n";
return $_[0]->{expression} })),
    AND('number',
     EVALUATION(sub {
#use Data::Dumper;print STDERR "to fin_exp2 is ".Dumper(\@_)."\n";
return $_[0]->{number} }),
    ),
   )
,
end_of_string => LEAF(
  qr/\z/
 )
,
number => LEAF(
  qr/\s*[+-]?(\d+(\.\d*)?|\.\d+)\s*/,
  EVALUATION( sub{
#use Data::Dumper;print STDERR "to number is ".Dumper(\@_)."\n";
   return $_[0];
  }
 ))
,
left_parenthesis => LEAF(
  qr/\s*(\()\s*/, )
,
right_parenthesis => LEAF(
  qr/\s*(\))\s*/, 
 )
,
power_of => LEAF(
  qr/\s*\*\*\s*/, E('**')
 ),
,
plus_or_minus => OR(
  'plus', 'minus'
 )
,
plus => qr/\s*(\+)\s*/,
minus => LEAF(
  qr/\s*\-\s*/, E('-')
 ),
,
times_or_divide_or_modulo => OR(
  'times', 'divided_by', 'modulo'
 )
,
modulo => LEAF(
  qr/\s*\%\s*/, E('%')
 )
,
times => LEAF(
  qr/\s*\*\s*/, E('*')
 )
,
divided_by => LEAF(
  qr/\s*\/\s*/, E('/')
 )
,
);

my $calculator_parser = new Parse::Stallion(
  \%calculator_rules,
  { start_rule => 'start_expression'
});

my $result =
 $calculator_parser->parse_and_evaluate("7+4");
print "Result is $result\n";
is ($result, 11, "simple plus");
#use Data::Dumper;print STDERR "parse trace is ".Dumper($x->{parse_trace})."\n";
#print STDERR "parse tree is ".$x->{tree}->stringify."\n";

my $x;
($result, $x) =
 $calculator_parser->parse_and_evaluate("7 + 4");
print "Result is $result\n";
is ($result, 11, "simple plus with spaces");


($result, $x) = $calculator_parser->parse_and_evaluate("5+8+3 + 4.5");
#use Data::Dumper;print STDERR "parse trace is ".Dumper($x->{parse_trace})."\n";
print "Result is $result\n";
is ($result, 20.5, "simple half plus");

$result =
 $calculator_parser->parse_and_evaluate("7*4");
print "Result is $result\n";
is ($result, 28, "simple multiply");

$result =
 $calculator_parser->parse_and_evaluate("3+7*4");
print "Result is $result\n";
is ($result, 31, "simple plus and multiply");

$result = {};
$x =
 eval {
 $calculator_parser->parse_and_evaluate("3+-+7*4", {parse_info=>$result,
  trace => 1})};
#print STDERR $@."  \n";

is($result->{parse_succeeded},0,"bad parse on parse and evaluate");
#use Data::Dumper; print STDERR Dumper($result);


print "\nAll done\n";


