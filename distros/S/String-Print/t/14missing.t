#!/usr/bin/env perl
# Test reporting of missing parameters

use warnings;
use strict;

use Test::More;

use String::Print;

my $f = String::Print->new;
isa_ok($f, 'String::Print');

is $f->sprinti('testA {a}', a => undef), 'testA undef', 'undef is not missing';

my $warning;
$SIG{__WARN__} = sub { $warning = join '/', @_ };
my $file = __FILE__;
my $line = __LINE__ + 1;
is $f->sprinti('testB {b}'), 'testB undef', 'missing';
is $warning, "Missing key 'b' in format 'testB {b}', file $file line $line\n";


done_testing;
