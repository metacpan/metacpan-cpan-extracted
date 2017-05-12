use Test::More tests => 8;

use Net::OpenSoundControl;

# test to/from functions

sub toTest {
    is(unpack("H*", $_[0]), $_[1]);
}

# floats
is(Net::OpenSoundControl::fromFloat(Net::OpenSoundControl::toFloat(-1)), -1);
is(Net::OpenSoundControl::fromFloat(Net::OpenSoundControl::toFloat(1)),  1);

# floats from the spec
toTest(Net::OpenSoundControl::toFloat(440.0), '43dc0000');
toTest(Net::OpenSoundControl::toFloat(1.234), '3f9df3b6');
toTest(Net::OpenSoundControl::toFloat(5.678), '40b5b22d');

cmp_ok(Net::OpenSoundControl::fromFloat(pack("H*", '43dc0000')), '==', 440.0);

# fractions won't work this way due to rounding problems, so we
# leave away the two other tests.

# ints from the spec
toTest(Net::OpenSoundControl::toInt(1000), '000003e8');
toTest(Net::OpenSoundControl::toInt(-1),   'ffffffff');
