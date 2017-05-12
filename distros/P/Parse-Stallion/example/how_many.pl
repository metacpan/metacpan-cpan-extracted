#!/usr/bin/perl
use Parse::Stallion;

my %parsing_rules = (
 start_expression => A(
  'two_statements', qr/\z/,
  E(sub {return $_[0]->{'two_statements'}})
 ),
 two_statements =>
   A('list_statement','truth_statement',
    E(sub {
     if ($_[0]->{list_statement} != $_[0]->{truth_statement}) {
       return (undef, 1);
     }
     return 1;
   })
 ),
 list_statement =>
   A('count_statement', 'list',
    E(sub {
     if ($_[0]->{count_statement} == scalar(@{$_[0]->{list}})) {
       return 1;
     }
     return 0;
   })
 ),
 count_statement =>
   A(qr/there are /i,'number',qr/ elements in /,
    E(sub {
     return $_[0]->{number};
   })
  ),
 number => L(
  qr/\d+/,
   E(sub { return 0 + shift; })
 ),
 list => A('number', M(A(qr/\,/, 'number')),
   E(sub {return $_[0]->{number}})
 ),
 truth_statement =>
   O({t=>qr/\. that is the truth\./},
    {t=>qr/\. that is not the truth\./},
    E(sub {
     if ($_[0]->{t} =~ /not/) {
       return 0;
     }
     return 1;
   })
 )
);

my $how_many_parser = new Parse::Stallion(
  \%parsing_rules,
  { do_evaluation_in_parsing => 1,
   start_rule => 'start_expression',
});

$result = $how_many_parser->parse_and_evaluate(
  "there are 5 elements in 5,4,3,2,1. that is the truth.");

print "$result should be 1\n";

$result = $how_many_parser->parse_and_evaluate(
  "there are 5 elements in 5,4,3,1. that is not the truth.");

print "$result should be 1\n";

$result = $how_many_parser->parse_and_evaluate(
  "there are 5 elements in 5,4,3,1. that is the truth.");

print "$result should be undef\n";

