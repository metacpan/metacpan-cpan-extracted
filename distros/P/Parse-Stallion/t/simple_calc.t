#!/usr/bin/perl
#Copyright 2007-10 Arthur S Goldstein
use Test::More tests => 10;
BEGIN { use_ok('Parse::Stallion') };

my %calculator_rules = (
 start_rule =>
   AND('expression',
   E(sub {
#print STDERR "final expression is ".$_[0]->{expression}."\n";
return $_[0]->{expression}}),
  ),
 expression => AND(
   'term', 
    MULTIPLE(AND('plus_or_minus', 'term')),
   E(sub {my $to_combine = $_[0]->{term};
#use Data::Dumper; print STDERR "p and e params are ".Dumper(\@_);
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
   }),
  ),
 term => AND(
   'number', 
    M(AND('times_or_divide', 'number')),
    E(sub {my $to_combine = $_[0]->{number};
#use Data::Dumper;print STDERR "terms to term are ".Dumper(\@_)."\n";
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
#print STDERR "Term returning $value\n";
    return $value;
   })
 ),
 number => LEAF(qr/\s*[+\-]?(\d+(\.\d*)?|\.\d+)\s*/,
   E(sub{ return $_[0]})),
 plus_or_minus => LEAF(qr/\s*[\-+]\s*/),
 times_or_divide => LEAF(qr/\s*[*\/]\s*/)
);

my $calculator_parser = new Parse::Stallion(
  \%calculator_rules,
  {
  do_evaluation_in_parsing => 1
  });

my $result =
 $calculator_parser->parse_and_evaluate("7+4");
#my $parsed_tree = $result->{tree};
#$result = $calculator_parser->do_tree_evaluation({tree=>$parsed_tree});
#print "Result is $result\n";
is ($result, 11, "simple plus");

$result =
 $calculator_parser->parse_and_evaluate("7*4");
#$parsed_tree = $result->{tree};
#$result = $calculator_parser->do_tree_evaluation({tree=>$parsed_tree});
#print "Result is $result\n";
is ($result, 28, "simple multiply");

$result =
 $calculator_parser->parse_and_evaluate("3+7*4");
is ($result, 31, "simple plus and multiply");

my $array_p = $calculator_parser->which_parameters_are_arrays('term');

#use Data::Dumper; print STDERR "ap is ".Dumper($array_p)."\n";
is_deeply({number => 1, times_or_divide => 1},
 $array_p, 'Which parameters are arrays arrays');

$array_p = $calculator_parser->which_parameters_are_arrays('start_rule');

is_deeply({expression => 0},
 $array_p, 'Which parameters are arrays single values');

my $short_calculator_parser = new Parse::Stallion(
  \%calculator_rules,
  {do_evaluation_in_parsing => 1,
#  end_of_parse_allowed => sub {return 1},
  });

#$result =
# $short_calculator_parser->parse_and_evaluate("7+4 x");
#is ($result, 11, "simple plus x on short calculator");
#
#$result =
# $calculator_parser->parse_and_evaluate("7+4 x");
#is ($result, undef, "simple plus x on calculator");
#
#my ($new_result, $details) =
# $short_calculator_parser->parse_and_evaluate("7+4 x");
#is ($details->{unparsed}, 'x', "unparsed of simple plus x on short calculator");
#
#my $q = '7 + 4 x';
#
#$short_calculator_parser->parse_and_evaluate(\$q);
#
#is ($q, 'x', "var in unparsed of simple plus x on short calculator");
#
#$q = '7 + 4 x';
#
#$short_calculator_parser->parse_and_evaluate(\$q);
#
#is ($q, 'x', "var in as hash unparsed of simple plus x on short calculator");

$result = $calculator_parser->parse_and_evaluate('');
is ($result, undef, "empty");

use_ok('Parse::Stallion::EBNF');
my $ebnf = ebnf Parse::Stallion::EBNF($short_calculator_parser);

my $numb_regexp = qr/\s*[+\-]?(\d+(\.\d*)?|\.\d+)\s*/;
my $t_or_d_regexp = qr/\s*[*\/]\s*/;
my $p_or_m_regexp = qr/\s*[\-+]\s*/;

is ($ebnf,
'start_rule = expression -EVALUATION-  ;
expression = term , expression__XZ__1 -EVALUATION-  ;
term = number , term__XZ__1 -EVALUATION-  ;
number = '.$numb_regexp.' -EVALUATION-  ;
term__XZ__1 = { term__XZ__2 } ;
term__XZ__2 = times_or_divide , number ;
times_or_divide = '.$t_or_d_regexp.' ;
expression__XZ__1 = { expression__XZ__2 } ;
expression__XZ__2 = plus_or_minus , term ;
plus_or_minus = '.$p_or_m_regexp.' ;
', "ebnf test");

my %calculator_with_end_rules = (
 start_rule =>
   AND('expression', qr/\s*\;\s*/,
   E(sub {
#print STDERR "final expression is ".$_[0]->{expression}."\n";
return $_[0]->{expression}}),
  ),
 expression => AND(
   'term', 
    MULTIPLE(AND('plus_or_minus', 'term')),
   E(sub {my $to_combine = $_[0]->{term};
#use Data::Dumper; print STDERR "p and e params are ".Dumper(\@_);
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
   }),
  ),
 term => AND(
   'number', 
    M(AND('times_or_divide', 'number')),
    E(sub {my $to_combine = $_[0]->{number};
#use Data::Dumper;print STDERR "terms to term are ".Dumper(\@_)."\n";
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
#print STDERR "Term returning $value\n";
    return $value;
   })
 ),
 number => LEAF(qr/\s*[+\-]?(\d+(\.\d*)?|\.\d+)\s*/,
   E(sub{ return $_[0]})),
 plus_or_minus => LEAF(qr/\s*[\-+]\s*/),
 times_or_divide => LEAF(qr/\s*[*\/]\s*/)
);

my $calculator_end_parser = new Parse::Stallion(\%calculator_with_end_rules);

my $pi={final_position => 0};

my $string = '3*9;2;432+332;9-3;';

my $i;
my @results = ();
while (($pi->{final_position} != length($string)) && $i++ < 10 ) {
  push @results, $calculator_end_parser->parse_and_evaluate($string,
   {parse_info => $pi, start_position => $pi->{final_position},
    match_length => 0});
}


#use Data::Dumper;print "results is ".Dumper(\@results)."\n";
#use Data::Dumper;print "pi is ".Dumper($pi)."\n";
is_deeply(\@results, [27, 2, 764, 6], 'loop with need not match whole string');


print "\nAll done\n";
