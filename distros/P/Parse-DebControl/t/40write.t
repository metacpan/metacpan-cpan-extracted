#!/usr/bin/perl -w

use strict;
use Test::More tests => 14;

my $warning ="";

BEGIN {
        chdir 't' if -d 't';
        use lib '../blib/lib', 'lib/', '..';

}


my $mod = "Parse::DebControl";

use_ok($mod);
my $writer;

ok($writer = new Parse::DebControl);
ok(!$writer->write_mem(), "write_mem should fail without data");
ok(!$writer->write_file(), "write_file should fail without a filename or handle");
ok(!$writer->write_file('/fake/file'), "write_file should fail without data");

ok($writer->write_mem({'foo' => 'bar'}) eq "foo: bar\n", "write_* should translate simple items correctly");

ok($writer->write_mem({'foo' => ''}) eq "foo:\n", "write_* should accept (begrudgingly) blank hashkeys");

ok($writer->write_mem({'foo' => undef}) eq "foo:\n", "write_* should correctly handle undef items");




SKIP: 	{
		eval { require Tie::IxHash };
		skip "Tie::IxHash is not installed", 3 if($@);

		my $test1 = "Test: Item1\nTest2: Item2\nTest3: Item3\n";
		my $test2 = "Test: Items\n Hello\n There\n .\n World\nAnother-item: world\n";
		my $i = 1;

		foreach($test1, $test2, "$test1\n$test2"){
			ok($writer->write_mem($writer->parse_mem($_, {'useTieIxHash' => 1})) eq $_, "...Fidelity test $i");
			$i++;
		}
	}

my $warnings = "";

local $SIG{__WARN__} = sub { $warnings = $_};

my $mem = $writer->write_mem([{}]);
ok($warnings eq "", "Writing blank hashrefs doesn't throw warnings"); #Version 1.6 fix

$mem = $writer->write_mem([]);
ok($warnings eq "", "Writing blank arrayrefs doesn't throw warnings"); #Version 1.9 fix

$mem = $writer->write_mem();
ok($warnings eq "", "Writing blank arrayrefs doesn't throw warnings"); #Version 1.9 fix

