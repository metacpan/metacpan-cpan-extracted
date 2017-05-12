#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Syccess;

{
  package SyccessTestThing;

  use Moo;

  sub blacklisted { $_[1] eq 'bad' ? 1 : 0 }
  sub whitelisted { $_[1] eq 'good' ? 1 : 0 }

  1;
}

my $thing = SyccessTestThing->new;

my $syc = Syccess->new(
  fields => [
    a => [ call => [ $thing, 'whitelisted' ] ],
    b => [ call => { not => [ $thing, 'blacklisted' ] } ],
    c => [ call => {
      not => [ $thing, 'blacklisted' ],
      message => 'You have 5 seconds to comply.'
    } ],
  ],
);

isa_ok($syc,'Syccess');

my $first = $syc->validate( a => 'good', b => 'good', c => 'good' );
isa_ok($first,'Syccess::Result');
ok($first->success,'first result is valid');

my $second = $syc->validate( a => 'bad', b => 'bad', c => 'bad' );
isa_ok($second,'Syccess::Result');
ok(!$second->success,'second result is invalid');
my @second_errors = @{$second->errors};
is(scalar @second_errors,3,'second result has three errors');
is($second_errors[0]->message,'Your value for A is not valid.','second result first error message is ok');
is($second_errors[1]->message,'Your value for B is not valid.','second result second error message is ok');
is($second_errors[2]->message,'You have 5 seconds to comply.','second result third error message is ok');
my @c_second_errors = @{$second->errors('c')};
is(scalar @c_second_errors,1,'second result has one error for field c');

done_testing;
