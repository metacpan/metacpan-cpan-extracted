# Testing Random::Skew

use strict;
use warnings;

use English qw(-no_match_vars);

use Test::More;
#use Test::NoWarnings 'had_no_warnings';

use Random::Skew;



my $r;
eval {
    $r = Random::Skew::ROUNDING( 'xxx' );
};
ok($EVAL_ERROR =~ /ROUNDING must be decimal-point and digits only/,"Floating point ROUNDING gripe 1");



eval {
    $r = Random::Skew::ROUNDING( 33.3 );
};
ok($EVAL_ERROR =~ /ROUNDING must be between 0.0 and 1.0/,"ROUNDING range gripe");



$r = Random::Skew::ROUNDING( .3 );
is($Random::Skew::ROUNDING,.3,"ROUNDING is set");



#had_no_warnings;
done_testing();
