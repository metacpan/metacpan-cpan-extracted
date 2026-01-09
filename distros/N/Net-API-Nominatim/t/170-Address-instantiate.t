#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

use utf8; # we have hardcoded unicode strings in here

use lib 'blib/lib';

our $VERSION = '0.03';

use Test::More;
use Test2::Plugin::UTF8; # rids of the Wide Character in TAP message!

use FindBin;
use Data::Roundtrip qw/perl2dump json2perl perl2json no-unicode-escape-permanently/;
use Test::TempDir::Tiny;
use File::Spec;

use Net::API::Nominatim::Model::BoundingBox;
use Net::API::Nominatim::Model::Address;

my $VERBOSITY = 3;

#my $curdir = $FindBin::Bin;
#my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set

my ($bbox, $res);

my @testcases = (
  '[]', # no results
  '[{"place_id":183167426,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"node","osm_id":1921466406,"lat":"55.5533060","lon":"34.9968416","category":"place","type":"town","place_rank":18,"importance":0.5259185792395352,"addresstype":"town","name":"Гагарин","display_name":"Гагарин, Гагаринский муниципальный округ, Смоленская область, Центральный федеральный округ, 215010, Россия","boundingbox":["55.5133060","55.5933060","34.9568416","35.0368416"]},{"place_id":49844566,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"way","osm_id":115811075,"lat":"38.0332384","lon":"23.8743649","category":"highway","type":"residential","place_rank":26,"importance":0.053416607156481236,"addresstype":"road","name":"Γκαγκάριν","display_name":"Γκαγκάριν, Ανθούσα, Κοινότητα Ανθούσας, Δημοτική Ενότητα Ανθούσας, Δήμος Παλλήνης, Περιφερειακή Ενότητα Ανατολικής Αττικής, Περιφέρεια Αττικής, Αποκεντρωμένη Διοίκηση Αττικής, 153 49, Ελλάς","boundingbox":["38.0328941","38.0335827","23.8741711","23.8745587"]}]',
  '[{"place_id":49798380,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"way","osm_id":84012200,"lat":"38.0774000","lon":"23.7129254","category":"highway","type":"residential","place_rank":26,"importance":0.053416607156481236,"addresstype":"road","name":"Μπελογιάννη","display_name":"Μπελογιάννη, Λίμνη, Άνω Λιόσια, Κοινότητα Άνω Λιοσίων, Δημοτική Ενότητα Άνω Λιοσίων, Δήμος Φυλής, Περιφερειακή Ενότητα Δυτικής Αττικής, Περιφέρεια Αττικής, Αποκεντρωμένη Διοίκηση Αττικής, 134 61, Ελλάς","boundingbox":["38.0758125","38.0789852","23.7129226","23.7130358"]},{"place_id":56889451,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"way","osm_id":84012207,"lat":"38.0794219","lon":"23.7131804","category":"highway","type":"residential","place_rank":26,"importance":0.053416607156481236,"addresstype":"road","name":"Μπελογιάννη","display_name":"Μπελογιάννη, Λίμνη, Άνω Λιόσια, Κοινότητα Άνω Λιοσίων, Δημοτική Ενότητα Άνω Λιοσίων, Δήμος Φυλής, Περιφερειακή Ενότητα Δυτικής Αττικής, Περιφέρεια Αττικής, Αποκεντρωμένη Διοίκηση Αττικής, 133 41, Ελλάς","boundingbox":["38.0789680","38.0798759","23.7130941","23.7132668"]},{"place_id":53035574,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"way","osm_id":293188695,"lat":"41.1246213","lon":"25.4029155","category":"highway","type":"residential","place_rank":26,"importance":0.05339399023422595,"addresstype":"road","name":"Μπελογιάννη","display_name":"Μπελογιάννη, Κομοτηνή, Δήμος Κομοτηνής, Περιφερειακή Ενότητα Ροδόπης, Περιφέρεια Ανατολικής Μακεδονίας και Θράκης, Αποκεντρωμένη Διοίκηση Μακεδονίας - Θράκης, 691 32, Ελλάς","boundingbox":["41.1245682","41.1247083","25.4014939","25.4043332"]},{"place_id":48866792,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"way","osm_id":80196749,"lat":"37.9760073","lon":"24.0015987","category":"highway","type":"residential","place_rank":26,"importance":0.05338869993133437,"addresstype":"road","name":"Μπελογιάννη","display_name":"Μπελογιάννη, Κοινότητα Αρτέμιδας, Δημοτική Ενότητα Αρτέμιδος, Δήμος Σπάτων - Αρτέμιδος, Περιφερειακή Ενότητα Ανατολικής Αττικής, Περιφέρεια Αττικής, Αποκεντρωμένη Διοίκηση Αττικής, 190 16, Ελλάς","boundingbox":["37.9759570","37.9760714","24.0004729","24.0027252"]},{"place_id":195040928,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"way","osm_id":89015368,"lat":"34.9911598","lon":"33.7864493","category":"highway","type":"residential","place_rank":26,"importance":0.053370834668497714,"addresstype":"road","name":"Nikou Mpelogianni","display_name":"Nikou Mpelogianni, Ορμήδεια, Σύμπλεγμα Κοινοτήτων Δεκέλειας, Επαρχία Λάρνακας, Κύπρος, 7525, Κύπρος - Kıbrıs","boundingbox":["34.9903544","34.9915339","33.7864478","33.7871788"]},{"place_id":50199373,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"way","osm_id":119762347,"lat":"37.7972089","lon":"21.3518248","category":"leisure","type":"park","place_rank":24,"importance":0.0800556687266346,"addresstype":"park","name":"πλατεία Μπελογιάννη","display_name":"πλατεία Μπελογιάννη, Amaliada, Δημοτική Ενότητα Αμαλιάδας, Δήμος Ήλιδας, Περιφερειακή Ενότητα Ηλείας, Περιφέρεια Δυτικής Ελλάδας, Αποκεντρωμένη Διοίκηση Πελοποννήσου, Δυτικής Ελλάδας και Ιονίου, Ελλάς","boundingbox":["37.7966726","37.7976009","21.3505146","21.3523710"]},{"place_id":195269200,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"way","osm_id":558259823,"lat":"34.8164030","lon":"33.6020362","category":"leisure","type":"park","place_rank":24,"importance":0.08003750133516438,"addresstype":"park","name":"Πάρκο Μπελογιάννη Ουγγαρίας","display_name":"Πάρκο Μπελογιάννη Ουγγαρίας, Περβόλια, Δήμος Δρομολαξιάς - Μενεού, Επαρχία Λάρνακας, Κύπρος, Κύπρος - Kıbrıs","boundingbox":["34.8156539","34.8170525","33.6011989","33.6029499"]}]',
  '[{"place_id":195240130,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"way","osm_id":79725540,"lat":"35.0954627","lon":"33.9578066","category":"highway","type":"residential","place_rank":26,"importance":0.05339408789196609,"addresstype":"road","name":"Beloyianni","display_name":"Beloyianni, Lala Mustafa Paşa, Lala Mustafa Paşa Mahallesi, Gazimağusa, Gazimağusa Belediyesi, Gazimağusa ilçesi, Kuzey Kıbrıs, 99450, Κύπρος - Kıbrıs","boundingbox":["35.0952486","35.0954992","33.9571960","33.9583849"]}]',
  '[{"place_id":51417578,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"way","osm_id":112996799,"lat":"42.6626209","lon":"21.1392662","category":"highway","type":"residential","place_rank":26,"importance":0.05340003585870142,"addresstype":"road","name":"Nazim Hikmet","display_name":"Nazim Hikmet, Zona Ekonomike, Prishtinë, Komuna e Prishtinës / Opština Priština, Rajoni i Prishtinës / Prištinski okrug, 10000, Kosova / Kosovo","boundingbox":["42.6621171","42.6631214","21.1390364","21.1395133"]},{"place_id":194420945,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"node","osm_id":10747242727,"lat":"39.9604947","lon":"32.7773774","category":"highway","type":"bus_stop","place_rank":30,"importance":7.518501564045194e-05,"addresstype":"highway","name":"Nazım Hikmet","display_name":"Nazım Hikmet, Bağdat Caddesi, Urankent, Mehmet Akif Ersoy Mahallesi, Yenimahalle, Ankara, İç Anadolu Bölgesi, 06200, Türkiye","boundingbox":["39.9604447","39.9605447","32.7773274","32.7774274"]},{"place_id":191344217,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"node","osm_id":10747242726,"lat":"39.9601801","lon":"32.7777171","category":"highway","type":"bus_stop","place_rank":30,"importance":7.518501564045194e-05,"addresstype":"highway","name":"Nazım Hikmet","display_name":"Nazım Hikmet, Bağdat Caddesi, Çamlıca Mahallesi, Yenimahalle, Ankara, İç Anadolu Bölgesi, 06200, Türkiye","boundingbox":["39.9601301","39.9602301","32.7776671","32.7777671"]},{"place_id":53684388,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"node","osm_id":10798973297,"lat":"41.0269994","lon":"28.6836679","category":"railway","type":"proposed","place_rank":30,"importance":5.005035477221359e-05,"addresstype":"railway","name":"Nazım Hikmet","display_name":"Nazım Hikmet, Doğan Araslı Bulvarı, Üçevler Mahallesi, Esenyurt, İstanbul, Marmara Bölgesi, 34513, Türkiye","boundingbox":["41.0269494","41.0270494","28.6836179","28.6837179"]},{"place_id":48951110,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"node","osm_id":10242421610,"lat":"37.0346741","lon":"27.4299188","category":"historic","type":"monument","place_rank":30,"importance":3.750133516437045e-05,"addresstype":"historic","name":"Nâzim Hikmet","display_name":"Nâzim Hikmet, Neyzen Tevfik Caddesi, Çarşı, Çarşı Mahallesi, Bodrum, Muğla, Ege Bölgesi, 48400, Türkiye","boundingbox":["37.0346241","37.0347241","27.4298688","27.4299688"]},{"place_id":48952593,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"node","osm_id":1710777037,"lat":"36.8806521","lon":"30.7038963","category":"historic","type":"memorial","place_rank":30,"importance":6.98336766612805e-05,"addresstype":"historic","name":"Nâzım Hikmet","display_name":"Nâzım Hikmet, Park Sokak, Kılınçarslan Mahallesi, Antalya, Muratpaşa, Antalya, Akdeniz Bölgesi, 07100, Türkiye","boundingbox":["36.8806021","36.8807021","30.7038463","30.7039463"]},{"place_id":53817323,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"way","osm_id":459825900,"lat":"43.3742376","lon":"24.3504550","category":"highway","type":"residential","place_rank":26,"importance":0.053374174868390904,"addresstype":"road","name":"Назим Хикмет","display_name":"Назим Хикмет, Горни Дъбник, Долни Дъбник, Плевен, България","boundingbox":["43.3739039","43.3742425","24.3490376","24.3517934"]},{"place_id":53057449,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"way","osm_id":146961697,"lat":"41.6474110","lon":"25.3626261","category":"highway","type":"residential","place_rank":26,"importance":0.05339322575722893,"addresstype":"road","name":"Назъм Хикмет","display_name":"Назъм Хикмет, Боровец, Кърджали, 6609, България","boundingbox":["41.6471579","41.6476161","25.3622933","25.3629238"]},{"place_id":54099072,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"way","osm_id":414697863,"lat":"43.4892420","lon":"24.0939598","category":"highway","type":"residential","place_rank":26,"importance":0.0533880300602731,"addresstype":"road","name":"Назъм Хикмет","display_name":"Назъм Хикмет, Кнежа, Плевен, 5835, България","boundingbox":["43.4877189","43.4910548","24.0902911","24.0977492"]},{"place_id":53806838,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"way","osm_id":195204034,"lat":"43.8083532","lon":"26.4854604","category":"highway","type":"residential","place_rank":26,"importance":0.05338799496452274,"addresstype":"road","name":"Назъм Хикмет","display_name":"Назъм Хикмет, кв. Дряново, Кубрат, Разград, 7300, България","boundingbox":["43.8031173","43.8120257","26.4806824","26.4886127"]}]',
);

my $dummy = Net::API::Nominatim::Model::Address->new();
ok(defined $dummy, "constructed empty object") or BAIL_OUT;
my $F = $dummy->fields;

my $tidx = 0;
for my $TC (@testcases){
  $tidx++;
  # each testcase comprises of an array of returned Addresses, each address is a Hash,
  # an address accepts a hash, not an array of Address, so check the input if array and break it
  my $p = json2perl($TC);
  ok(defined $p, "JSON input has been decoded to perl.") or BAIL_OUT("${TC}\n\nno, it failed for above JSON string.");
  my $tidx2 = 0;
  for my $I (@$p){
	$tidx2++;
	# constructor from HASH
	my $address = Net::API::Nominatim::Model::Address->new($I);
	ok(defined $address, "constructor called with HASH parameter and got good results.") or BAIL_OUT;
	for(@$F){
		my $v = $address->$_();
		is($v, $I->{$_}, "field '$_' has the same value in address ($v) as in the input (".$I->{$_}.").") or BAIL_OUT;
	}

	# constructor from another object of same class
	my $address2 = Net::API::Nominatim::Model::Address->new($address);
	ok(defined $address2, "contructor called and returned good result.") or BAIL_OUT;
	for(@$F){
		my $v = $address2->$_();
		is($v, $I->{$_}, "field '$_' has the same value in address ($v) as in the input (".$I->{$_}.").") or BAIL_OUT;
	}

	# constructor from JSON String
	my $js = perl2json($I);
	ok(defined $js, "converted input hash to JSON") or BAIL_OUT(perl2dump($I)."no, it failed for above data.");
	$address = Net::API::Nominatim::Model::Address->new($js);
	ok(defined $address, "contructor called and returned good result.") or BAIL_OUT;
	for(@$F){
		my $v = $address->$_();
		is($v, $I->{$_}, "field '$_' has the same value in address ($v) as in the input (".$I->{$_}.").") or BAIL_OUT;
	}

	# stringifiers: toString()
	# we can not compare the string because we toString() sorted but above testcases are not sorted.
	my $str = $address->toString();
	ok(defined $str, "toString(): called and got good result.") or BAIL_OUT;
	# parse it as JSON
	my $p = json2perl($str);
	ok(defined $p, "toString() : result validates as JSON.") or BAIL_OUT("${str}\nno, see above");
	for(@$F){
		my $ev = $address->$_();
		my $gv = $p->{$_};
		if( $_ eq 'boundingbox' ){
			# a problem: toString() makes the bounding box as [lat1,lat2,...] and not
			# as a 2D array like bboxs' toString(), no big deal, we just compare it like this:
			$ev = perl2json($ev->toArray());
		}
		is_deeply($gv, $ev, "toString() : parsed result as JSON and '$_' is what expected ($gv).") or BAIL_OUT(perl2dump($p)."no, it is ($gv) but expected ($ev), see above for all the JSON data returned from toString().");
	}

	# stringifiers: toJSON()
	# we can not compare the string because we toString() sorted but above testcases are not sorted.
	$str = $address->toJSON();
	ok(defined $str, "toJSON(): called and got good result.") or BAIL_OUT;
	# parse it as JSON
	$p = json2perl($str);
	ok(defined $p, "toJSON() : result validates as JSON.") or BAIL_OUT("${str}\nno, see above");
	for(@$F){
		my $ev = $address->$_();
		my $gv = $p->{$_};
		if( $_ eq 'boundingbox' ){
			# a problem: toJSON() makes the bounding box as [lat1,lat2,...] and not
			# as a 2D array like bboxs' toJSON(), no big deal, we just compare it like this:
			$ev = perl2json($ev->toArray());
		}
		is_deeply($gv, $ev, "toJSON() : parsed result as JSON and '$_' is what expected ($gv).") or BAIL_OUT(perl2dump($p)."no, it is ($gv) but expected ($ev), see above for all the JSON data returned from toJSON().");
	}

	# equals
	$address2 = Net::API::Nominatim::Model::Address->new($I);
	ok(defined $address2, "contructor called and returned good result.") or BAIL_OUT;
	is($address->equals($address2), 1, "equals() : new object is 'equal' to the source object.") or BAIL_OUT($address->toJSON()."\n".$address2->toJSON()."\nno, see above for the 1. source, 2. cloned.");
	is($address2->equals($address), 1, "equals() : source object is 'equal' to the new object.") or BAIL_OUT($address->toJSON()."\n".$address2->toJSON()."\nno, see above for the 1. source, 2. cloned.");

	# clone
	$address2 = $address->clone;
	ok(defined $address2, "clone() : called and got good result.") or BAIL_OUT;
	is($address->equals($address2), 1, "clone() : cloned object is exactly the same as the source.") or BAIL_OUT($address->toJSON()."\n".$address2->toJSON()."\nno, see above for the 1. source, 2. cloned.");

	# setters/getters
	my $tv = 123.123;
	for(@$F){
		my $v = $address->$_($tv);
		is($v, $tv, "testing setter $_".'()'." got value ($v) as expected.") or BAIL_OUT("no, got '$v' but expected '$tv'");
		$v = $address->$_();
		is($v, $tv, "testing getter $_".'()'." got value ($v) as expected.") or BAIL_OUT("no, got '$v' but expected '$tv'");
	}

	# factory method fromHash()
	my $ah = $address->toHash();
	my $address3 = Net::API::Nominatim::Model::Address::fromHash($ah);
	ok(defined($address3), 'Net::API::Nominatim::Model::Address::fromHash()'." : called and got good result.") or BAIL_OUT;
	is_deeply($ah, $address3->toHash(), 'Net::API::Nominatim::Model::Address::fromHash()'." : returned result is exactly the same as the source when comparing toHash().") or BAIL_OUT(perl2dump($ah)."No, above is the src and below is the destination/result:".perl2dump($address3->toHash()));
	is($address->equals($address3), 1, 'Net::API::Nominatim::Model::Address::fromHash()'." : returned result is exactly the same as the source using equals().") or BAIL_OUT($address->toString()."\nNo, above is the src and below is the destination/result:\n".$address3->toString());

	# factory method fromArray()
	my $objs = [$address, $address2, $address, $address2];
	my $arr = [ map { $_->toHash() } @$objs ];
	my $newarr = Net::API::Nominatim::Model::Address::fromArray($arr);
	ok(defined($newarr), 'Net::API::Nominatim::Model::Address::fromArray()'." : called and got good result.") or BAIL_OUT;
	for(my $i=scalar(@$arr);$i-->0;){
		my $obj1 = $objs->[$i];
		my $obj2 = $newarr->[$i];
		ok(defined($obj2), 'Net::API::Nominatim::Model::Address::fromArray()'." : array of address, item #${i} is defined.") or BAIL_OUT;
		is_deeply($obj1->toHash(), $obj2->toHash(), 'Net::API::Nominatim::Model::Address::fromArray()'." : array of address, items #${i} are equal compared using toHash().") or BAIL_OUT($obj1->toString()."\nNo, above is the src and below is the destination/result:\n".$obj2->toString());
		is($obj1->equals($obj2), 1, 'Net::API::Nominatim::Model::Address::fromArray()'." : returned result is exactly the same as the source using equals().") or BAIL_OUT($obj1->toString()."\nNo, above is the src and below is the destination/result:\n".$obj2->toString());
	}

  } # for each sub-testcase $I
} # for each testcase $TC

# now we will test reading the whole array of addresses as returned
# by nominatim, not just each hash item of the array as above.
# 
$tidx = 0;
for my $TC (@testcases){
  $tidx++;
  # each testcase comprises of an array of returned Addresses, each address is a Hash,
  # an address accepts a hash, not an array of Address, so check the input if array and break it
  my $addresses = Net::API::Nominatim::Model::Address::fromJSONArray($TC);
  ok(defined $addresses, 'Net::API::Nominatim::Model::Address::fromJSONArray()'." : called and got good result.") or BAIL_OUT;
  is(ref($addresses), 'ARRAY', 'Net::API::Nominatim::Model::Address::fromJSONArray()'." : result is an array.") or BAIL_OUT;
  for my $add (@$addresses){
	ok(defined($add), 'Net::API::Nominatim::Model::Address::fromJSONArray()'." : result contains an item which is defined.") or BAIL_OUT("no it is of type '".ref($add)."'.");
	is(ref($add), 'Net::API::Nominatim::Model::Address', 'Net::API::Nominatim::Model::Address::fromJSONArray()'." : result contains an address object of type 'Net::API::Nominatim::Model::Address'.") or BAIL_OUT("no it is of type '".ref($add)."'.");
	# TODO: add some more tests like above?
	# check they are NOT equal (but they may be, ok)
  }
  # check they are NOT equal (but they may be, ok)
  for(my $i=scalar(@$addresses);$i-->0;){
    for(my $j=scalar(@$addresses);$j-->0;){
	if( $i == $j ){
		is($addresses->[$i]->equals($addresses->[$j]), 1, "comparing same Address object expecting to be equal.") or BAIL_OUT($addresses->[$i]->toString()."\nno! but they are the exact same object, anyway i=$i, see above.");
	} else {
		is($addresses->[$i]->equals($addresses->[$j]), 0, "comparing different Address objects expecting to be different.") or BAIL_OUT($addresses->[$i]->toString()."\n".$addresses->[$j]->toString()."\nno! but they are part of all the addresses returned for just one nominatim search, unlikely to be the same, anyway i=$i, j=$j, see above.");
		is($addresses->[$j]->equals($addresses->[$i]), 0, "comparing different Address objects expecting to be different.") or BAIL_OUT($addresses->[$i]->toString()."\n".$addresses->[$j]->toString()."\nno! but they are part of all the addresses returned for just one nominatim search, unlikely to be the same, anyway i=$i, j=$j, see above.");
	}
    }
  }
}	

###################### rand test

for my $ran (1234, 5433, 1233){
	# test constructor from Random
	srand $ran;
	my $address = Net::API::Nominatim::Model::Address::fromRandom();
	ok(defined $address, "contructor called and returned good result.") or BAIL_OUT;
	for(@$F){
		ok(defined($bbox->$_()), "field '$_' has defined value") or BAIL_OUT(perl2dump($bbox)."\nno see above bounding box with random coordinates.");
		ok(abs($bbox->$_()) > 1E-12, "field '$_' has non-zero value") or BAIL_OUT(perl2dump($bbox)."\nno see above bounding box with random coordinates.");
	}
}

####### done ouph!

#diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
