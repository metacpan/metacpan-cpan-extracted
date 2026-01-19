#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'Music::Intervals::Numeric';

subtest frequencies => sub {
    my $obj = new_ok 'Music::Intervals::Numeric';
    is_deeply $obj->frequencies,
        { "1/1" => "unison, perfect prime, tonic",
          "3/2" => "perfect fifth",
          "5/4" => "5-limit major third, 5th harmonic" },
        'frequencies';
};

subtest intervals => sub {
    my $obj = new_ok 'Music::Intervals::Numeric';
    is_deeply $obj->intervals,
        { "1/1 3/2" => { "3/2" => "perfect fifth" },
          "1/1 5/4" => { "5/4" => "5-limit major third, 5th harmonic" },
          "5/4 3/2" => { "6/5" => "5-limit minor third" } },
        'intervals';
};

subtest cent_vals => sub {
    my $obj = new_ok 'Music::Intervals::Numeric';
    is sprintf('%.3f', $obj->cent_vals->{'1/1 5/4'}), '386.314', 'cent_vals 1/1 5/4';
    is sprintf('%.3f', $obj->cent_vals->{'1/1 3/2'}), '701.955', 'cent_vals 1/1 3/2';
    is sprintf('%.3f', $obj->cent_vals->{'5/4 3/2'}), '315.641', 'cent_vals 5/4 3/2';
};

subtest prime_factor => sub {
    my $obj = new_ok 'Music::Intervals::Numeric';
    is_deeply $obj->prime_factor,
        { "1/1 3/2" => { "3/2" => "(3) / (2)" },
          "1/1 5/4" => { "5/4" => "(5) / (2*2)" },
          "5/4 3/2" => { "6/5" => "(2*3) / (5)" } },
        'prime_factor';
};

subtest lives => sub {
    my $obj = new_ok 'Music::Intervals::Numeric' => [ notes => ['1/1'] ];
    lives_ok { $obj->frequencies } 'frequencies';
    lives_ok { $obj->intervals } 'intervals';
    lives_ok { $obj->cent_vals } 'cent_vals';
    lives_ok { $obj->prime_factor } 'prime_factor';
};

done_testing();
