#!/usr/bin/perl
#Copyright 2007-9 Arthur S Goldstein
use Test::More tests => 12;
BEGIN { use_ok('Parse::Stallion') };

our $and_count = 0;
our $un_and_count = 0;

my %calculator_rules = (
 start_rule => AND(
   'expression',
   E(sub {
#print STDERR "final expression is ".$_[0]->{expression}."\n";
return $_[0]->{expression}})),
 expression => AND(
   ('term', 
    MULTIPLE(AND('plus_or_minus', 'term'))),
   EVALUATION(sub {my $to_combine = $_[0]->{term};
#use Data::Dumper;
#print STDERR "p and e params are ".Dumper(\@_);
    my $plus_or_minus = $_[0]->{plus_or_minus};
    my $value = $to_combine->[0];
    for my $i (1..$#{$to_combine}) {
      if ($plus_or_minus->[$i-1] eq '+') {
        $value += $to_combine->[$i];
      }
      else {
        $value -= $to_combine->[$i];
      }
    }
    return $value;
   })),
 term => 
   A('number', 
    M(A('times_or_divide', 'number')),
   E (sub {my $to_combine = $_[0]->{number};
    my $times_or_divide = $_[0]->{times_or_divide};
    my $value = $to_combine->[0];
    for my $i (1..$#{$to_combine}) {
      if ($times_or_divide->[$i-1] eq '*') {
        $value *= $to_combine->[$i];
      }
      else {
        $value /= $to_combine->[$i]; #does not check for zero
      }
    }
    return $value;
   }
 )),
 number => LEAF(
   qr/\s*[+\-]?(\d+(\.\d*)?|\.\d+)\s*/,
   E(sub{$and_count++; return 0 + $_[0]; })),
 plus_or_minus => LEAF(
   qr/\s*[\-+]\s*/
 ),
 times_or_divide => L(
   qr/\s*[*\/]\s*/
 ),
);

my $calculator_parser = new Parse::Stallion(\%calculator_rules);

my $result;
my $info;
($result, $info) = $calculator_parser->parse_and_evaluate("7+4");
is ($result, 11, "simple plus");
#use Data::Dumper; print STDERR Dumper($info)."\n";

$result =
 $calculator_parser->parse_and_evaluate("7*4");
is ($result, 28, "simple multiply");

$result =
 $calculator_parser->parse_and_evaluate("3+7*4");
#print "Result is $result\n";
is ($result, 31, "simple plus and multiply");

my $array_p = $calculator_parser->which_parameters_are_arrays('term');

is_deeply({number => 1, times_or_divide => 1},
 $array_p, 'Which parameters are arrays arrays');

$array_p = $calculator_parser->which_parameters_are_arrays('start_rule');

is_deeply({expression => 0},
 $array_p, 'Which parameters are arrays single values');

my %n_calculator_rules = (
 start_rule =>
   A('expression',
   E(sub {
#print STDERR "final expression is ".$_[0]->{expression}."\n";
return $_[0]->{expression}}),U()),
 expression => A(
   ('term', 
    M(A('plus_or_minus', 'term'))),
   E(sub {my $to_combine = $_[0]->{term};
#use Data::Dumper;
#print STDERR "p and e params are ".Dumper(\@_);
    my $plus_or_minus = $_[0]->{plus_or_minus};
    my $value = $to_combine->[0];
    for my $i (1..$#{$to_combine}) {
      if ($plus_or_minus->[$i-1] eq '+') {
        $value += $to_combine->[$i];
      }
      else {
        $value -= $to_combine->[$i];
      }
    }
    return $value;
   })),
 term =>
   A('number', 
    M(A('times_or_divide', 'number')),
   E(sub {my $to_combine = $_[0]->{number};
    my $times_or_divide = $_[0]->{times_or_divide};
    my $value = $to_combine->[0];
    for my $i (1..$#{$to_combine}) {
      if ($times_or_divide->[$i-1] eq '*') {
        $value *= $to_combine->[$i];
      }
      else {
        $value /= $to_combine->[$i]; #does not check for zero
      }
    }
    return $value;
   })),
 number => L(
   qr/\s*[+\-]?(\d+(\.\d*)?|\.\d+)\s*/,
   U(sub{
#print STDERR "discountu $un_and_count\n";
    $un_and_count++;}),
   E( sub{ $and_count++;return 0 + $_[0]; })),
 plus_or_minus => L(
   qr/\s*[\-+]\s*/,
 ),
 times_or_divide => L(
   qr/\s*[*\/]\s*/
 ),
);

my $c_calculator_parser = new Parse::Stallion(\%calculator_rules,
 {do_evaluation_in_parsing => 1
});

my $n_calculator_parser = new Parse::Stallion(\%n_calculator_rules);

$un_and_count = 0;
$and_count = 0;
$calculator_parser->parse_and_evaluate("3+7*4+q8q");
my $and_1 = $and_count;
my $un_and_1 = $un_and_count;

$un_and_count = 0;
$and_count = 0;
$c_calculator_parser->parse_and_evaluate("3+7*4+q8q");
my $and_2 = $and_count;
my $un_and_2 = $un_and_count;

$un_and_count = 0;
$and_count = 0;
$n_calculator_parser->parse_and_evaluate("3+7*4+q8q");
my $and_3 = $and_count;
my $un_and_3 = $un_and_count;

is ($and_1, 0, 'post eval');
is ($and_2, 3, 'during eval');
is ($and_3, 3, 'during eval again');
is ($un_and_1, 0, 'un post eval');
is ($un_and_2, 0, 'un during eval');
is ($un_and_3, 3, 'un during eval again');


print "\nAll done\n";
