use strict;
use warnings;

use Tags::Output::PYX;
use Test::More 'tests' => 5;
use Test::NoWarnings;
use version 0.77;

my $tags_output_version = version->parse($Tags::Output::VERSION);
my $tags_output_supported_version = version->parse(0.09);
SKIP: {
	skip 'Tags::Output < 0.09', 4 if $tags_output_version < $tags_output_supported_version;

	# Test.
	my $obj = Tags::Output::PYX->new;
	my @ret = $obj->open_elements;
	is_deeply(\@ret, []);

	# Test.
	$obj->put(
		['b', 'element'],
	);
	@ret = $obj->open_elements;
	is_deeply(\@ret, ['element']);

	# Test.
	$obj->put(
		['b', 'other_element'],
	);
	@ret = $obj->open_elements;
	is_deeply(\@ret, ['other_element', 'element']);

	# Test.
	$obj->finalize;
	@ret = $obj->open_elements;
	is_deeply(\@ret, []);
};
