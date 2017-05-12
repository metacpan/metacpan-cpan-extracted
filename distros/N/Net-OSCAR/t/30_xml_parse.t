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

Test::More->import(tests => 31);

require_ok("Net::OSCAR");
require_ok("Net::OSCAR::XML");
Net::OSCAR::XML->import('protoparse');

my $oscar = Net::OSCAR->new();
$Net::OSCAR::XML::NO_XML_CACHE = 1;
is(Net::OSCAR::XML::load_xml(dirname($0)."/test.xml"), 1, "loading XML test file");

is_deeply([sort keys(%Net::OSCAR::XML::xmlmap)], [sort qw(
		just_byte
		just_word
		just_dword
		just_data
		fixed_value
		fixed_value_data
		null_terminated_data
		null_separated_array
		null_pad_data
		count_prefix_data
		complex_count_prefix
		length_prefix
		vax_prefix
		repeated_data
		fixed_width_data
		default_generate_data
		count_len
		basic_tlv
		data_tlv
		data_prefix_tlv
		subdata_tlv
		subdata_prefix_tlv
		length_tlv
		named_tlv
		named_only_tlv
		complex_data_tlv
		subtyped_tlv
		count_prefix_tlv
		count_type_tlv
		count_subtype_tlv
		default_generate_tlv
		im_footer_test
		ref_foo
		ref_bar
		ref
		snac
		enum
		enum_default
	), "TLV", "subtyped_TLV"], "forward name mapping");

is_deeply({%Net::OSCAR::XML::xml_revmap}, {1 => { 2 => "snac" }}, "reverse name mapping");

$Net::OSCAR::XML::PROTOPARSE_DEBUG = 1;

is_deeply(
	[protoparse($oscar, "just_byte")],
	[{len => 1, type => 'num', packlet => 'C', name => 'x'}],
	"byte"
);
is_deeply(
	[protoparse($oscar, "just_word")],
	[{len => 2, type => 'num', packlet => 'n', name => 'x'}],
	"word"
);
is_deeply(
	[protoparse($oscar, "just_dword")],
	[{len => 4, type => 'num', packlet => 'N', name => 'x'}],
	"dword"
);
is_deeply(
	[protoparse($oscar, "just_data")],
	[{type => 'data', name => 'x'}],
	"data"
);

is_deeply(
	[protoparse($oscar, "fixed_value")],
	[{len => 2, type => 'num', packlet => 'n', value => 123}],
	"fixed-value word"
);
is_deeply(
	[protoparse($oscar, "fixed_value_data")],
	[{type => 'data', value => 'foo'}],
	"fixed-value data"
);
is_deeply(
	[protoparse($oscar, "null_terminated_data")],
	[
		{type => 'data', name => "foo", null_terminated => 1},
		{type => 'data', name => "bar"}
	],
	"null-terminated data"
);
is_deeply(
	[protoparse($oscar, "null_pad_data")],
	[
		{type => 'data', name => "foo", pad => 0, len => 10}
	],
	"null-padded data"
);
is_deeply(
	[protoparse($oscar, "count_prefix_data")],
	[
		{type => 'num', name => "foo", prefix => "count", prefix_packlet => "C", prefix_len => 1, packlet => 'n', len => 2},
		{type => 'num', name => "bar", packlet => "n", len => 2}
	],
	"count prefix data"
);
is_deeply(
	[protoparse($oscar, "complex_count_prefix")],
	[
		{type => 'data', count => -1, name => "foo", items => [
			{type => 'data', name => "bar", prefix => "length", prefix_packlet => "n", prefix_len => 2},
			{type => 'data', name => "baz", prefix => "count", prefix_packlet => "n", prefix_len => 2, items => [
				{type => 'data', name => "buzz", prefix => "length", prefix_packlet => "n", prefix_len => 2},
			]}
		]}
	],
	"complex count prefix data"
);

is_deeply(
	[protoparse($oscar, "length_prefix")],
	[{prefix_len => 2, type => 'data', prefix_packlet => 'n', prefix => 'length', name => 'x'}],
	"length prefix"
);
is_deeply(
	[protoparse($oscar, "vax_prefix")],
	[{prefix_len => 2, type => 'data', prefix_packlet => 'v', prefix => 'length', name => 'x'}],
	"vax-order length prefix"
);
is_deeply(
	[protoparse($oscar, "repeated_data")],
	[{type => 'num', len => 2, packlet => "n", count => -1, name => 'x'}],
	"repeated data"
);
is_deeply(
	[protoparse($oscar, "fixed_width_data")],
	[{type => 'data', len => 10, name => 'x'}, {type => 'data', name => 'y'}],
	"fixed-width data"
);
is_deeply(
	[protoparse($oscar, "default_generate_data")],
	[{type => 'data', prefix => "length", prefix_len => 2, prefix_packlet => "n", value => ""}],
	"default-generate data"
);

is_deeply(
	[protoparse($oscar, "count_len")],
	[{type => 'data', count => -1, len => 1, name => 'foo'}],
	"count length data"
);

is_deeply(
	[protoparse($oscar, "basic_tlv")],
	[{type => 'tlvchain', items => [
		{
			type => 'data',
			num => 1,
			items => [{type => 'num', packlet => 'n', len => 2, name => 'x'}],
		},{
			type => 'data',
			num => 2,
			items => [{type => 'num', packlet => 'n', len => 2, name => 'y'}],
		}
	]}],
	"TLV chain"
);
is_deeply(
	[protoparse($oscar, "named_tlv")],
	[{type => 'tlvchain', items => [
		{
			type => 'data',
			name => 'foo',
			num => 1,
			items => [{type => 'data', name => 'x'}]
		},{
			type => 'data',
			name => 'bar',
			num => 2,
			items => [{type => 'data', name => 'y'}]
		}
	]}],
	"TLV chain, named TLVs"
);
is_deeply(
	[protoparse($oscar, "complex_data_tlv")],
	[{type => 'tlvchain', items => [
		{
			type => 'data',
			num => 1,
			items => [
				{type => 'data', name => 'foo', len => 3},
				{type => 'num', name => 'bar', len => 2, packlet => 'n'},
				{type => 'num', len => 4, packlet => 'N', value => 1793},
				{type => 'num', name => 'baz', len => 1, packlet => 'C'}
			]
		},{
			type => 'data',
			num => 2,
			items => [{type => 'data', name => 'buzz'}]
		}
	]}],
	"TLV chain, complex data"
);
is_deeply(
	[protoparse($oscar, "subtyped_tlv")],
	[{type => 'tlvchain', subtyped => 1, items => [
		{
			type => 'data',
			name => 'foo',
			num => 1, subtype => 1,
			items => [{type => 'num', packlet => 'n', len => 2, name => 'x'}]
		},{
			type => 'data',
			name => 'bar',
			num => 1, subtype => 2,
			items => [{type => 'num', packlet => 'n', len => 2, name => 'y'}]
		}
	]}],
	"TLV chain, subtyped TLVs"
);
is_deeply(
	[protoparse($oscar, "count_prefix_tlv")],
	[{type => 'tlvchain', prefix => 'count', prefix_packlet => 'n', prefix_len => 2, items => [
		{type => 'data', num => 1, items => [{type => 'data', name => 'x'}]},
		{type => 'data', num => 2, items => [{type => 'data', name => 'y'}]},
	]}],
	"TLV chain, count prefixed"
);
is_deeply(
	[protoparse($oscar, "count_type_tlv")],
	[{type => 'tlvchain', items => [
		{type => 'data', num => 1, count => -1, name => 'x', items => [
			{type => 'data', name => 'y'}
		]}
	]}],
	"TLV chain, counted TLV"
);
is_deeply(
	[protoparse($oscar, "count_subtype_tlv")],
	[{type => 'tlvchain', subtyped => 1, items => [
		{type => 'data', num => 1, subtype => 1, count => -1, name => 'x', items => [
			{type => 'data', name => 'y'}
		]}
	]}],
	"TLV chain, counted TLV"
);


is_deeply(
	[protoparse($oscar, "ref")],
	[
		{type => 'ref', name => "ref_foo"},
		{type => 'ref', name => "ref_bar"}
	],
	"references"
);

is_deeply(
	[protoparse($oscar, "enum")],
	[
		{len => 2, type => "num", packlet => "n", name => "metasyntax",
			enum_byname => {foo => 1, bar => 2, baz => 3},
			enum_byval => {1 => "foo", 2 => "bar", 3 => "baz"}}
	],
	"enum"
);
is_deeply(
	[protoparse($oscar, "enum_default")],
	[
		{len => 1, type => "num", packlet => "C", name => "icecream", value => 2,
			enum_byname => {chocolate => 1, vanilla => 2},
			enum_byval => {1 => "chocolate", 2 => "vanilla"}}
	],
	"enum_default"
);
