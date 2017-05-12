#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Syccess;

my $syc = Syccess->new(
  fields => [
    a => [ required => 1, label => 'Voodoo' ],
    b => [ required => { message => 'You have 5 seconds to comply.' } ],
  ],
);

isa_ok($syc,'Syccess');

my $first = $syc->validate( a => 1, b => 1 );
isa_ok($first,'Syccess::Result');
ok($first->success,'first result is valid');

my $second = $syc->validate( a => 1 );
isa_ok($second,'Syccess::Result');
ok(!$second->success,'second result is invalid');
my @second_errors = @{$second->errors};
is(scalar @second_errors,1,'second result has one error');
is($second_errors[0]->message,'You have 5 seconds to comply.','second result error message is custom');
is($second_errors[0]->syccess_field->name,'b','second result error has correct field');
my @a_second_errors = @{$second->errors('b')};
is(scalar @a_second_errors,1,'second result has one error for field b');

my $third = $syc->validate( b => 1 );
ok(!$third->success,'third result is invalid');
my @third_errors = @{$third->errors};
is(scalar @third_errors,1,'third result has one error');
is($third_errors[0]->message,'Voodoo is required.','third result error message is standard');
is($third_errors[0]->syccess_field->name,'a','third result error has correct field');

done_testing;
