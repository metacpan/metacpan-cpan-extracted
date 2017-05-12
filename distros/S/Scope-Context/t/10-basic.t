#!perl -T

use strict;
use warnings;

use Test::More tests => 11;

use Scope::Context;

for my $method (qw<new here>) {
 local $@;
 eval {
  my $here = Scope::Context->$method;
  isa_ok $here, 'Scope::Context', "$method return value isa Scope::Context";
 };
 is $@, '', "creating a new object with ->$method does not croak";
}

{
 local $@;
 eval {
  my $here      = Scope::Context->new;
  my $also_here = Scope::Context->new($here->cxt);
  isa_ok $here,      'Scope::Context', '$here isa Scope::Context';
  isa_ok $also_here, 'Scope::Context', '$also_here isa Scope::Context';
 };
 is $@, '', 'creating a new object from a given context does not croak';
}

for my $method (qw<new here>) {
 local $@;
 eval {
  my $here = $Scope::Context::{$method}->();
  isa_ok $here, 'Scope::Context', "$method return value isa Scope::Context";
 };
 is $@, '', "creating a new object with Scope::Context::$method does not croak";
}
