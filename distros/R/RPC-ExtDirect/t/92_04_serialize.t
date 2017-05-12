use strict;
use warnings;
no  warnings 'once';

use Test::More;

if ( $ENV{REGRESSION_TESTS} ) {
    plan tests => 3;
}
else {
    plan skip_all => 'Regression tests are not enabled.';
}

# We will test deprecated API and don't want the warnings
# cluttering STDERR
$SIG{__WARN__} = sub {};

use RPC::ExtDirect::Serialize;

local $RPC::ExtDirect::Serialize::DEBUG = 1;

my $data     = { foo => 'foo', qux => 'qux', bar => 'bar' };
my $expected = '{"bar":"bar","foo":"foo","qux":"qux"}';

my $json = RPC::ExtDirect::Serialize->serialize(0, $data);

is $json, $expected, "Canonical output";

$data     = bless { foo => 'foo', };
$expected = q|{"action":null,"message":"encountered object 'main=HASH(blessed)'","method":null,"tid":null,"type":"exception","where":"RPC::ExtDirect::Serializer"}|;

$json = RPC::ExtDirect::Serialize->serialize(0, $data);

$json =~ s/HASH\([^\)]+\)[^"]+/HASH(blessed)'/;

is $json, $expected, 'Invalid data, exceptions on';

$expected = undef;

$json = RPC::ExtDirect::Serialize->serialize(1, $data);

is $json, $expected, 'Ivalid data, exceptions off';

