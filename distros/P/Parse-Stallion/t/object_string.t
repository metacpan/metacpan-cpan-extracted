#!/usr/bin/perl
#Copyright 2007-10 Arthur S Goldstein
use Test::More tests => 5;
BEGIN { use_ok('Parse::Stallion') };

my %calculator_rules = (
 start_expression => A(
   'expression', 'end_of_string',
   E(sub {return $_[0]->{expression}})),
,
 expression => A(
   'term', 
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
   },
  )),
,
 term => A
   ('factor', 
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
   },
  )),
,
 factor =>
   AND('fin_exp', 
    M(A('power_of', 'fin_exp')),
   E(sub {
#use Data::Dumper;print STDERR "params f are ".Dumper(\@_)."\n";
    my $to_combine = $_[0]->{fin_exp};
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
       #use Data::Dumper;print STDERR "Params are ".Dumper(\@_);
       return $_[0]->{expression} }),
    ),
    (AND('number',
     EVALUATION(sub {
       #use Data::Dumper;print STDERR "params are ".Dumper(\@_);
        return $_[0]->{number} }),
    ),
   ),
  ),
,
end_of_string => L({
  nsl_regex_match => qr/\z/,
 }),
,
number => L({
  nsl_regex_match => qr/\s*[+-]?(\d+(\.\d*)?|\.\d+)\s*/,
 },
EVALUATION(
  sub{
#print STDERR "number in is ".$_[0]."\n";
   return $_[0];
  })),
left_parenthesis => L({
  nsl_regex_match => qr/\s*\(\s*/,
 }),
,
right_parenthesis => L({
  nsl_regex_match => qr/\s*\)\s*/,
 }),
,
power_of => L({
  nsl_regex_match => qr/\s*\*\*\s*/,
 }),
,
plus_or_minus => OR(
  'plus', 'minus',
 ),
,
plus => L({
  nsl_regex_match => qr/\s*\+\s*/,
 }),
,
minus => L({
  nsl_regex_match => qr/\s*\-\s*/,
 }),
,
times_or_divide_or_modulo => OR(
  'times', 'divided_by', 'modulo'
 ),
,
modulo => L({
  nsl_regex_match => qr/\s*\%\s*/,
 }),
,
times => L({
  nsl_regex_match => qr/\s*\*\s*/,
 }),
,
divided_by => L({
  nsl_regex_match => qr/\s*\/\s*/,
 }),
,
);

my $calculator_stallion = new Parse::Stallion(
  \%calculator_rules,
  {start_rule => 'start_expression',
  parse_forward =>
   sub {
    my $parameters = shift;
    my $input_string_ref = $parameters->{parse_this_ref};
#print STDERR "looking at ".$$input_string_ref."\n";
    my $rule_definition = $parameters->{rule_info}->{$parameters->{rule_name}};
    my $match_rule = $rule_definition->{nsl_regex_match} ||
     $rule_definition->{leaf} ||
     $rule_definition->{l};
    if ($$input_string_ref =~ /\A($match_rule)/) {
      my $matched = $1;
      my $not_match_rule = $rule_definition->{regex_not_match};
      if ($not_match_rule) {
        if (!($$input_string_ref =~ /\A$not_match_rule/)) {
          return (0, undef);
        }
      }
      $$input_string_ref = substr($$input_string_ref, length($matched));
#print STDERR "matched on $matched\n";
      return (1, $matched, length($matched));
    }
    return 0;
   },
  parse_backtrack =>
   sub {
    my $parameters = shift;
    my $input_string_ref = $parameters->{parse_this_ref};
    my $stored_position = $parameters->{parse_match};
    if (defined $stored_position) {
      $$input_string_ref = $stored_position.$$input_string_ref;
    }
#print STDERR "pb now have ".$$input_string_ref."\n";
   },
#  initial_position_routine => sub {
#    return 0 - length($_[0]);
#  },
  length_routine => sub {
    return length(${$_[0]});;
  }
});


#$calculator_stallion->set_handle_object({
#});


my @parse_trace;
my $string = '7+4';
my $result =
 $calculator_stallion->parse_and_evaluate($string, {parse_trace => \@parse_trace});
#print "Result is $result\n";
#use Data::Dumper;print STDERR "pt of 7 + 4 is ".Dumper(\@parse_trace)."\n";
is ($result, 11, "simple plus");

$string = '7*4';
$result =
 $calculator_stallion->parse_and_evaluate($string);
print "Result is $result\n";
is ($result, 28, "simple multiply");

$string = '3+7*4';
$result =
 $calculator_stallion->parse_and_evaluate($string);
print "Result is $result\n";
is ($result, 31, "simple plus and multiply");

$string = '3+-+7*4';
$result = {};
my $x;
$x = eval {$calculator_stallion->parse_and_evaluate($string, {parse_info=>$result})};

is($result->{parse_succeeded},0,"bad parse on parse and evaluate");


print "\nAll done\n";


