# Testing Random::Skew

use strict;
use warnings;

use English qw(-no_match_vars);

use Test::More;
#use Test::NoWarnings 'had_no_warnings';

use Random::Skew;



eval {
    Random::Skew->new();
};
ok($EVAL_ERROR =~ /Random::Skew->new: No parameters/,"No parameters gripe");


eval {
    Random::Skew->new(
        x => 'ouch',
    );
};
ok($EVAL_ERROR =~ /Value .* for key .* must be a number >= 1/,"Must be number>=1 warning 1");


eval {
    Random::Skew->new(
        okfine => 10,
        toosmall => 0.1,
    );
};
ok($EVAL_ERROR =~ /Value .* for key .* must be a number >= 1/,"Must be number>=1 warning 2");



my $rs = Random::Skew->new(
    whatever => 5,
);
isa_ok($rs,"Random::Skew");


#had_no_warnings;
done_testing();
