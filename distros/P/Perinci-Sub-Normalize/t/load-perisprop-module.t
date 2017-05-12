#!perl

use 5.010;
use strict;
use warnings;

use Perinci::Sub::Normalize qw(normalize_function_metadata);
use Test::Exception;
use Test::More 0.98;

subtest retry => sub {
    plan skip_all => "Perinci::Sub::Property::retry 0.10 not installed"
        unless eval "use Perinci::Sub::Property::retry 0.10; 1";

    is_deeply(normalize_function_metadata({v=>1.1, retry=>2}),
              {v=>1.1, retry=>2});
};

subtest retry => sub {
    plan skip_all => "Perinci::Sub::Property::result::table 0.08 not installed"
        unless eval "use Perinci::Sub::Property::result::table 0.08; 1";

    is_deeply(normalize_function_metadata({v=>1.1, result=>{table=>{}}}),
              {v=>1.1, result=>{table=>{}}});
};

dies_ok { normalize_function_metadata({v=>1.1, foo=>1}) }
        "doesn't allow unknown properties";
dies_ok { normalize_function_metadata({v=>1.1, result=>{foo=>1}}) }
        "doesn't allow unknown result properties";

DONE_TESTING:
done_testing();
