#!/usr/bin/perl -w

use Test::More tests => 24;

BEGIN {
        chdir 't' if -d 't';
        use lib '../blib/lib', 'lib/', '..';
}


my $mod = "Parse::DebControl";

#Object initialization - 2 tests

	use_ok($mod);
	ok($pdc = new Parse::DebControl(), "Parser object creation works fine");

#stripComments - 6 tests

	$pdc = new Parse::DebControl(1);
	ok($data = $pdc->parse_mem("Key1: value1\n\#This is a comment\nKey2: value2#another comment\nKey3: value3", {stripComments => 1}), "Comments parse out correctly");
	ok(@$data == 1, "...and there are two stanzas");
	ok(keys %{$data->[0]} == 3, "...and the first stanza is the right size");
	ok($data->[0]->{Key1} eq "value1", "...and the first value is correct");

	ok($data->[0]->{Key2} eq "value2", "...and the second value is correct");
	ok($data->[0]->{Key3} eq "value3", "...and the third value is correct");

	#Comment char as last character - 2 tests
	ok($data = $pdc->parse_mem("Key1: value\#", {stripComments => 1}), "Parse with pound as last character");
	ok($data->[0]->{Key1} eq "value", "...data is correct");

	#Literal pound as last character - 2 tests
	ok($data = $pdc->parse_mem("Key1: value\#\#", {stripComments => 1}), "Parse with literal pound as last character");
	ok($data->[0]->{Key1} eq "value\#", "...data is correct");

	#Comment char as first character - 3 tests
	ok($data = $pdc->parse_mem("Key1: value\n\#oo: bar", {stripComments => 1}), "Parse with comment as first character");
	ok($data->[0]->{Key1} eq "value", "...data is correct");
	ok(keys %{$data->[0]} == 1, "...data is right size");

	#Literal pound as first character - 3 tests
	ok($data = $pdc->parse_mem("Key1: value\n\#\#oo: bar", {stripComments => 1}), "Parse with literal pound  as first character");
	ok($data->[0]->{Key1} eq "value", "...data is correct");
	ok($data->[0]->{"\#oo"} eq "bar", "...pound-key character is correct");

	#Line skip - 3 tests
	ok($data = $pdc->parse_mem("Key1: value\n#hello there#\nKey2: value2", {stripComments => 1}), "Parse with line skip");
	ok($data->[0]->{Key1} eq "value", "...first value is correct");
	ok($data->[0]->{Key2} eq "value2", "...second value is correct");

	#Line skip; leading whitespace - 3 tests
	ok($data = $pdc->parse_mem("Key1: value\n         #hello there#\nKey2: value2", {stripComments => 1}), "Parse with line skip and leading space");
	ok($data->[0]->{Key1} eq "value", "...first value is correct");
	ok($data->[0]->{Key2} eq "value2", "...second value is correct");

