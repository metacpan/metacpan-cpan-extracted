use strict;
use warnings;
use Test::More tests => 6;
use constant EPS => 1e-2;

BEGIN { use_ok('Statistics::SDT') };

my $val;

# test inverse-phi access from Math::Cephes and return value
eval { $val = Statistics::SDT::ndtri(.05)  };

ok(!$@);

ok( about_equal($val, -1.64), "z by Math::Cephes::ndtri $val != -1.64");

# Smith (1982) examples (ensuring are using what his method expects):
$val = Statistics::SDT::ndtri(1-.5);
ok( about_equal($val, 0), "z by Math::Cephes::ndtri $val != 0");

#$val = Statistics::SDT::ndtri(1-0.1586);
#ok( about_equal($val, 1), "z by Math::Cephes::ndtri $val != 1");


# test log10 from Math::Cephes and return value
eval { $val = Statistics::SDT::log10(2)  };

ok(!$@);

ok( about_equal($val, 0.301), "z by Math::Cephes::ndtri $val != 0.301");

sub about_equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}