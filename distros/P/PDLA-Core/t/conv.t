# Test conversions. This is not yet good enough: we need
# nasty test cases,

# 1.9901 - converted to new type semantics + extra test

use Test::More tests => 7;

use strict;
use warnings;

use PDLA::LiteF;
use PDLA::Types;

my $pa = pdl 42.4;
note "A is $pa";

is($pa->get_datatype,$PDLA_D);

my $pb = byte $pa;
note "B (byte $pa) is $pb";

is($pb->get_datatype,$PDLA_B);
is($pb->at(),42);

my $pc = $pb * 3;
is($pc->get_datatype, $PDLA_B); # $pc is the same
note "C ($pb * 3) is $pc";

my $pd = $pb * 600.0;
is($pd->get_datatype, $PDLA_F); # $pd is promoted to float
note "D ($pb * 600) is $pd";

my $pi = 4*atan2(1,1);

my $pe = $pb * $pi;
is($pe->get_datatype, $PDLA_D); # $pe needs to be double to represent result
note "E ($pb * $pi) is $pe";

my $pf = $pb * "-2.2";
is($pf->get_datatype, $PDLA_D); # $pe check strings are handled ok
note "F ($pb * string(-2.2)) is $pf";

