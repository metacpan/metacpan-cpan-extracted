#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Syccess;

my $syc = Syccess->new(
  fields => [
    a => [ length => 4 ],
    b => [ length => { min => 4 }, label => 'Bar' ],
    c => [ length => { max => 8 } ],
    d => [ length => { min => 2, max => 6 }, label => 'Foo' ],
  ],
);

isa_ok($syc,'Syccess');

my $first = $syc->validate( a => 1234, b => 12345, c => 12, d => 1234 );
isa_ok($first,'Syccess::Result');
ok($first->success,'first result is valid');

my $second = $syc->validate( a => 1, b => 1, c => 123456789, d => 1 );
isa_ok($second,'Syccess::Result');
ok(!$second->success,'second result is invalid');
my @second_errors = @{$second->errors};
is(scalar @second_errors,4,'second result has four error');
is($second_errors[0]->message,'A must be exactly 4 characters.','second result first error message is ok');
is($second_errors[1]->message,'Bar must be at least 4 characters.','second result second error message is ok');
is($second_errors[2]->message,'C is not allowed to be more than 8 characters.','second result third error message is ok');
is($second_errors[3]->message,'Foo must be between 2 and 6 characters.','second result fourth error message is ok');
my @a_second_errors = @{$second->errors('a')};
is(scalar @a_second_errors,1,'second result has one error for field a');
my @b_second_errors = @{$second->errors('b')};
is(scalar @b_second_errors,1,'second result has one error for field b');
my @c_second_errors = @{$second->errors('c')};
is(scalar @c_second_errors,1,'second result has one error for field c');
my @d_second_errors = @{$second->errors('d')};
is(scalar @d_second_errors,1,'second result has one error for field d');

my $third = $syc->validate( a => 1, b => 1 );
ok(!$third->success,'third result is invalid');
my @third_errors = @{$third->errors};
is(scalar @third_errors,2,'third result has two errors');
is($third_errors[0]->syccess_field->name,'a','third result first error has correct field');
is($third_errors[1]->syccess_field->name,'b','third result second error has correct field');

done_testing;
