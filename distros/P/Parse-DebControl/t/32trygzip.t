#!/usr/bin/perl -w

use Test::More tests => 13;
use Compress::Zlib;

BEGIN {
        chdir 't' if -d 't';
        use lib '../blib/lib', 'lib/', '..';
}


my $mod = "Parse::DebControl";

#Object initialization - 1 test

	use_ok($mod);
	ok($pdc = new Parse::DebControl(), "Parser object creation works fine");

#tryGzip - 6 tests

	$pdc = new Parse::DebControl(1);
	my $string = "Key1: value1\nKey2: value2\nKey3: value3";
	my $gzdata = Compress::Zlib::memGzip($string);
	my $gzcopy = $gzdata;
	
	ok(Compress::Zlib::memGunzip($gzcopy) eq $string, "memGunzip is sane");
	ok($data = $pdc->parse_mem($gzdata, {"tryGzip" => 1}), "Parse with gzip works on a gzipped stanza");

	ok(@$data == 1, "...and there is one stanzaa");

	ok($data->[0]->{Key1} eq "value1", "...and the first value is correct");
	ok($data->[0]->{Key2} eq "value2", "...and the second value is correct");
	ok($data->[0]->{Key3} eq "value3", "...and the third value is correct");

	#Without gzipped data, emphasis on "try"
	ok($data = $pdc->parse_mem($string,), "Parsing the string is sane");
	ok($data = $pdc->parse_mem($string, {"tryGzip" => 1}), "Parse with gzip works on a ungzipped stanza");

	ok($data->[0]->{Key1} eq "value1", "...and the first value is correct");
	ok($data->[0]->{Key2} eq "value2", "...and the second value is correct");
	ok($data->[0]->{Key3} eq "value3", "...and the third value is correct");

