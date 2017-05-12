#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::Intervals::Numeric';

my $obj = Music::Intervals::Numeric->new;
isa_ok $obj, 'Music::Intervals::Numeric', 'default args';

my $chord = '1/1 5/4 3/2';
$obj = Music::Intervals::Numeric->new(
    freq => 1,
    interval => 1,
    cent => 1,
    prime => 1,
    notes => [qw( 1/1 5/4 3/2 )],
);
isa_ok $obj, 'Music::Intervals::Numeric';
$obj->process;

is_deeply $obj->frequencies,
    { "1/1 5/4 3/2" => { "1/1" => "C unison, perfect prime, tonic", "3/2" => "G perfect fifth", "5/4" => "E major third" } },
    'frequencies';
is_deeply $obj->intervals,
    { "1/1 5/4 3/2" => { "1/1 3/2" => { "3/2" => "G perfect fifth" }, "1/1 5/4" => { "5/4" => "E major third" }, "5/4 3/2" => { "6/5" => "Eb minor third" } } },
    'intervals';
is sprintf('%.3f', $obj->cent_vals->{$chord}{'1/1 5/4'}), '386.314', 'cent_vals 1/1 5/4';
is sprintf('%.3f', $obj->cent_vals->{$chord}{'1/1 3/2'}), '701.955', 'cent_vals 1/1 3/2';
is sprintf('%.3f', $obj->cent_vals->{$chord}{'5/4 3/2'}), '315.641', 'cent_vals 5/4 3/2';
is_deeply $obj->prime_factor,
    { "1/1 5/4 3/2" => { "1/1 3/2" => { "3/2" => "(3) / (2)" }, "1/1 5/4" => { "5/4" => "(5) / (2*2)" }, "5/4 3/2" => { "6/5" => "(2*3) / (5)" } } },
    'prime_factor';

done_testing();
