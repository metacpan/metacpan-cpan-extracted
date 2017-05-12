#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Syccess;

my $syc = Syccess->new(
  fields => [
    a => [ in => [qw( a b c )] ],
  ],
);

isa_ok($syc,'Syccess');

my $first = $syc->validate( a => 'a' );
isa_ok($first,'Syccess::Result');
ok($first->success,'first result is valid');

my $second = $syc->validate( a => 'd' );
isa_ok($second,'Syccess::Result');
ok(!$second->success,'second result is invalid');
my @second_errors = @{$second->errors};
is(scalar @second_errors,1,'second result has one error');
is($second_errors[0]->message,'This value for A is not allowed.','second result first error message is ok');

done_testing;
