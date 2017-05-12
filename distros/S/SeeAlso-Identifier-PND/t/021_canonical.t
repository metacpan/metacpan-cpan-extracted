# -*- perl -*-

# t/020_values.t - check illegal values

use Test::More tests => 83;

use SeeAlso::Identifier::PND;

# new
my $object = SeeAlso::Identifier::PND->new ();

# assign value
is($object->canonical("132010445"), undef, "valid 9 digits");
is($object->canonical("13201044-5"), undef, "valid 9 digits with dash");
is($object->canonical("PND:132010445"), undef, "valid 9 digits with prefix");
is($object->canonical("http://d-nb.info/gnd/132010445"), "http://d-nb.info/gnd/132010445", "valid 9 digits URI");

is($object->canonical("188416994"), undef, "valid 9 digits 2011");

is($object->canonical("http://d-nb.info/gnd/13201044"), "", "too short");
is($object->canonical("http://d-nb.info/gnd/1320104-4"), "", "too short with dash");
is($object->canonical("http://d-nb.info/gnd/13201044"), "", "too short URI");

is($object->canonical("1011171872"), undef, "valid 10 digits");
is($object->canonical("101117187-2"), undef, "valid 10 digits with dash");
is($object->canonical("PND:1011171872"), undef, "valid 10 digits with prefix");
is($object->canonical("http://d-nb.info/gnd/1011171872"), "http://d-nb.info/gnd/1011171872", "valid 10 digits URI");

is($object->canonical("http://d-nb.info/gnd/10111718723"), "", "too long");
is($object->canonical("http://d-nb.info/gnd/1011171872-3"), "", "too long with dash");
is($object->canonical("http://d-nb.info/gnd/PND:10111718723"), "", "too long with prefix");
is($object->canonical("http://d-nb.info/gnd/10111718723"), "", "too long URI");

is($object->canonical("http://d-nb.info/gnd/119653826"), "http://d-nb.info/gnd/119653826", "store valid checksum 6");
is($object->value(), "119653826", "retrieve valid checksum 6");
is($object->canonical("http://d-nb.info/gnd/119653820"), "", "store invalid checksum 0");
is($object->value(), "119653820", "retrieve invalid checksum 0");

is($object->canonical("http://d-nb.info/gnd/119653820"), "", "request invalid checksum 0");
is($object->canonical("http://d-nb.info/gnd/119653821"), "", "invalid checksum 1");
is($object->canonical("http://d-nb.info/gnd/119653822"), "", "invalid checksum 2");
is($object->canonical("http://d-nb.info/gnd/119653823"), "", "invalid checksum 3");
is($object->canonical("http://d-nb.info/gnd/119653824"), "", "invalid checksum 4");
is($object->canonical("http://d-nb.info/gnd/119653825"), "", "invalid checksum 5");
ok($object->canonical("http://d-nb.info/gnd/119653826") && $object->valid(), "valid checksum 6");
is($object->canonical("http://d-nb.info/gnd/119653827"), "", "invalid checksum 7");
is($object->canonical("http://d-nb.info/gnd/119653828"), "", "invalid checksum 8");
is($object->canonical("http://d-nb.info/gnd/119653829"), "", "invalid checksum 9");
is($object->canonical("http://d-nb.info/gnd/11965382X"), "", "invalid checksum X");

is($object->canonical("http://d-nb.info/gnd/13201044"), "", "too short");
is($object->canonical("http://d-nb.info/gnd/1320104-4"), "", "too short with dash");
is($object->canonical("http://d-nb.info/gnd/PND:13201044"), "", "too short with prefix");
is($object->canonical("http://d-nb.info/gnd/13201044"), "", "too short URI");

is($object->canonical("http://d-nb.info/gnd/1196538262"), "", "too long");
is($object->canonical("http://d-nb.info/gnd/119653826-2"), "", "too long, with dash");
is($object->canonical("http://d-nb.info/gnd/1196 538262"), "", "too long, with spaces");
is($object->canonical("http://d-nb.info/gnd/1196538262"), "", "too long URI");

is($object->canonical("http://d-nb.info/gnd/1948-8352"), "", "wrong checksum");
is($object->canonical("http://d-nb.info/gnd/19488352"), "", "wrong checksum, with dash");
is($object->canonical("http://d-nb.info/gnd/1948 8352"), "", "wrong checksum, with spaces");

is($object->canonical("http://d-nb.info/gnd/0"), "", "invalid zero");
is($object->canonical("http://d-nb.info/gnd/"), "", "empty string");
is($object->canonical(""), undef, "really empty string");
is($object->canonical(undef), "", "undef");
is($object->canonical(), "", "emtpy arg");

ok($object->canonical("http://d-nb.info/gnd/15617913X") && $object->valid(), "valid checksum X");
ok($object->canonical("http://d-nb.info/gnd/15617913x") && $object->valid(), "valid checksum x");
is($object->canonical("http://d-nb.info/gnd/15617913Y"), "", "invalid checksum Y");
is($object->canonical("http://d-nb.info/gnd/15617913-"), "", "invalid checksum -");

# conversions
is($object->canonical("http://d-nb.info/gnd/188416994"), "http://d-nb.info/gnd/188416994", "valid 9 digits 2011 URI again");
is($object->value(), "188416994", "valid 9 digits 2011 value");
is($object->hash(), "188416994", "valid 9 digits 2011 hash");
is($object->indexed(), $object->hash(), "valid 9 digits 2011 indexed");
is($object->canonical(), "http://d-nb.info/gnd/188416994", "valid 9 digits 2011 canonical");
is($object->normalized(), $object->canonical(), "valid 9 digits 2011 normalized");
is("$object", $object->canonical(), "valid 9 digits 2011 stringification");
is($object->pretty(), "188416994", "valid 9 digits 2011 pretty");

is($object->canonical("http://d-nb.info/gnd/132010445"), "http://d-nb.info/gnd/132010445", "valid 9 digits URI again");
is($object->value(), "132010445", "valid 9 digits value");
is($object->hash(), "132010445", "valid 9 digits hash");
is($object->indexed(), $object->hash(), "valid 9 digits indexed");
is($object->canonical(), "http://d-nb.info/gnd/132010445", "valid 9 digits canonical");
is($object->normalized(), $object->canonical(), "valid 9 digits normalized");
is("$object", $object->canonical(), "valid 9 digits stringification");
is($object->pretty(), "132010445", "valid 9 digits pretty");

is($object->canonical("http://d-nb.info/gnd/1011171872"), "http://d-nb.info/gnd/1011171872", "valid 10 digits URI again");
is($object->value(), "1011171872", "valid 10 digits value");
is($object->hash(), "1011171872", "valid 10 digits hash");
is($object->indexed(), $object->hash(), "valid 10 digits indexed");
is($object->canonical(), "http://d-nb.info/gnd/1011171872", "valid 10 digits canonical");
is($object->normalized(), $object->canonical(), "valid 10 digits normalized");
is("$object", $object->canonical(), "valid 10 digits stringification");
is($object->pretty(), "1011171872", "valid 10 digits pretty");

is($object->canonical("http://d-nb.info/gnd/1100110011"), "http://d-nb.info/gnd/1100110011", "valid 10 digits again");
is($object->value(), "1100110011", "valid 10 digits value");
is($object->hash(), "1100110011", "valid 10 digits hash");
is($object->indexed(), $object->hash(), "valid 10 digits indexed");
is($object->canonical(), "http://d-nb.info/gnd/1100110011", "valid 10 digits canonical");
is($object->normalized(), $object->canonical(), "valid 10 digits normalized");
is("$object", $object->canonical(), "valid 10 digits stringification");
is($object->pretty(), "1100110011", "valid 10 digits pretty");

