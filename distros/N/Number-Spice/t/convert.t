#!perl -w
use strict;
use Test;
BEGIN {
    plan(tests => 34);
}

# import the module
eval "use Number::Spice qw(:all);";
ok(length($@) == 0) or die $@; # 1

# standard spice to number conversions
ok(spice_to_number('1t'),1e12); # 2
ok(spice_to_number('1g'),1e9); # 3
ok(spice_to_number('1meg'),1e6); # 4
ok(spice_to_number('1x'),1e6); # 5
ok(spice_to_number('1k'),1e3); # 6
ok(spice_to_number('1'),1); # 7
ok(spice_to_number('1m'),1e-3); # 8
ok(spice_to_number('1mil'),2.54e-5); # 9
ok(spice_to_number('1u'),1e-6); # 10
ok(spice_to_number('1n'),1e-9); # 11
ok(spice_to_number('1p'),1e-12); # 12
ok(spice_to_number('1f'),1e-15); # 13
ok(spice_to_number('1a'),1e-18); # 14

# standard number to spice conversions
ok(number_to_spice(1e12),'1t'); # 15
ok(number_to_spice(1e9),'1g'); # 16
ok(number_to_spice(1e6),'1meg'); # 17
ok(number_to_spice(1e3),'1k'); # 18
ok(number_to_spice(1e0),'1'); # 19
ok(number_to_spice(1e-3),'1m'); # 20
ok(number_to_spice(1e-6),'1u'); # 21
ok(number_to_spice(1e-9),'1n'); # 22
ok(number_to_spice(1e-12),'1p'); # 23
ok(number_to_spice(1e-15),'1f'); # 24
ok(number_to_spice(1e-18),'1a'); # 25
ok(number_to_spice(1e-21),'1e-21'); # 26

# advanced and pathological conversions
ok(normalize_spice_number('3.3V'),'3.3'); # 27
ok(!is_spice_number('1.0E')); # 28
ok(normalize_spice_number('1.0EE'),'1'); # 29
ok(normalize_spice_number('3.0E1KVOLT'),'30k'); # 30
ok(normalize_spice_number('1000mil'),'25.4m'); # 31
ok(normalize_spice_number('0.00000e88'),'0'); # 32
ok(normalize_spice_number('-1.2e-3'),'-1.2m'); # 33
ok(normalize_spice_number('-0.999e-15'),'-999a'); # 34

__END__
