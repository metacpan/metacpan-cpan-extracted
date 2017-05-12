use strict;
use utf8;
use Test::More;
use Parse::JCONF;
use Parse::JCONF::Boolean qw(TRUE FALSE);

my $parser = Parse::JCONF->new();
my $res = $parser->parse_file('t/files/array.jconf');

is_deeply($res, {
	sql_queries => [
		"select * from life",
		"select * from life\n\tinner join death",
		"delete from life where id=\$you"
	],
	mixed => [
		1,
		2,
		3,
		"this is smile: \N{U+263A}",
		undef,
		TRUE,
		-1E-1
	],
	with_comments => [
		FALSE,
		"joke\n\N{U+263A}",
		999E-999
	],
	empty   => [],
	one_elt => [undef]
}, "parse arrays");

done_testing;
