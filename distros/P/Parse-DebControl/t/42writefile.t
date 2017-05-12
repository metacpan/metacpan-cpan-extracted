#!/usr/bin/perl -w

use Test::More tests => 20;
use Compress::Zlib;

BEGIN {
        chdir 't' if -d 't';
        use lib '../blib/lib', 'lib/', '..';
}


my $mod = "Parse::DebControl";

#Object initialization - 2 tests

	use_ok($mod);
	ok($pdc = new Parse::DebControl(), "Parser object creation works fine");

SKIP: {
	skip "/tmp not available. Either not-unix or not standard unix", 18 unless(-d "/tmp");
	skip "/tmp not writable. Skipping write tests", 18 unless(-d "/tmp" and -w "/tmp");
	skip "Windows /tmp wierdness. No thanks", 18 if($^O =~ /Win32/);

	my $fh;
	my $file = "/tmp/pdc_testfile".int(rand(10000));

	ok($pdc->write_file($file, {"key1" => "value1", "key2" => "value2"}, {"clobberFile" => 1}), "File write is okay");
	ok(my $data = $pdc->parse_file($file), "...and re-parsing is correct");
	ok($data->[0]->{key1} eq "value1", "...and the first key is correct");
	ok($data->[0]->{key2} eq "value2", "...and the second key is correct");
	unlink $file;

	ok($pdc->write_file($file, {"key1" => "value3", "key2" => "value4"}, {"gzip" => 1, "clobberFile" => 1}), "Writing file with gzip is okay");
	ok($data = $pdc->parse_file($file, {tryGzip => 1}), "...and parsing the zipped file is correct");
	ok($data->[0]->{key1} eq "value3", "...and the first key is correct");
	ok($data->[0]->{key2} eq "value4", "...and the second key is correct");


	#Expected behaviour tests
	ok($pdc->write_file($file, {"key1" => "value4"}, {"clobberFile" => 1}), "File write with single stanza is okay");
	ok($pdc->write_file($file, {"key2" => "value5"}), "...appending to that file should produce consistant results");
	ok($data = $pdc->parse_file($file), "...and re-parsing succeeded");
	ok($data->[0]->{key1} eq "value4", "...and the first key is correct");
	ok($data->[0]->{key2} eq "value5", "...and the second key is correct");
	
	ok($pdc->write_file($file, {"key1" => "value6"}, {"clobberFile" => 1, "addNewline" => 1}), "File rewrite with addNewline");
	ok($pdc->write_file($file, {"key2" => "value7"}), "...and append to that file");
	ok($data = $pdc->parse_file($file), "...and parsing of the newlined file works");
	ok($data->[0]->{key1} eq "value6", "...and the first value is correct");
	ok($data->[1]->{key2} eq "value7", "...and the second value is correct");

	unlink $file;

};
