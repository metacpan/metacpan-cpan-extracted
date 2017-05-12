# -*- perl -*-

# t/020_values.t - check illegal values

use Test::More tests => 78;

use SeeAlso::Identifier::PND;

# new
my $object = SeeAlso::Identifier::PND->new ();

# get value
is($object->value("132010445"), "132010445", "valid 9 digits");
is($object->value("13201044-5"), "", "valid 9 digits with dash are invalid");
is($object->value("PND:132010445"), "132010445", "valid 9 digits with prefix");
is($object->value("(DE-588)132010445"), "132010445", "valid 9 digits with MARC prefix");
is($object->value("http://d-nb.info/gnd/132010445"), "132010445", "valid 9 digits URI");

is($object->value("188416994"), "188416994", "valid 9 digits 2011");

is($object->value("13201044"), "", "too short");
is($object->value("1320104-4"), "", "too short with dash");
is($object->value("PND:13201044"), "", "too short with prefix");
is($object->value("http://d-nb.info/gnd/13201044"), "", "too short URI");

is($object->value("1011171872"), "1011171872", "valid 10 digits");
is($object->value("101117187-2"), "", "valid 10 digits with dash are not valid");
is($object->value("PND:1011171872"), "1011171872", "valid 10 digits with prefix ':'");
is($object->value("PND 1011171872"), "1011171872", "valid 10 digits with prefix ' '");
is($object->value("PND/1011171872"), "1011171872", "valid 10 digits with prefix '/'");
is($object->value("PND-1011171872"), "1011171872", "valid 10 digits with prefix '-'");
is($object->value("http://d-nb.info/gnd/1011171872"), "1011171872", "valid 10 digits URI");
is($object->value("(DE-588a)1011171872"), "1011171872", "MARC-prefixed PND number");
is($object->value("(DE-588)1011171872"), "1011171872", "MARC-prefixed GND number");

is($object->value("10111718723"), "", "too long");
is($object->value("1011171872-3"), "", "too long with dash");
is($object->value("PND:10111718723"), "", "too long with prefix");
is($object->value("http://d-nb.info/gnd/10111718723"), "", "too long URI");

ok($object->value("119653820") && ! $object->valid(), "invalid checksum 0");
ok($object->value("119653821") && ! $object->valid(), "invalid checksum 1");
ok($object->value("119653822") && ! $object->valid(), "invalid checksum 2");
ok($object->value("119653823") && ! $object->valid(), "invalid checksum 3");
ok($object->value("119653824") && ! $object->valid(), "invalid checksum 4");
ok($object->value("119653825") && ! $object->valid(), "invalid checksum 5");
ok($object->value("119653826") && $object->valid(), "valid checksum 6");
ok($object->value("119653827") && ! $object->valid(), "invalid checksum 7");
ok($object->value("119653828") && ! $object->valid(), "invalid checksum 8");
ok($object->value("119653829") && ! $object->valid(), "invalid checksum 9");
ok($object->value("11965382X") && ! $object->valid(), "invalid checksum X");

is($object->value("13201044"), "", "too short");
is($object->value("1320104-4"), "", "too short with dash");
is($object->value("PND:13201044"), "", "too short with prefix");
is($object->value("http://d-nb.info/gnd/13201044"), "", "too short URI");

is($object->value("11965382672"), "", "too long");
is($object->value("1196538267-2"), "", "too long, with dash");
is($object->value("1196 5382672"), "", "too long, with spaces");
is($object->value("http://d-nb.info/gnd/11965382672"), "", "too long URI");

is($object->value("1948-8352"), "", "wrong checksum");
is($object->value("19488352"), "", "wrong checksum, with dash");
is($object->value("1948 8352"), "", "wrong checksum, with spaces");
is($object->value("http://d-nb.info/gnd/1948-8352"), "", "wrong checksum URI");

is($object->value("0"), "", "invalid zero");
is($object->value(""), "", "empty string");
is($object->value(undef), "", "undef");
is($object->value(), "", "emtpy arg");

ok($object->value("15617913X") && $object->valid(), "valid checksum X");
ok($object->value("15617913x") && $object->valid(), "valid checksum x");
is($object->value("15617913Y"), "", "invalid checksum Y");
is($object->value("15617913-X"), "", "invalid checksum -");

# conversions
is($object->value("132010445"), "132010445", "valid 9 digits again");
is($object->value(), "132010445", "valid 9 digits value");
is($object->hash(), "132010445", "valid 9 digits hash");
is($object->indexed(), $object->hash(), "valid 9 digits indexed");
is($object->canonical(), "http://d-nb.info/gnd/132010445", "valid 9 digits canonical");
is($object->normalized(), $object->canonical(), "valid 9 digits normalized");
is("$object", $object->canonical(), "valid 9 digits stringification");
is($object->pretty(), "132010445", "valid 9 digits pretty");

is($object->value("1011171872"), "1011171872", "valid 10 digits again");
is($object->value(), "1011171872", "valid 10 digits value");
is($object->hash(), "1011171872", "valid 10 digits hash");
is($object->indexed(), $object->hash(), "valid 10 digits indexed");
is($object->canonical(), "http://d-nb.info/gnd/1011171872", "valid 10 digits canonical");
is($object->normalized(), $object->canonical(), "valid 10 digits normalized");
is("$object", $object->canonical(), "valid 10 digits stringification");
is($object->pretty(), "1011171872", "valid 10 digits pretty");

is($object->value("1100110011"), "1100110011", "valid 10 digits again");
is($object->value(), "1100110011", "valid 10 digits value");
is($object->hash(), "1100110011", "valid 10 digits hash");
is($object->indexed(), $object->hash(), "valid 10 digits indexed");
is($object->canonical(), "http://d-nb.info/gnd/1100110011", "valid 10 digits canonical");
is($object->normalized(), $object->canonical(), "valid 10 digits normalized");
is("$object", $object->canonical(), "valid 10 digits stringification");
is($object->pretty(), "1100110011", "valid 10 digits pretty");

