# -*- perl -*-

# t/022_hash.t - check constuctor

use Test::More tests => 74;

use SeeAlso::Identifier::PND;

# new
my $object = SeeAlso::Identifier::PND->new ();

# get value
is($object->hash("132010445"), "132010445", "valid 9 digits");
is($object->hash("13201044-5"), undef, "valid 9 digits with dash");
is($object->hash("PND:132010445"), undef, "valid 9 digits with prefix");
is($object->hash("http://d-nb.info/gnd/132010445"), undef, "valid 9 digits URI");

is($object->hash("188416994"), "188416994", "valid 9 digits 2011");

is($object->hash("13201044"), undef, "too short");
is($object->hash("1320104-4"), undef, "too short with dash");
is($object->hash("13201044"), undef, "too short URI");

is($object->hash("1011171872"), "1011171872", "valid 10 digits");
is($object->hash("101117187-2"), undef, "valid 10 digits with dash");
is($object->hash("PND:1011171872"), undef, "valid 10 digits with prefix");
is($object->hash("http://d-nb.info/gnd/1011171872"), undef, "valid 10 digits URI");

is($object->hash("10111718723"), undef, "too long");
is($object->hash("1011171872-3"), undef, "too long with dash");
is($object->hash("PND:10111718723"), undef, "too long with prefix");
is($object->hash("http://d-nb.info/gnd/10111718723"), undef, "too long URI");

is($object->hash("119653826"), "119653826", "store valid checksum 6");
is($object->value(), "119653826", "retrieve valid checksum 6");
is($object->hash("119653820"), "", "store invalid checksum 0");
is($object->value(), "119653820", "retrieve invalid checksum 0");

is($object->hash("119653820"), "", "request invalid checksum 0");
is($object->hash("119653821"), "", "invalid checksum 1");
is($object->hash("119653822"), "", "invalid checksum 2");
is($object->hash("119653823"), "", "invalid checksum 3");
is($object->hash("119653824"), "", "invalid checksum 4");
is($object->hash("119653825"), "", "invalid checksum 5");
ok($object->hash("119653826") && $object->valid(), "valid checksum 6");
is($object->hash("119653827"), "", "invalid checksum 7");
is($object->hash("119653828"), "", "invalid checksum 8");
is($object->hash("119653829"), "", "invalid checksum 9");
is($object->hash("11965382X"), "", "invalid checksum X");

is($object->hash("13201044"), undef, "too short");
is($object->hash("1320104-4"), undef, "too short with dash");
is($object->hash("PND:13201044"), undef, "too short with prefix");
is($object->hash("http://d-nb.info/gnd/13201044"), undef, "too short URI");

is($object->hash("11965382672"), undef, "too long");
is($object->hash("1196538267-2"), undef, "too long, with dash");
is($object->hash("1196 5382672"), undef, "too long, with spaces");
is($object->hash("http://d-nb.info/gnd/11965382672"), undef, "too long URI");

is($object->hash("1948-8352"), undef, "wrong checksum");
is($object->hash("19488352"), undef, "wrong checksum, with dash");
is($object->hash("1948 8352"), undef, "wrong checksum, with spaces");

is($object->hash("0"), undef, "invalid zero");
is($object->hash(""), undef, "empty string");
is($object->hash(undef), "", "undef");
is($object->hash(), "", "emtpy arg");

ok($object->hash("15617913X") && $object->valid(), "valid checksum X");
ok($object->hash("15617913x") && $object->valid(), "valid checksum x");
is($object->hash("15617913Y"), undef, "invalid checksum Y");
is($object->hash("15617913-"), undef, "invalid checksum -");


# conversions
is($object->hash("132010445"), "132010445", "valid 9 digits again");
is($object->value(), "132010445", "valid 9 digits value");
is($object->hash(), "132010445", "valid 9 digits hash");
is($object->indexed(), $object->hash(), "valid 9 digits indexed");
is($object->canonical(), "http://d-nb.info/gnd/132010445", "valid 9 digits canonical");
is($object->normalized(), $object->canonical(), "valid 9 digits normalized");
is("$object", $object->canonical(), "valid 9 digits stringification");
is($object->pretty(), "132010445", "valid 9 digits pretty");

is($object->hash("1011171872"), "1011171872", "valid 10 digits again");
is($object->value(), "1011171872", "valid 10 digits value");
is($object->hash(), "1011171872", "valid 10 digits hash");
is($object->indexed(), $object->hash(), "valid 10 digits indexed");
is($object->canonical(), "http://d-nb.info/gnd/1011171872", "valid 10 digits canonical");
is($object->normalized(), $object->canonical(), "valid 10 digits normalized");
is("$object", $object->canonical(), "valid 10 digits stringification");
is($object->pretty(), "1011171872", "valid 10 digits pretty");

is($object->hash("1100110011"), "1100110011", "valid 10 digits again");
is($object->value(), "1100110011", "valid 10 digits value");
is($object->hash(), "1100110011", "valid 10 digits hash");
is($object->indexed(), $object->hash(), "valid 10 digits indexed");
is($object->canonical(), "http://d-nb.info/gnd/1100110011", "valid 10 digits canonical");
is($object->normalized(), $object->canonical(), "valid 10 digits normalized");
is("$object", $object->canonical(), "valid 10 digits stringification");
is($object->pretty(), "1100110011", "valid 10 digits pretty");

