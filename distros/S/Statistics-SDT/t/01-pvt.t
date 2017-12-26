use strict;
use warnings;
use Test::More tests => 7;
use constant EPS => 1e-2;

BEGIN { use_ok('Statistics::SDT') };

my $val;

# test sign method
$val = Statistics::SDT::_sign(2);
ok( about_equal($val, 1), "sign method $val != 1");

$val = Statistics::SDT::_sign(-2);
ok( about_equal($val, -1), "sign method $val != -1");

# test valid probability value method
$val = Statistics::SDT::_valid_p(2);
ok( about_equal($val, 0), "valid_p method $val != 0");

$val = Statistics::SDT::_valid_p(-.2);
ok( about_equal($val, 0), "valid_p method $val != 0");

$val = Statistics::SDT::_sign(.301);
ok( about_equal($val, 1), "sign method $val != 1");


# test precisioned method
$val = Statistics::SDT::_precisioned(2, .301);
$val =~ /([^\.]+)$/;
ok( length($1) == 2, "precisioned method $val != .30");

sub about_equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}