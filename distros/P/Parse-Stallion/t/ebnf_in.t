#!/usr/bin/perl
#Copyright 2008-10 Arthur S Goldstein
use Test::More tests => 71;

BEGIN { use_ok('Parse::Stallion::EBNF') };

my $rules=<<'END';
start = (number plus number)
 S{
 #use Data::Dumper;print STDERR "input is ".Dumper(\@_)."\n";
  return $number->[0] + $number->[1]}S;
plus = qr/\s*\+\s*/;
number = (qr/\d+/) S{
 #use Data::Dumper;print STDERR "ninput is ".Dumper(\@_)."\n";
 return 0 + $_}S;
END

my $rule_parser = ebnf_new Parse::Stallion::EBNF($rules);

#my @ptrace;
my $value = $rule_parser->parse_and_evaluate('1 + 1'
  #,{parse_trace=>\@ptrace}
);

#use Data::Dumper;print STDERR "Lpt ".Dumper(\@ptrace);

is($value, 2, 'did simple addition');

my $morerules=<<'END';
start = (term plus_terms)
 S{
 #use Data::Dumper;print STDERR "startinput is ".Dumper(\@_)."\n";
  my $value = $term;
  if ($plus_terms) {
    foreach my $plus_term (@{$plus_terms}) {
      $value += $plus_term;
    }
  }
  return $value}S;
plus_terms = {plus_term};
plus_term = (plus term) S{return $term}S;
plus = qr/\s*\+\s*/;
term = (number times_numbers)
 S{
 #use Data::Dumper;print STDERR "terminput is ".Dumper(\@_)."\n";
  my $value = $number;
  if ($times_numbers) {
    foreach my $times_number (@{$times_numbers}) {
      $value *= $times_number;
    }
  }
  return $value}S;
times_numbers = {times_number};
times_number = (times number) S{return $number}S;
times = qr/\s*\*\s*/;
number = (qr/\d+/) S{
 #use Data::Dumper;print STDERR "xinput is ".Dumper(\@_)."\n";
 return 0 + $_}S;
END

my $morerule_parser = ebnf_new Parse::Stallion::EBNF($morerules);

$value =
 $morerule_parser->parse_and_evaluate('1 + 1');

#use Data::Dumper;print STDERR "Lpt ".Dumper(\@ptrace);

is($value, 2, 'more did simple addition');

$value =
 $morerule_parser->parse_and_evaluate('2 * 2');

#use Data::Dumper;print STDERR "Lpt ".Dumper(\@ptrace);

is($value, 4, 'more did simple multiplication');

$value =
 $morerule_parser->parse_and_evaluate('2 * 2 + 3');

#use Data::Dumper;print STDERR "Lpt ".Dumper(\@ptrace);

is($value, 7, 'more did multiplication and add');

$value =
 $morerule_parser->parse_and_evaluate('2 + 2 * 3');

#use Data::Dumper;print STDERR "Lpt ".Dumper(\@ptrace);

is($value, 8, 'more did add and multiplication');

$value =
 $morerule_parser->parse_and_evaluate('4 * 8 + 3 * 2 + 4 + 5 + 8 * 2+2 + 2 * 3');

#use Data::Dumper;print STDERR "Lpt ".Dumper(\@ptrace);

is($value, 71 , 'more did big calculation');

my $badmorerules=<<'END';
start = (term plus_terms)
 S{
 #use Data::Dumper;print STDERR "startinput is ".Dumper(\@_)."\n";
  my $value = $term;
  if ($plus_terms) {
    foreach my $plus_term (@{$plus_terms}) {
      $value += $plus_term;
    }
  }
  return $value}S;
plus_terms = {plus_term};
plus_term = (plus term) S{return $term}S;
plus = qr/\s*\+\s*/;
x;
term = (number times_numbers)
 S{
 #use Data::Dumper;print STDERR "terminput is ".Dumper(\@_)."\n";
  my $value = $number;
  if ($times_numbers) {
    foreach my $times_number (@{$times_numbers}) {
      $value *= $times_number;
    }
  }
  return $value}S;
times_numbers = {times_number};
times_number = (times && number) S{return $number}S;
times = qr/\s*\*\s*/;
number = (qr/\d+/) S{
 #use Data::Dumper;print STDERR "xinput is ".Dumper(\@_)."\n";
 return 0 + $_}S;
END

my $badmorerule_parser = eval {ebnf_new Parse::Stallion::EBNF($badmorerules)};
like($@, qr/Error at line 14\b/, 'x error');
like($@, qr/Error at line 26\b/, '&& error');

my $dupmorerules=<<'END';
start = (term plus_terms)
 S{
 #use Data::Dumper;print STDERR "startinput is ".Dumper(\@_)."\n";
  my $value = $term;
  if ($plus_terms) {
    foreach my $plus_term (@{$plus_terms}) {
      $value += $plus_term;
    }
  }
  return $value}S;
plus_terms = {plus_term};
plus_terms = {plus_term};
plus_term = (plus term) S{return $term}S;
plus = qr/\s*\+\s*/;
term = (number times_numbers)
 S{
 #use Data::Dumper;print STDERR "terminput is ".Dumper(\@_)."\n";
  my $value = $number;
  if ($times_numbers) {
    foreach my $times_number (@{$times_numbers}) {
      $value *= $times_number;
    }
  }
  return $value}S;
times_numbers = {times_number};
times_number = (times number) S{return $number}S;
times = qr/\s*\*\s*/;
number = (qr/\d+/) S{
 #use Data::Dumper;print STDERR "xinput is ".Dumper(\@_)."\n";
 return 0 + $_}S;
END

my $dupmorerule_parser = eval {ebnf_new Parse::Stallion::EBNF($dupmorerules)};

like($@, qr/Duplicate rule name plus_terms/, 'plus terms error');

my $bsmorerules=<<'END';
start = (term plus_terms)
 S{
 #use Data::Dumper;print STDERR "startinput is ".Dumper(\@_)."\n";
  my $value = $term;
  if ($plus_terms) {
    foreach my $plus_term (@{$plus_terms}) {
      $value += $plus_term;
    }
  }
  return $value}S;
plus_terms = {plus_term};
plus_term = (plus term) S{return $term}S;
plus = qr/\s*\+\s*/;
term = (number times_numbers)
 S{
 #use Data::Dumper;print STDERR "terminput is ".Dumper(\@_)."\n";
  m $value = $number;
  if ($times_numbers) {
    foreach my $times_number (@{$times_numbers}) {
      $value *= $times_number;
    }
  }
  return $value}S;
times_numbers = {times_number};
times_number = (times number) S{return $number}S;
times = qr/\s*\*\s*/;
number = (qr/\d+/) S{
 #use Data::Dumper;print STDERR "xinput is ".Dumper(\@_)."\n";
 rturn 0 + $_}S;
END

#commented out these two tests because perl writes to STDERR and not
#sure of a clean way to capture it across the various environments.
#my $bsmorerule_parser = eval {ebnf_new Parse::Stallion::EBNF($bsmorerules)};
#
#like($@, qr/Subroutine in term has error/, 'sub term error');
#like($@, qr/Subroutine in number has error/, 'sub number error');

my $subrules=<<'END';
start = (term plus_terms)
 S{
 #use Data::Dumper;print STDERR "startinput is ".Dumper(\@_)."\n";
  my $value = $term;
  if ($plus_terms) {
    foreach my $plus_term (@{$plus_terms}) {
      $value += $plus_term;
    }
  }
  return $value}S;
plus_terms = {plus_term};
plus_term = ((qr/\s*\+\s*/) term) S{return $term}S;
term = (number times_numbers)
 S{
 #use Data::Dumper;print STDERR "terminput is ".Dumper(\@_)."\n";
  my $value = $number;
  if ($times_numbers) {
    foreach my $times_number (@{$times_numbers}) {
      $value *= $times_number;
    }
  }
  return $value}S;
times_numbers = {times_number};
times_number = (times number) S{return $number}S;
times = qr/\s*\*\s*/;
number = (qr/\d+/) S{
 #use Data::Dumper;print STDERR "xinput is ".Dumper(\@_)."\n";
 return 0 + $_}S;
END

my $subrule_parser = ebnf_new Parse::Stallion::EBNF($subrules);

#my @q;
$value = $subrule_parser->parse_and_evaluate('1 + 1'
# ,{parse_trace => \@q}
);

#use Data::Dumper;print STDERR "q is ".Dumper(\@q)."\n";

is($value, 2, 'sub did simple addition');

my $subsubrules=<<'END';
start = (term plus_terms)
 S{
 #use Data::Dumper;print STDERR "startinput is ".Dumper(\@_)."\n";
  my $value = $term;
  if ($plus_terms) {
    foreach my $plus_term (@{$plus_terms}) {
      $value += $plus_term;
    }
  }
  return $value}S;
plus_terms = {(((qr/\s*\+\s*/) term) S{return $term}S)};
term = (number times_numbers)
 S{
 #use Data::Dumper;print STDERR "terminput is ".Dumper(\@_)."\n";
  my $value = $number;
  if ($times_numbers) {
    foreach my $times_number (@{$times_numbers}) {
      $value *= $times_number;
    }
  }
  return $value}S;
times_numbers = {times_number};
times_number = (times number) S{return $number}S;
times = qr/\s*\*\s*/;
number = (qr/\d+/) S{
 #use Data::Dumper;print STDERR "xinput is ".Dumper(\@_)."\n";
 return 0 + $_}S;
END

my $subsubrule_parser = ebnf_new Parse::Stallion::EBNF($subsubrules);

#my @q;
$value = $subsubrule_parser->parse_and_evaluate('1 + 1'
# ,{parse_queue => \@q}
);

#use Data::Dumper;print STDERR "q is ".Dumper(\@q)."\n";

is($value, 2, 'subsub did simple addition');

#my @q;
$value = $subsubrule_parser->parse_and_evaluate('5 + 3 * 6'
# ,{parse_queue => \@q}
);

#use Data::Dumper;print STDERR "q is ".Dumper(\@q)."\n";

is($value, 23, 'subsub did addition and multiplication');


my $qoptsrules=<<'END';
start = q ([s]) ;
q = qr/q/;
s = qr/s/;
END

my $qopts_parser = ebnf_new Parse::Stallion::EBNF($qoptsrules);

$value = $qopts_parser->parse_and_evaluate('q');
ok($value, 'qopts on q');

$value = $qopts_parser->parse_and_evaluate('qs');
ok($value, 'qopts on qs');

$value = $qopts_parser->parse_and_evaluate('s');
ok(!defined $value, 'qopts on s');

$value = $qopts_parser->parse_and_evaluate('qr');
ok(!defined $value, 'qopts on qr');

my $qoptsrules2=<<'END';
start = q [s] ;
q = qr/q/;
s = qr/s/;
END

my $qopts2_parser = ebnf_new Parse::Stallion::EBNF($qoptsrules2);

$value = $qopts2_parser->parse_and_evaluate('q');
ok($value, 'qopts2 on q');

$value = $qopts2_parser->parse_and_evaluate('qs');
ok($value, 'qopts2 on qs');

$value = $qopts2_parser->parse_and_evaluate('s');
ok(!defined $value, 'qopts2 on s');

$value = $qopts2_parser->parse_and_evaluate('qr');
ok(!defined $value, 'qopts2 on qr');

my $qmultsrules=<<'END';
start = q {s} {t}*0,2;
q = qr/q/;
s = qr/s/;
t = qr/t/i;
END

my $qmults_parser = ebnf_new Parse::Stallion::EBNF($qmultsrules);

$value = $qmults_parser->parse_and_evaluate('q');
ok($value, 'qmult on q');

$value = $qmults_parser->parse_and_evaluate('qs');
ok($value, 'qmult on qs');

$value = $qmults_parser->parse_and_evaluate('qss');
ok($value, 'qmult on qss');

$value = $qmults_parser->parse_and_evaluate('s');
ok(!defined $value, 'qmult on s');

$value = $qmults_parser->parse_and_evaluate('qr');
ok(!defined $value, 'qmult on qr');

$value = $qmults_parser->parse_and_evaluate('qsst');
ok($value, 'qmult on qsst');

$value = $qmults_parser->parse_and_evaluate('qsstt');
ok($value, 'qmult on qsstt');

$value = $qmults_parser->parse_and_evaluate('qssttt');
ok(!defined $value, 'qmult on qssttt');

$value = $qmults_parser->parse_and_evaluate('qssTt');
ok($value, 'qmult on qssTt');

$value = $qmults_parser->parse_and_evaluate('qSsTt');
ok(!defined $value, 'qmult on qSsTt');

my $qqmultsrules=<<'END';
start = qr/q/ {s} {t}*0,2;
s = qr/s/;
t = q/t/;
END

my $qqmults_parser = ebnf_new Parse::Stallion::EBNF($qqmultsrules);

$value = $qqmults_parser->parse_and_evaluate('q');
ok($value, 'qqmult on q');

$value = $qqmults_parser->parse_and_evaluate('qs');
ok($value, 'qqmult on qs');

$value = $qqmults_parser->parse_and_evaluate('qss');
ok($value, 'qqmult on qss');

$value = $qqmults_parser->parse_and_evaluate('s');
ok(!defined $value, 'qqmult on s');

$value = $qqmults_parser->parse_and_evaluate('qr');
ok(!defined $value, 'qqmult on qr');

$value = $qqmults_parser->parse_and_evaluate('qsst');
ok($value, 'qqmult on qsst');

$value = $qqmults_parser->parse_and_evaluate('qsstt');
ok($value, 'qqmult on qsstt');

$value = $qqmults_parser->parse_and_evaluate('qssttt');
ok(!defined $value, 'qqmult on qssttt');

my $nrules=<<'END';
start = qr/q/ [s] {t}*0,2;
s = qr/\ws/; # comment
t = '\wt';
#another comment
END

my $nparser = ebnf_new Parse::Stallion::EBNF($nrules);

$value = $nparser->parse_and_evaluate('q');
ok($value, 'n on q');

$value = $nparser->parse_and_evaluate('qs');
ok(!defined $value, 'n on qs');

$value = $nparser->parse_and_evaluate('qss');
ok($value, 'n on qss');

$value = $nparser->parse_and_evaluate('qssss');
ok(!defined $value, 'n on qss');

$value = $nparser->parse_and_evaluate('s');
ok(!defined $value, 'n on s');

$value = $nparser->parse_and_evaluate('qr');
ok(!defined $value, 'n on qr');

$value = $nparser->parse_and_evaluate('qsst');
ok(!defined $value, 'n on qsst');

$value = $nparser->parse_and_evaluate('qsstt');
ok(!defined $value, 'n on qsstt');

$value = $nparser->parse_and_evaluate('qss\wt');
ok($value, 'n on qss\wt');

$value = $nparser->parse_and_evaluate('qss\wt\wt');
ok($value, 'n on qss\wt\wt');

$value = $nparser->parse_and_evaluate('qss\wt\wt\wt');
ok(!defined $value, 'n on qss\wt\wt\wt');

my $alias_rules=<<'END';
start = (left.(number) plus right.(number))
 S{
  return $left->{number} + $right->{number}}S;
plus = qr/\s*\+\s*/;
number = (qr/\d+/) S{
 #use Data::Dumper;print STDERR "ninput is ".Dumper(\@_)."\n";
 return 0 + $_}S;
END

my $alias_rule_parser = ebnf_new Parse::Stallion::EBNF($alias_rules);

#my @ptrace;
$value = $alias_rule_parser->parse_and_evaluate('1 + 2'
  #,{parse_trace=>\@ptrace}
);

is($value, 3, 'did simple alias addition');

my $subtrules=<<'END';
start = ("hello" | "hi") " to you";
END

my $subtparser = ebnf_new Parse::Stallion::EBNF($subtrules);

$value = $subtparser->parse_and_evaluate('hello to you');
ok($value, 'hello to you');

$value = $subtparser->parse_and_evaluate('hi to you');
ok($value, 'hi to you');

$value = $subtparser->parse_and_evaluate('bye to you');
ok(!defined $value, 'bye to you');


my $dotalias_rules=<<'END';
start = (left.number plus #comment
right.number)
 S{
  return $left + $right}S;
plus = qr/\s*\+\s*/;
number = (qr/\d+/) S{
 return 0 + $_}S;
END

my $dotalias_rule_parser = ebnf_new Parse::Stallion::EBNF($dotalias_rules);

$value = $dotalias_rule_parser->parse_and_evaluate('1 + 2');

is($value, 3, 'did simple dot alias addition');

   my $grammar_3 = 'start = (left.number qr/\s*\+\s*/ right.number)
        S{return $left + $right}S;
      number = qr/\d+/;';

   my $parser_3 = ebnf_new Parse::Stallion::EBNF($grammar_3);

   my $result_3 = $parser_3->parse_and_evaluate('1 + 6');

is ($result_3, 7, 'from parse::stallion doc');

   my $grammar_4 = 'start = (left.number qr/\s*\+\s*/ right.number)
        S{return $_matched_string}S;
      number = qr/\d+/;';

   my $parser_4 = ebnf_new Parse::Stallion::EBNF($grammar_4);

   my $result_4 = $parser_4->parse_and_evaluate('1 + 6');

is ($result_4, '1 + 6', 'matched_string');

my $frules=<<'END';
start = x_8ff;
x_8ff = qr/\ws/;
END

my $fparser = ebnf_new Parse::Stallion::EBNF($frules);

my $slrules=<<'END';
start = qr.\/\/.;
END

my $sl_parser = ebnf_new Parse::Stallion::EBNF($slrules);

$value = $sl_parser->parse_and_evaluate('//');
ok($value, 'sl on q');

my $prrules=<<'END';
a = (((c) S{3}S) | d) S{if (defined $d) {$d} else {$_}}S;
d = qr/5/;
c = qr/7/;
END

my $pr_parser = ebnf_new Parse::Stallion::EBNF($prrules);

$value = $pr_parser->parse_and_evaluate('7');
is($value, 3, 'precedence test');

my $aprrules=<<'END';
a = (d.((c) S{9}S ) | d) S{$d}S ;
d = #new comment
 qr/5/;
c = qr/7/;
END

my $apr_parser = ebnf_new Parse::Stallion::EBNF($aprrules);

$value = $apr_parser->parse_and_evaluate('5');
is($value, 5, 'precedence test a1');

$value = $apr_parser->parse_and_evaluate('7');
is($value, 9, 'precedence test a2');

$value = $apr_parser->parse_and_evaluate('9');
is($value, undef, 'precedence test a3');

my $use_min_rules=<<'END';
a = (lll.((x.{y.qr/\d/}?*1,0)
   S{
#   use Data::Dumper; print STDERR "par ".Dumper(\@_)."\n";
   return join('',@{$x->{y}})}S )
 qr/\d+/)
   S{
#   use Data::Dumper; print STDERR "ptar ".Dumper(\@_)."\n";
   return $lll}S
;
END

my $use_min__parser = ebnf_new Parse::Stallion::EBNF($use_min_rules);

my $use_max_rules=<<'END';
ab = (x.(y.{z.qr/\d/}) qr/\d+/) S{
#   use Data::Dumper; print STDERR "ptar ".Dumper(\@_)."\n";
join('',@{$x->{y}->{z}}) }S;
END

my $use_max__parser = ebnf_new Parse::Stallion::EBNF($use_max_rules);

$value = $use_min__parser->parse_and_evaluate('885');
is($value, 8, 'min rules');

$value = $use_max__parser->parse_and_evaluate('885');
is($value, 88, 'max rules');

my $newe_rules=<<'END';
ab = (x.({qr/\d/} =SM) qr/\d+/) S{
#   use Data::Dumper; print STDERR "ptar ".Dumper(\@_)."\n";
$x}S;
END

my $newe_parser = ebnf_new Parse::Stallion::EBNF($newe_rules);

$value = $newe_parser->parse_and_evaluate('885');
is($value, 88, 'newe rules');

my $newf_rules=<<'END';
cd = (y.{i.qr/\d/} qr/\d+/) S{
#   use Data::Dumper; print STDERR "ptar ".Dumper(\@_)."\n";
$y}S;
END

my $newf_parser = ebnf_new Parse::Stallion::EBNF($newf_rules);

$value = $newf_parser->parse_and_evaluate('885');
#use Data::Dumper;print STDERR "val ".Dumper($value)."\n";
is_deeply($value, {i=>[8,8]}, 'newf rules');

my $pf_rules=<<'END';
pft = (qr/\d/ F{sub {return (1,'x',0)}}F qr/\d/ =SM) S{return $_}S;
END

my $pf_parser = ebnf_new Parse::Stallion::EBNF($pf_rules);

$value = $pf_parser->parse_and_evaluate('74');
#use Data::Dumper;print STDERR "val ".Dumper($value)."\n";
is_deeply($value, '74', 'pf rules');

our $j;
my $pfb_rules=<<'END';
pft = (qr/\d/ F{sub {return (1,'x',0)}}F B{sub {$::j='q'; return;}}B
  qr/\d/ =SM) S{return $_}S;
END

my $pfb_parser = ebnf_new Parse::Stallion::EBNF($pfb_rules);

$value = $pfb_parser->parse_and_evaluate('7x');
is_deeply($j, 'q', 'pb rules');
is_deeply($value, undef, 'pb value rules');

$j = 'k';

$value = $pfb_parser->parse_and_evaluate('79');
is_deeply($j, 'k', 'pb rules');
is_deeply($value, '79', 'pb value rules 2');

print "All done\n";

