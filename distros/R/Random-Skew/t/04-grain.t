# Testing Random::Skew

use strict;
use warnings;

use English qw(-no_match_vars);

use Test::More;
#use Test::NoWarnings 'had_no_warnings';

use Random::Skew;



my $g;
eval {
    $g = Random::Skew::GRAIN( 'xxx' );
};
ok($EVAL_ERROR =~ /GRAIN must be a positive integer/,"Noninteger GRAIN gripe 1");



eval {
    $g = Random::Skew::GRAIN( 33.3 );
};
ok($EVAL_ERROR =~ /GRAIN must be a positive integer/,"Noninteger GRAIN gripe 2");



eval {
    $g = Random::Skew::GRAIN( 1 );
};
ok($EVAL_ERROR =~ /GRAIN must be >= 2/,"Insufficient GRAIN gripe");


$g = Random::Skew::GRAIN( 33 );
is($Random::Skew::GRAIN,33,"Grain is set");


#had_no_warnings;
done_testing();
