#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Syccess;

my $syc = Syccess->new(
  fields => [
    a => [ code => sub { $_ eq 'a' ? () : (undef) } ],
    b => [ code => {
      arg => sub { $_ eq 'b' ? () : (undef) },
      message => 'MUST BE B.',
    } ],
    c => [ code => {
      arg => sub { $_ eq 'c' ? () : (undef,'AND ANOTHER ERROR!') },
      message => 'MUST BE C.',
    } ],
  ],
);

isa_ok($syc,'Syccess');

my $first = $syc->validate( a => 'a', b => 'b', c => 'c' );
isa_ok($first,'Syccess::Result');
ok($first->success,'first result is valid');

my $second = $syc->validate( a => 'd', b => 'd', c => 'd' );
isa_ok($second,'Syccess::Result');
ok(!$second->success,'second result is invalid');
my @second_errors = @{$second->errors};
is(scalar @second_errors,4,'second result has four errors');
is($second_errors[0]->message,'Your value for A is not valid.','second result first error message is ok');
is($second_errors[1]->message,'MUST BE B.','second result second error message is ok');
is($second_errors[2]->message,'MUST BE C.','second result third error message is ok');
is($second_errors[3]->message,'AND ANOTHER ERROR!','second result forth error message is ok');
my @c_second_errors = @{$second->errors('c')};
is(scalar @c_second_errors,2,'second result has two errors for field c');

done_testing;
