#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Keyword::Try;

sub inner
{
   my $canary = Canary->new; # if this line is commented, nothing happens
   try {
      return 123;
   }
   catch ($e) {
      die "Something terrible happened: $e";
   }
}

sub outer
{
   my @result;
   try {
      @result = (1, scalar inner()); # scalar or void context is mandatory
      1; # or catch will be triggered
   }
   catch ($e) {
      die "Something terrible happened: $e";
   }
   return @result;
}

is_deeply [ outer() ], [ 1, 123 ], "No extra data in return";

done_testing;

package Canary;
sub new {
    bless {}, shift;
}

sub DESTROY {
    my $x;   # Destructor MUST be nonempty
    $@ = "oops"; # Assigning to $@ is optional
}
