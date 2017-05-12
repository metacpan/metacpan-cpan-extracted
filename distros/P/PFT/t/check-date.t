#!/usr/bin/perl -w

use v5.16;

use strict;
use warnings;
use utf8;

use PFT::Date;

use Test::More;

ok(!PFT::Date->new(undef, 2, 3)->complete, 'Complete 1');
ok(!PFT::Date->new(1, undef, 3)->complete, 'Complete 2');
ok(!PFT::Date->new(1, 2, undef)->complete, 'Complete 3');
ok(PFT::Date->new(0, 2, 3)->complete, 'Complete 5');
ok(PFT::Date->new(1, 2, 3)->complete, 'Complete 4');

is(
    PFT::Date->new(1, 2, 3)->repr,
    '0001-02-03',
    'represented'
);

is_deeply(
    PFT::Date->new(1, 2, 3)->to_hash,
    { y=>1, m=>2, d=>3 },
    'hash'
);

is(
    PFT::Date->new(1, 2)->derive(m => 3)->repr,
    '0001-03-*',
    'derive'
);

is(
    PFT::Date->new(1, 2)->derive(y => undef, m => 3)->repr,
    '*-03-*',
    'derive'
);

is(
    PFT::Date->new(1, undef, 3)->repr,
    '0001-*-03',
    'derive'
);

is(
    PFT::Date->from_spec(y => 2000, m => 'january', d => 12)->repr,
    '2000-01-12',
    'human-friendly',
);

is_deeply(
    PFT::Date->from_string('1999-08-02')->to_hash,
    { y=>1999, m=>8, d=>2 },
    'repr from string',
);

eval { PFT::Date->from_string('09-08-02')->to_hash };
isnt($@, undef, 'parse error');

my $date = PFT::Date->new(5, 5, 5);
cmp_ok($date, '<', PFT::Date->new(6, 4, 9), 'Date cmp y');
cmp_ok($date, '<', PFT::Date->new(5, 6, 9), 'Date cmp m');
cmp_ok($date, '<', PFT::Date->new(5, 5, 6), 'Date cmp d');
cmp_ok($date, '>', PFT::Date->new(5, 5, 4), 'Date cmp >');

cmp_ok($date, '<=', PFT::Date->new(6, 4, 9), 'Date cmp y=');
cmp_ok($date, '<=', PFT::Date->new(5, 6, 9), 'Date cmp m=');
cmp_ok($date, '<=', PFT::Date->new(5, 5, 6), 'Date cmp d=');
cmp_ok($date, '>=', PFT::Date->new(5, 5, 4), 'Date cmp >=');

cmp_ok($date, '>', PFT::Date->new(5, 5), 'Date cmp incomplete 1');
cmp_ok($date, '>', PFT::Date->new(5), 'Date cmp incomplete 2');
cmp_ok($date, '>', PFT::Date->new, 'Date cmp incomplete 3');

done_testing()
