#!/usr/bin/perl -w
use strict;
use Parse::Eyapp::Node;

use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Purity = 1;

my $string = shift || 'ASSIGN(VAR(TERMINAL), TIMES(NUM(TERMINAL),NUM(TERMINAL)))  ';
my @t = Parse::Eyapp::Node->new(
           $string, 
           sub { my $i = 0; $_->{n} = $i++ for @_ }
        );

print "****************\n";
print Dumper(\@t);
