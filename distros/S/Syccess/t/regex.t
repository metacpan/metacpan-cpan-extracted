#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Syccess;

my $syc = Syccess->new(
  fields => [
    a => [ regex => qr/^\w+$/ ],
    b => [ regex => {
      arg => '^[a-z]+$',
      message => 'We only allow lowercase letters on this field.',
    } ],
  ],
);

isa_ok($syc,'Syccess');

my $first = $syc->validate( a => 'a123C456d', b => 'abc' );
isa_ok($first,'Syccess::Result');
ok($first->success,'first result is valid');

my $second = $syc->validate( a => '%%%%&$&4234', b => 'GGGGG' );
isa_ok($second,'Syccess::Result');
ok(!$second->success,'second result is invalid');
my @second_errors = @{$second->errors};
is(scalar @second_errors,2,'second result has two errors');
is($second_errors[0]->message,'Your value for A is not valid.','second result first error message is ok');
is($second_errors[1]->message,'We only allow lowercase letters on this field.','second result second error message is ok');
my @a_second_errors = @{$second->errors('a')};
is(scalar @a_second_errors,1,'second result has one error for field a');
my @b_second_errors = @{$second->errors('b')};
is(scalar @b_second_errors,1,'second result has one error for field b');

done_testing;
