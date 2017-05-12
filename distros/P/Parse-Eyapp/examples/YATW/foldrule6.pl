#!/usr/bin/perl -w
# Compile rule6.yp first: eyapp Rule6.yp
# foldrule6.pl
use strict;
use Rule6;
use Parse::Eyapp::YATW;

my %BinaryOperation = (PLUS=>'+', MINUS => '-', TIMES=>'*', DIV => '/');

sub set_terminfo {
  no warnings;
  *TERMINAL::info = sub { $_[0]{attr} };
}

sub is_foldable {
  my ($op, $left, $right);
  return 0 unless defined($op = $BinaryOperation{ref($_[0])});
  return 0 unless ($left = $_[0]->child(0), $left->isa('NUM'));
  return 0 unless ($right = $_[0]->child(1), $right->isa('NUM'));
  
  my $leftnum = $left->child(0)->{attr};
  my $rightnum = $right->child(0)->{attr};
  $left->child(0)->{attr} = eval "$leftnum $op $rightnum";
  $_[0] = $left;
}

my $parser = new Rule6();
my $input = "2*3";
$parser->input(\$input);
my $t = $parser->YYParse;

exit(1) if $parser->YYNberr > 0;

&set_terminfo;
print "\n***** Before ******\n";
print $t->str;

my $p = Parse::Eyapp::YATW->new(PATTERN => \&is_foldable);
$p->s($t);

print "\n***** After ******\n";
print $t->str."\n";
