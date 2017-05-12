#!/usr/bin/perl
#Copyright 2007 Arthur S Goldstein
use Test::More tests => 6;
BEGIN { use_ok('Parse::Stallion') };
#use Data::Dumper;

my %middle_parsing_rules = (
 start_expression => A(
  'ows', 'the_middle', 'ows', L(qr/\z/),
  E(sub {return $_[0]->{the_middle}})
 ),

 ows => L(
   qr/\s*/
 ),

 the_middle => L(
  qr/middle|muddle/,
  E(sub {
    my $mid = shift;
    my $k = reverse $mid;
    return $k;
  })
 )

);

my $middle_parser = new Parse::Stallion(
  \%middle_parsing_rules,
  { do_evaluation_in_parsing => 1,
  start_rule => 'start_expression',
});

my %parsing_rules = (
 start_expression => A(
  'parse_expression', L(qr/\z/),,
  E(sub {return $_[0]->{parse_expression}})
 ),
 parse_expression => O(
   'same_sized_lists'
 ),
 same_sized_lists => A(
   {'list_one'=>'string_list'}, 'middle', {list_two=>'string_list'},
   E(sub {
    if (scalar(@{$_[0]->{list_one}})
    != scalar(@{$_[0]->{list_two}})) {
     return (undef, 1);
     }
     return $_[0]->{middle};
   })
  ),
 middle => L(
  qr/\s+\w+\s+/,
  E(sub {
    my $middle = shift;
    my $j = $middle_parser->parse_and_evaluate($middle);
    if ($j) {return $j};
    return (undef, 1);
  })
 ),
 string_value => L(qr/\w+/),
 string_list => A(
   'string_value', M(A('comma','string_value')),
   E(sub {
#print STDERR "sl\n";
    return $_[0]->{string_value}})
  ),
 comma => L(qr/\,/)
);

my $pe_parser = new Parse::Stallion(
  \%parsing_rules,
  {
  do_evaluation_in_parsing => 1,
  start_rule => 'start_expression',
});

my $result;
my $x;

$result = {};
$x = $pe_parser->parse_and_evaluate("abc middle def", {parse_info=>$result});

is ($result->{parse_succeeded},1, 'simple middle parse');

is ($x,'elddim', 'simple middle parse');

$x = $pe_parser->parse_and_evaluate("abc muddle def", {parse_info=>$result={}});

is ($result->{parse_succeeded},1, 'simple middle parse');

is ($x,'elddum', 'simple middle parse');

$result = {};
$x = $pe_parser->parse_and_evaluate("abc maddle def", {parse_info=>$result});

is ($result->{parse_succeeded},0, 'simple middle parse');


print "\nAll done\n";


