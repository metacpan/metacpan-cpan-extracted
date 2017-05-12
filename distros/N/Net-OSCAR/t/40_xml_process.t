#!/usr/bin/perl

eval {
	require Test::More;
	require XML::Parser;
};
if($@) {
	print "1..0 # Skipped: Couldn't load Test::More or XML::Parser\n";
	exit 0;
}

use File::Basename;
use strict;
use lib "./blib/lib";
no warnings;

Test::More->import();

my %do_tests = map {$_ => 1} @ARGV;

my @tests = grep {%do_tests ? exists($do_tests{$_->{template}}) : 1} (
	{
		binary => pack("C", 42),
		data => {x => 42},
		template => "just_byte",
	},{
		binary => "0",
		data => {x => ord("0")},
		template => "just_byte",
		name => "zero string byte"
	},{
		binary => pack("n", 1984),
		data => {x => 1984},
		template => "just_word"
	},{
		binary => pack("N", 0xDEADBEEF),
		data => {x => 0xDEADBEEF},
		template => "just_dword"
	},{
		binary => "UML model of a modern major general",
		data => {x => "UML model of a modern major general"},
		template => "just_data"
	},{
		binary => pack("n", 0),
		data => {x => 0},
		template => "just_word",
		name => "zero word"
	},{
		binary => pack("n", 123),
		data => {},
		template => "fixed_value"
	},{
		binary => "foo",
		data => {},
		template => "fixed_value_data"
	},{
		binary => pack("na*", length("Cthulhu"), "Cthulhu"),
		data => {x => "Cthulhu"},
		template => "length_prefix"
	},{
		binary => pack("n", 0),
		data => {x => ""},
		template => "length_prefix",
		name => "empty prefix data"
	},{
		binary => pack("va*", length("Kessel run"), "Kessel run"),
		data => {x => "Kessel run"},
		template => "vax_prefix"
	},{
		binary => pack("n*", 1, 1, 2, 3, 5, 8, 13),
		data => {x => [1, 1, 2, 3, 5, 8, 13]},
		template => "repeated_data"
	},{
		binary => "1234567890XXX",
		data => {x => "1234567890", y => "XXX"},
		template => "fixed_width_data"
	},{
		binary => pack("n", 0),
		data => {},
		template => "default_generate_data"
	},{
		binary => "foo" . chr(0) . "bar",
		data => {foo => "foo", bar => "bar"},
		template => "null_terminated_data"
	},{
		binary => "foo" . (chr(0) x 7),
		data => {foo => "foo"},
		template => "null_pad_data"
	},{
		binary => pack("Cnnn n", 3, 1, 2, 3, 4),
		data => {foo => [1, 2, 3], bar => 4},
		template => "count_prefix_data"
	},{
		binary => pack("na*n na* na* na*  na*n na* na*",
			length("FRUITS"), "FRUITS", 3,
				length("apple"), "apple",
				length("orange"), "orange",
				length("pear"), "pear",
			length("VEGGIES"), "VEGGIES", 2,
				length("lettuce"), "lettuce",
				length("broccoli"), "broccoli",
		),
		data => {foo => [
			{bar => "FRUITS", baz => [{buzz => "apple"}, {buzz => "orange"}, {buzz => "pear"}]},
			{bar => "VEGGIES", baz => [{buzz => "lettuce"}, {buzz => "broccoli"}]}
		]},
		template => "complex_count_prefix"
	},{
		binary => "foo" . chr(0) . "bar" . chr(0),
		data => {foo => ["foo", "bar"]},
		template => "null_separated_array"
	},{
		binary => "abc",
		data => {foo => [qw(a b c)]},
		template => "count_len"
	},{
		binary => pack("nnn nnn", 1, 2, 3, 2, 2, 20),
		data => {x => 3, y => 20},
		template => "basic_tlv"
	},{
		binary => pack("nn", 1, 0),
		data => {x => ""},
		template => "data_tlv"
	#},{
	#	binary => pack("nnC", 1, 1, "0"),
	#	data => {x => "0"},
	#	template => "data_tlv",
	#	name => "zero string data tlv"
	},{
		binary => pack("nnn", 1, 2, 0),
		data => {x => ""},
		template => "data_prefix_tlv"
	},{
		binary => "",
		data => {},
		template => "data_prefix_tlv",
		name => "empty data_prefix_tlv"
	},{
		binary => pack("nCC", 1, 1, 0),
		data => {x => ""},
		template => "subdata_tlv",
	},{
		binary => pack("nCCn", 1, 1, 2, 0),
		data => {x => ""},
		template => "subdata_prefix_tlv",
	},{
		binary => pack("nna*a*", 1, 3, "foo", "bar"),
		data => {x => "foo", y => "bar"},
		template => "length_tlv"
	},{
		binary => pack("nna* nna*", 1, length("Baby"), "Baby", 2, length("Surge"), "Surge"),
		data => {foo => {x => "Baby"}, bar => {y => "Surge"}},
		template => "named_tlv"
	},{
		binary => pack("nn", 1, 0),
		data => {foo => ""},
		template => "named_only_tlv"
	},{
		binary => "",
		data => {},
		template => "named_only_tlv",
		name => "empty named_only_tlv"
	},{
		binary => pack("nna*nNC", 1, 10, "foo", 3142, 1793, 27),
		data => {foo => "foo", bar => 3142, baz => 27},
		template => "complex_data_tlv"
	},{
		binary => pack("nCCn nCCn", 1, 1, 2, 3, 1, 2, 2, 20),
		data => {foo => {x => 3}, bar => {y => 20}},
		template => "subtyped_tlv"
	},{
		binary => pack("nCCn nCCn", 1, 1, 2, 0, 1, 2, 2, 0),
		data => {foo => {x => 0}, bar => {y => 0}},
		template => "subtyped_tlv",
		name => "zero subtyped TLV"
	},{
		binary => pack("n nna*", 1, 1, length("foo"), "foo"),
		data => {x => "foo"},
		template => "count_prefix_tlv"
	},{
		binary => pack("nna* nna*", 1, length("foo"), "foo", 1, length("foo"), "foo"),
		data => {x => [{y => "foo"}, {y => "foo"}]},
		template => "count_type_tlv"
	},{
		binary => pack("nCCa* nCCa*", 1, 1, length("foo"), "foo", 1, 1, length("foo"), "foo"),
		data => {x => [{y => "foo"}, {y => "foo"}]},
		template => "count_subtype_tlv"
	},{
		binary => pack("nn", 1, 0),
		data => {},
		template => "default_generate_tlv"
	},{
		binary => pack("nn", 3, 20),
		data => {foo => 3, bar => 20},
		template => "ref"
	},{
		binary => pack("n", 2),
		data => {metasyntax => "bar"},
		template => "enum"
	},{
		binary => pack("C", 1),
		data => {icecream => "chocolate"},
		template => "enum_default"
	}
);


plan(tests => 3+2*@tests);

require_ok("Net::OSCAR");
require_ok("Net::OSCAR::XML");
Net::OSCAR::XML->import('protoparse');

my $oscar = Net::OSCAR->new();
$Net::OSCAR::XML::NO_XML_CACHE = 1;
is(Net::OSCAR::XML::load_xml(dirname($0)."/test.xml"), 1, "loading XML test file");

$oscar->loglevel(99) if %do_tests;
foreach (@tests) {
	is(
		protoparse($oscar, $_->{template})->pack(%{$_->{data}}),
		$_->{binary},
		"Encode: " . (exists($_->{name}) ? $_->{name} : $_->{template})
	);

	is_deeply(
		{protoparse($oscar, $_->{template})->unpack($_->{binary})},
		$_->{data},
		"Decode: " . (exists($_->{name}) ? $_->{name} : $_->{template})
	);
}

