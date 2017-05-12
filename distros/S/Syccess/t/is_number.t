#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Syccess;

my $syc = Syccess->new(
  fields => [
    a => [ is_number => 1 ],
    b => [ is_number => {
      message => 'American Horror Story rulez'
    } ],
  ],
);

isa_ok($syc,'Syccess');

my $first = $syc->validate( a => 1234 );
isa_ok($first,'Syccess::Result');
ok($first->success,'first result is valid');

my $second = $syc->validate( a => 'a', b => 'b' );
isa_ok($second,'Syccess::Result');
ok(!$second->success,'second result is invalid');
my @second_errors = @{$second->errors};
is(scalar @second_errors,2,'second result has two errors');
is($second_errors[0]->message,'A must be a number.','second result first error message is ok');
is($second_errors[1]->message,'American Horror Story rulez','second result second error message is ok');

done_testing;
