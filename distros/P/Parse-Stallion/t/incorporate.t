#!/usr/bin/perl
#Copyright 10 Arthur S Goldstein
use Test::More tests => 12;
BEGIN { use_ok('Parse::Stallion') };

my $sub_number = sub{ return $_[0]};
my $sub_term = sub {my $to_combine = $_[0]->{number};
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
   };
my $sub_exp = sub {my $to_combine = $_[0]->{term};
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
   };
my $sub_start = sub {
return $_[0]->{expression}};

my %calculator_rules = (
 start_rule =>
   AND('expression',
   E($sub_start)
  ),
 expression => AND(
   'term', 
    MULTIPLE(AND('plus_or_minus', 'term')),
   E($sub_exp)
  ),
 term => AND(
   'number', 
    M(AND('times_or_divide', 'number')),
    E($sub_term)
 ),
 number => LEAF(qr/\s*[+\-]?(\d+(\.\d*)?|\.\d+)\s*/,
   E($sub_number)),
 plus_or_minus => LEAF(qr/\s*[\-+]\s*/),
 times_or_divide => LEAF(qr/\s*[*\/]\s*/)
);

my $calculator_parser = new Parse::Stallion(
  \%calculator_rules,
  {
  do_evaluation_in_parsing => 1
  });
#use Data::Dumper; print STDERR "Calc parser rules ".Dumper($calculator_parser)."\n";

my $inc_parser = new Parse::Stallion(
 {},
 {incorporate => [{grammar_source => $calculator_parser}]});

my $i_result = $inc_parser->parse_and_evaluate("7+4");
is ($i_result, 11, "i simple plus");

delete $calculator_parser->{unique_name_counter};
is_deeply($inc_parser, $calculator_parser, 'Just incorporate');
is_deeply($inc_parser->{rule}, $calculator_parser->{rule}, 'Just rule incorporate');

my %numberg = (
 number => LEAF(qr/\s*[+\-]?(\d+(\.\d*)?|\.\d+)\s*/,
   E($sub_number)),
);

my $numberg_parser = new Parse::Stallion(
  \%numberg
);

my %no_number_calc = (
 start_rule =>
   AND('expression',
   E($sub_start)
  ),
 expression => AND(
   'term', 
    MULTIPLE(AND('plus_or_minus', 'term')),
   E($sub_exp)
  ),
 term => AND(
   'number', 
    M(AND('times_or_divide', 'number')),
    E($sub_term)
 ),
 plus_or_minus => LEAF(qr/\s*[\-+]\s*/),
 times_or_divide => LEAF(qr/\s*[*\/]\s*/)
);

my $calc_with_numberg_parser = new Parse::Stallion(
  \%no_number_calc,
  {incorporate=>[{grammar_source=>$numberg_parser}],
   do_evaluation_in_parsing => 1}
);
delete $calc_with_numberg_parser->{unique_name_counter};

my $cwnp_result = $calc_with_numberg_parser->parse_and_evaluate("7+6");
is ($cwnp_result, 13, "calc with number simple plus");

is_deeply($inc_parser, $calc_with_numberg_parser, 'two incorporated parsers');

my $x;
$x = '';

$x = eval{my $z_parser = new Parse::Stallion(
  \%calculator_rules,
  {incorporate=>[{grammar_source=>$numberg_parser}]}
);
};

like($@,qr/Rule number already exists/,'already exists');

eval{my $z_parser = new Parse::Stallion(
  \%calculator_rules,
  {incorporate=>[{grammar_source=>$numberg_parser},
    {grammar_source=>$calculator_parser}]}
);
};

like($@,qr/Rule number in extraction already exists/,'extraction already exists');

my $prefix_z_parser;

eval{
  $prefix_z_parser = new Parse::Stallion(
    \%calculator_rules,
    {incorporate=>[{grammar_source=>$numberg_parser, prefix=>'z'},
      {grammar_source=>$calculator_parser, prefix=>'zz'}]}
  );
};
like($@,qr/No path to rule/,'unconnected prefixed grammar');

eval {
  $no_number_calc{start_rule} = (
   OR('expression','zzstart_rule',
   E($sub_start)
  ));

  $prefix_z_parser = new Parse::Stallion(
    \%no_number_calc,
    {incorporate=>[{grammar_source=>$numberg_parser},
      {grammar_source=>$calculator_parser, prefix=>'zz'}]}
  );
};
is ($@,'','prefix rule');

my $nn_result = $prefix_z_parser->parse_and_evaluate("7+9");
is ($nn_result, 16, "zz simple plus");

  my %number = (number => qr/[+\-]?(\d+(\.\d*)?|\.\d+)/);

  my $number_parser = new Parse::Stallion(\%number);

  my %grammar_i = (
   expression =>
    A('number', qr/\s*\+\s*/, 'decimal_number',
     E(sub {return $_[0]->{number} + $_[0]->{'decimal_number'}})
   ),
   number => qr/\d+/
  );

  my $parser_i = new Parse::Stallion(
   \%grammar_i,
   {incorporate => [{grammar_source=>$number_parser, prefix=>'decimal_'}]}
  );

 my $results_i = $parser_i->parse_and_evaluate('4 + 5.6');
 #$results_i should contain 9.6
 is ($results_i, 9.6, 'incorporate documentation example');


print "\nAll done\n";
