#!/usr/bin/perl -w
use strict;
use Parse::Eyapp::Node;

my $string1 = shift || 'ASSIGN(VAR(TERMINAL))';
my $string2 = shift || 'ASSIGN(VAR(TERMINAL))';
my $t1 = Parse::Eyapp::Node->new($string1, sub { my $i = 0; $_->{n} = $i++ for @_ });
my $t2 = Parse::Eyapp::Node->new($string2);

# Without attributes
if ($t1->equal($t2)) {
  print "\nNot considering attributes: Equal\n";
}
else {
  print "\nNot considering attributes: Not Equal\n";
}

# Equality with attributes
if ($t1->equal($t2, n => sub { return $_[0] == $_[1] })) {
  print "\nConsidering attributes: Equal\n";
}
else {
  print "\nConsidering attributes: Not Equal\n";
}
