#!/usr/bin/perl -w
use strict;

sub fib {
  my($howmany, $n1, $n2) = @_;
  my(@result);
  if ( $howmany > 0 ) {
    push @result, $n1+$n2, fib($howmany-1, $n2, $n1+$n2);
  }
  return @result;
}

printf "%s\n", join ",", fib(10,1,1);
