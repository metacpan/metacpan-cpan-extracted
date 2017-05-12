use strict;
use Test::More;
use_ok('Parse::JCONF');

my $parser = Parse::JCONF->new();
my $res = $parser->parse("");
is_deeply($res, {}, "parse empty string");

$res = $parser->parse(
	"
	# some comment
	
	#another comment
	
	# !!!! end # !!!!
	"
);
is_deeply($res, {}, "parse empty string with comments");

done_testing;
