#!/usr/bin/perl
#Copyright 2008 Arthur S Goldstein
use Test::More tests => 2;
BEGIN { use_ok('Parse::Stallion') };

my %basic_plus_grammar = (
 start_expression =>
   A('number', LEAF(qr/\s*[+]\s*/),
    {right_number => 'number'}, L(qr/\z/),
   E(sub {
#use Data::Dumper;print STDERR "pbpg is ".Dumper(\@_)."\n";
     return $_[0]->{number} + $_[0]->{right_number}}))
 ,
 number => 
   L(qr/\s*[+\-]?(\d+(\.\d*)?|\.\d+)\s*/,
    E(sub{ return 0 + $_[0]; })
 )
);

my $basic_plus_parser = new Parse::Stallion(
  \%basic_plus_grammar,
  {start_rule => 'start_expression'});

my $result =
 $basic_plus_parser->parse_and_evaluate("7+4");
print "Result is $result\n";
is ($result, 11, "simple plus");

print "\nAll done\n";


