#!perl

use strict;
use warnings;

use Test::More;

eval "use Test::Kwalitee 1.01 ()";
plan(skip_all => 'Test::Kwalitee 1.01 not installed') if $@;

SKIP: {
 eval { Test::Kwalitee->import(tests => [ '-use_strict' ]); };
 if (my $err = $@) {
  1 while chomp $err;
  require Test::Builder;
  my $Test = Test::Builder->new;
  my $plan = $Test->has_plan;
  $Test->skip_all($err) if not defined $plan or $plan eq 'no_plan';
  skip $err => $plan - $Test->current_test;
 }
}
