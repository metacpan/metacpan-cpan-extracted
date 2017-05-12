#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Syccess;

{
  package SyccessTestTrait;

  use Moo::Role;

  sub doomdidoom { 1 }

  1;
}

my $syc = Syccess->new_with_traits(
  traits => [qw( SyccessTestTrait )],
  result_traits => [qw( SyccessTestTrait )],
  error_traits => [qw( SyccessTestTrait )],
  field_traits => [qw( SyccessTestTrait )],
  fields => [
    a => [ in => [qw( a b c )] ],
  ],
);

isa_ok($syc,'Syccess');
ok($syc->does('SyccessTestTrait'),'Syccess role is applied');
ok($syc->can('doomdidoom') ? 1 : 0,'Role function is available');
ok($syc->field('a')->does('SyccessTestTrait'),'field a has field role applied');

my $first = $syc->validate( a => 'a' );
isa_ok($first,'Syccess::Result');
ok($first->does('SyccessTestTrait'),'result role is applied');
ok($first->success,'first result is valid');

my $second = $syc->validate( a => 'd' );
isa_ok($second,'Syccess::Result');
ok($second->does('SyccessTestTrait'),'result role is applied on second result');
ok(!$second->success,'second result is invalid');
my @second_errors = @{$second->errors};
is(scalar @second_errors,1,'second result has one error');
is($second_errors[0]->message,'This value for A is not allowed.','second result first error message is ok');
ok($second_errors[0]->does('SyccessTestTrait'),'second result error does error role');

my $thirdsyc = Syccess->new(
  result_traits => [qw( SyccessTestTrait )],
  error_traits => [qw( SyccessTestTrait )],
  field_traits => [qw( SyccessTestTrait )],
  fields => [
    a => [ in => [qw( a b c )] ],
  ],
);

isa_ok($thirdsyc,'Syccess');
ok($thirdsyc->field('a')->does('SyccessTestTrait'),'field a of third Syccess has field role applied');

my $third = $thirdsyc->validate( a => 'd' );
isa_ok($third,'Syccess::Result');
ok($third->does('SyccessTestTrait'),'result role of third Syccess is applied on second result');
ok(!$third->success,'third result is invalid');
my @third_errors = @{$third->errors};
ok($third_errors[0]->does('SyccessTestTrait'),'third result error does error role');

done_testing;
