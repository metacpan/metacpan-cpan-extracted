#!/usr/bin/perl
#Copyright 2007-8 Arthur S Goldstein
use Test::More tests => 6;
BEGIN { use_ok('Parse::Stallion') };
#use Data::Dumper; print STDERR "hi\n";

my %parsing_rules = (
 start_expression => A(
  'two_statements', L(qr/\z/),
  E(sub {return $_[0]->{'two_statements'}})
 ),
 two_statements => A(
   'list_statement','truth_statement',
   E(sub {
#print STDERR "two stat input is ".Dumper(\@_)."\n";
     if ($_[0]->{list_statement} != $_[0]->{truth_statement}) {
       return (undef, 1);
     }
     return 1;
   })
 ),
 list_statement => A(
   'count_statement', 'list',
   E(sub {
#print STDERR "input is now ".Dumper(\@_);
     if ($_[0]->{count_statement} == scalar(@{$_[0]->{list}})) {
#print STDERR "returning 1\n";
       return 1;
     }
#print STDERR "returning 0\n";
     return 0;
   })
 ),
 count_statement => A(
   L(qr/there are /i),'number',L(qr/ elements in /),
   E(sub {
     return $_[0]->{number};
   })
  ),
 number => L(
  qr/\d+/,
   E(sub { return shift; })
 ),
 list => A('number', M(A(L(qr/\,/), 'number')),
  E(sub {
    #use Data::Dumper;print STDERR "list input is ".Dumper(\@_)."\n";
    return $_[0]->{number}})
 ),
 truth_statement => O(
   {x=>L(qr/\. that is the truth\./)},
   {x=>L(qr/\. that is not the truth\./)},
   E(sub {
     #use Data::Dumper; print STDERR "ts input is ".Dumper(\@_)."\n";
     if ($_[0]->{'x'} =~ /not/) {
       return 0;
     }
     return 1;
   })
 ),
);

my $how_many_parser = new Parse::Stallion(
  \%parsing_rules,
  {
  do_evaluation_in_parsing => 1,
  start_rule => 'start_expression',
});

my $result;

$result = $how_many_parser->parse_and_evaluate(
  "there are 5 elements in 5,4,3,2,1. that is the truth.");

#print STDERR "result is $result\n";

is ($result, 1, 'true statement');

$result = $how_many_parser->parse_and_evaluate(
  "there are 4 elements in 5,4,3,1. that is the truth.");

#print STDERR "result is $result\n";

is ($result, 1, 'another true statement');

$result = $how_many_parser->parse_and_evaluate(
  "there are 5 elements in 5,4,3,1. that is not the truth.");

#print STDERR "result is $result\n";

is ($result, 1, 'true but trickier statement');

$result = $how_many_parser->parse_and_evaluate(
  "there are 5 elements in 5,4,3,1. that is the truth.");

#print STDERR "result is $result\n";

is ($result, undef, 'not true statement');

$result = $how_many_parser->parse_and_evaluate(
  "there are 4 elements in 5,4,3,1. that is not the truth.");

#print STDERR "result is $result\n";

is ($result, undef, 'another not true statement');
