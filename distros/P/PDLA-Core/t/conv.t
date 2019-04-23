# Test conversions. This is not yet good enough: we need
# nasty test cases,

# 1.9901 - converted to new type semantics + extra test

use Test::More tests => 7;

use strict;
use warnings;

use PDLA::LiteF;
use PDLA::Types;
use PDLA::Constants qw(PI);
use strict;
use warnings;

my $pa = pdl 42.4;
note "A is $pa";

is($pa->get_datatype,$PDLA_D, "A is double");

my $pb = byte $pa;
note "B (byte $pa) is $pb";

is($pb->get_datatype,$PDLA_B, "B is byte");
is($pb->at(),42, 'byte value is 42');

my $pc = $pb * 3;
is($pc->get_datatype, $PDLA_B, "C also byte");
note "C ($pb * 3) is $pc";

my $pd = $pb * 600.0;
is($pd->get_datatype, $PDLA_F, "D promoted to float");
note "D ($pb * 600) is $pd";

my $pi = 4*atan2(1,1);

my $pe = $pb * $pi;
is($pe->get_datatype, $PDLA_D, "E promoted to double (needed to represent result)");
note "E ($pb * PI) is $pe";

my $pf = $pb * "-2.2";
is($pf->get_datatype, $PDLA_D, "F check string handling");
note "F ($pb * string(-2.2)) is $pf";
