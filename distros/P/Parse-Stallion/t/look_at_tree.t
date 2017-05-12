#!/usr/bin/perl
#Copyright 2007-9 Arthur S Goldstein
use Test::More tests => 12;
#use Data::Dumper;
BEGIN { use_ok('Parse::Stallion') };

sub bottom_up_depth_first_search { #left to right
  my $tree = shift;
  my @qresults;
  my @queue = ($tree);
  while (my $node = pop @queue) {
    unshift @qresults, $node;
    foreach my $child (@{$node->{children}}) {
      push @queue, $child;
    }
  }
  return @qresults;
}

my %calculator_rules = (
 start_expression => A(
   'expression', L(qr/\z/),
   E(sub {return $_[0]->{expression}})
  ),
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
   })
  ),
 term => A(
   'number', 
    M(A('times_or_divide', 'number')),
   E(sub {my $to_combine = $_[0]->{number};
    my $times_or_divide = $_[0]->{times_or_divide};
    my $value = shift @$to_combine;
    for my $i (0..$#{$to_combine}) {
      if ($times_or_divide->[$i] eq '*') {
        $value *= $to_combine->[$i];
      }
      else {
        $value /= $to_combine->[$i]; #does not check for zero
      }
    }
    return $value;
   })
 ),
 number => L(
   qr/\s*[+\-]?(\d+(\.\d*)?|\.\d+)\s*/,
   E(sub{ return $_[0]; })
 ),
 plus_or_minus => L(
   qr/\s*[\-+]\s*/, E(qr/\s*([\-+])\s*/),
 ),
 times_or_divide => L(
   qr/\s*[*\/]\s*/, E(qr/\s*([*\/])\s*/), 'USE_PARSE_MATCH'
 ),
);

my $calculator_parser = new Parse::Stallion(
  \%calculator_rules,
  { start_rule => 'start_expression'});

my $result = {};
my $x =
 $calculator_parser->parse_and_evaluate("7+4", {parse_info=>$result});
#my $parsed_tree = $result->{tree};
#print STDERR "pt is ".Dumper($parsed_tree)."\n";
#$result = $calculator_parser->do_tree_evaluation({tree=>$parsed_tree});
#print "Result is $result\n";
is ($x, 11, "simple plus");

$result = {};
$x =
 $calculator_parser->parse_and_evaluate("7*4", {parse_info=>$result});
#$parsed_tree = $result->{tree};
#$result = $calculator_parser->do_tree_evaluation({tree=>$parsed_tree});
#print "Result is $result\n";
is ($x, 28, "simple multiply");

$result = {};
$x =
 $calculator_parser->parse_and_evaluate("3+7*4", {parse_info=>$result});
my $parsed_tree = $result->{tree};
#$result = $calculator_parser->do_tree_evaluation({tree=>$parsed_tree});
#print "Result is $result\n";
is ($x, 31, "simple plus and multiply");

my @bottom_up_names;
my @bottom_up_pvalues;
#$calculator_parser->remove_non_evaluated_nodes({tree=>$parsed_tree});
foreach my $node
 (bottom_up_depth_first_search($parsed_tree)) {
  push @bottom_up_names, $node->{name};
  push @bottom_up_pvalues, $node->{parse_match};
}

#use Data::Dumper;print STDERR "bunames ".Dumper(\@bottom_up_names)."\n";
is_deeply(\@bottom_up_names,
[qw (number 
 term__XZ__1 term plus_or_minus number times_or_divide number 
 term__XZ__2 term__XZ__1 term expression__XZ__2
 expression__XZ__1 expression
 start_expression__XZ__1
 start_expression)]
, 'names in bottom up search');

#use Data::Dumper;print STDERR "buvalues ".Dumper(\@bottom_up_pvalues)."\n";
is_deeply(\@bottom_up_pvalues,
[  '3',
          undef,
          undef,
          '+',
          '7',
          '*',
          '4',
          undef,
          undef,
          undef,
          undef,
          undef,
          undef,
          '',
          undef
]
, 'pvalues in bottom up search');

#print STDERR "bun ".join('.bun.', @bottom_up_names)."\n";

#print STDERR "bup ".join('.bup.', @bottom_up_pvalues)."\n";

#use Data::Dumper;print STDERR $parsed_tree->stringify({values=>['name','parse_match']});

my $pm = $parsed_tree->stringify({values=>['name','parse_match']});

my $pq = 
'start_expression||
 expression||
  term||
   number|3|
   term__XZ__1||
  expression__XZ__1||
   expression__XZ__2||
    plus_or_minus|+|
    term||
     number|7|
     term__XZ__1||
      term__XZ__2||
       times_or_divide|*|
       number|4|
 start_expression__XZ__1||
';

my @x = split /\n/, $pm;
my @y = split /\n/, $pq;
is_deeply(\@x,\@y, 'split pm pq');

is($parsed_tree->stringify({values=>['name','parse_match']}), $pq,
'stringify');

  my %no_eval_rules = (
   start_rule => A('term',
    M(A ({plus=>qr/\s*\+\s*/}, 'term'))),
   term => A({left=>'number_or_x'},
    M (A({times=>qr/\s*\*\s*/},
     {right=>'number_or_x'}))),
   number_or_x => O('number',qr/x/),
   number => qr/\s*\d*\s*/,
  );

  my $no_eval_parser = new Parse::Stallion(
   \%no_eval_rules,
   {do_not_compress_eval => 0 });

  $result = $no_eval_parser->parse_and_evaluate("7+4*8");
#use Data::Dumper; print STDERR "result is ".Dumper($result);

  is_deeply($result,{                                  
          'plus' => [
                      '+'
                    ],
          'term' => [
                      '7',
                      {
                        'left' => '4',
                        'right' => [
                                     '8'
                                   ],
                        'times' => [
                                     '*'
                                   ]
                      }
                    ]
        },'no eval do not compress 0');

  my $dnce_no_eval_parser =
   new Parse::Stallion(
   \%no_eval_rules,
   {do_not_compress_eval => 1
   });

  $result = $dnce_no_eval_parser->parse_and_evaluate("7+4*8");

  is_deeply($result, {
          'plus' => [
                      '+'
                    ],
          'term' => [
                      {
                        'left' => {number => '7'}
                      },
                      {
                        'left' => {number => '4'},
                        'right' => [
                                     {number => '8'}
                                   ],
                        'times' => [
                                     '*'
                                   ]
                      }
                    ]
        }, 'no eval do not compress 1');
#use Data::Dumper; print STDERR "result is ".Dumper($result);

my %recursive = (
 begin => A('start'),
 start => A('start', 'start')
);

my $recursive_parser = eval {new Parse::Stallion(\%recursive)};
like($@, qr/^Left recursion in grammar/, 'start start');

%recursive = (
 start => A('start')
);

$recursive_parser = eval {new Parse::Stallion(\%recursive,
 {start_rule => 'start'})};
like($@, qr/^Left recursion in grammar/, 'only start');

print "\nAll done\n";


