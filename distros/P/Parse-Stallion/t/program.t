#!/usr/bin/perl
#Copyright 2008 Arthur S Goldstein
use Test::More tests => 2;
BEGIN { use_ok('Parse::Stallion') };

my $big_output_string;
my %variables;
sub less_than_equal_sub {return $_[0] <= $_[1]};
sub less_than_sub {return $_[0] < $_[1]};
sub greater_than_equal_sub {return $_[0] >= $_[1]};
sub greater_than_sub {return $_[0] > $_[1]};
sub equality_sub {return $_[0] == $_[1]};

my %program_rules = (
 program => A(
   'block_of_statements', qr/\z/,
   E(sub {my $block_of_statements = $_[0]->{block_of_statements};
       return $block_of_statements;
    })
  )
,
 ows => #optional white space
    qr/\s*/
,
 block_of_statements =>
   M('full_statement',
    E(sub {
      my @statements = @{$_[0]->{full_statement}};
      return sub {
        foreach my $statement (@statements) {
         &$statement}
      }
    })
  )
,
  full_statement =>
   A('statement', 'ows', qr/\;/ , 'ows',
    E(sub {return $_[0]->{statement}})
 )
,
 statement => O(
   'assignment', 'print', 'while'
 )
,
  assignment => A
   ('variable', 'ows', qr/\=/,
     'ows', 'numeric_expression',
   E(sub {
     my $variable = $_[0]->{variable};
     my $numeric_expression = $_[0]->{numeric_expression};
     return sub {
      $variables{$variable} = &$numeric_expression};
   })
 )
,
  variable => L(
    qr/\w+/,
    qr/
     while|
     print
    /
 )
,
  print => A(
   qr/print/, 'ows', 'numeric_expression',
   E(sub {
     my $numeric_expression = $_[0]->{numeric_expression};
     return sub {my $ne = &$numeric_expression;
       $big_output_string .= $ne;
 #      print $ne  #commented out because causes problems with make test
   }})
 )
,
  while => A(
   qr/while/, 'ows',
      qr/\(/, 'ows',
    'condition', 'ows',
     qr/\)/, 'ows',
     qr/\{/, 'ows',
      'block_of_statements', 'ows',
     qr/\}/, 'ows',
   E(sub {
     my $condition = $_[0]->{condition};
     my $block_of_statements = $_[0]->{block_of_statements};
     return sub {
      while (&$condition) {&$block_of_statements}
    }
   })
 )
,
  condition => A('ows', 'value', 'ows', 'comparison', 'ows',
   'value', 'ows',
   E(sub {
     my $left_value = $_[0]->{value}->[0];
     my $right_value = $_[0]->{value}->[1];
     my $comparison = $_[0]->{comparison};
     return sub {
       my $left = &$left_value;
       my $right = &$right_value;
       &$comparison($left, $right);
     }
   })
 )
,
  comparison => O('less_than_equal','less_than',
   'greater_than_equal', 'greater_than', 'equality'),
less_than_equal => L(
  qr/\<\=/,
  E(sub {return \&less_than_equal_sub})
 ),
less_than => L(
  qr/\</,
  E(sub {return \&less_than_sub})
 ),
greater_than_equal => L(
  qr/\>\=/,
  E(sub {return \&greater_than_equal_sub})
 ),
greater_than => L(
  qr/\>/,
  E(sub {return \&greater_than_sub})
 ),
equality => L(
  qr/\=\=/,
  E(sub {return \&equality_sub})
 ),
 plus_or_minus => 
   qr/[\-+]/
 ,
 times_or_divide =>
   qr/[*\/]/
 ,
 numeric_expression =>
   A(
   'term', 'ows',
    M(A('plus_or_minus', 'ows', 'term', 'ows')),
   E(sub {my $terms = $_[0]->{term};
    my $plus_or_minus = $_[0]->{plus_or_minus};
    my $value = shift @$terms;
    return sub {
      my $to_return = &$value;
      for my $i (0..$#{$terms}) {
        if ($plus_or_minus->[$i] eq '+') {
          $to_return += &{$terms->[$i]};
        }
        else {
          $to_return -= &{$terms->[$i]};
        }
      }
      return $to_return;
    }
   })
  ),
 term =>
   A('value', 
    M(A('times_or_divide', 'value')),
   E(sub {
    my $values = $_[0]->{value};
    my $times_or_divide = $_[0]->{times_or_divide};
    my $first_value = shift @$values;
    return sub {
      my $to_return = &$first_value;
      for my $i (0..$#{$values}) {
        if ($times_or_divide->[$i] eq '*') {
          $to_return *= &{$values->[$i]};
        }
        else {
          $to_return /= &{$values->[$i]};
        }
      }
      return $to_return;
    }
   })
 ),
 value => O('xnumber','variable_value'
 ),
 variable_value => A('variable',
  E(sub {my $variable = $_[0]->{variable};
    return sub {return $variables{$variable}}
   })
  ),
 xnumber => L(
   qr/[+\-]?(\d+(\.\d*)?|\.\d+)/,
   E(sub{ my $number = $_[0];
     return sub {return $number} })
 ),
);

my $program_parser = new Parse::Stallion(
 \%program_rules, {start_rule=>'program'});

my $fin_result =
  $program_parser->parse_and_evaluate(
   'x=1; while (x < 7) {print x; x = x + 2;};'
 );

print "Generated program\n";

&$fin_result;
is($big_output_string,'135','compiled and ran program');


print "\nAll done\n";


