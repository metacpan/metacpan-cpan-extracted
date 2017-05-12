#!/usr/bin/perl -w

use Test::More tests => 3;
use Compress::Zlib;

BEGIN {
        chdir 't' if -d 't';
        use lib '../blib/lib', 'lib/', '..';
}


my $mod = "Parse::DebControl";

#Object initialization - 1 test

	use_ok($mod);
	ok($pdc = new Parse::DebControl(), "Parser object creation works fine");

#writegzip - 1 test

	$pdc = new Parse::DebControl(1);
	my $hash = {"Key1" => "value1", "Key2" => "value2","Key3" => "value3"};
	my $gzipped = $pdc->write_mem($hash, {gzip => 1});

	ok(
		Compress::Zlib::memGunzip($gzipped) eq 
		$pdc->write_mem($hash), 
		"write_mem with the gzip option is sane");

