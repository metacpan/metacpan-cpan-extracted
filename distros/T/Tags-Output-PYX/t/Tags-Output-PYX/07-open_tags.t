use strict;
use warnings;

use Tags::Output::PYX;
use Test::More 'tests' => 9;
use Test::NoWarnings;
use Test::Warn;
use version 0.77;

my $tags_output_version = version->parse($Tags::Output::VERSION);
my $tags_output_supported_version = version->parse(0.09);

# Test.
my $obj = Tags::Output::PYX->new;
my @ret;
if ($tags_output_version < $tags_output_supported_version) {
	@ret = $obj->open_tags;
	SKIP: {
		skip "Warning isn't present.", 1, 1;
	};
} else {
	warning_like {
		@ret = $obj->open_tags;
	} qr{^Method open_tags\(\) is deprecated at}, 'Deprecation warning.';
}
is_deeply(\@ret, [], 'No open tags in begin.');

# Test.
$obj->put(
	['b', 'tag'],
);
if ($tags_output_version < $tags_output_supported_version) {
	@ret = $obj->open_tags;
	SKIP: {
		skip "Warning isn't present.", 1, 1;
	};
} else {
	warning_like {
		@ret = $obj->open_tags;
	} qr{^Method open_tags\(\) is deprecated at}, 'Deprecation warning.';
}
is_deeply(\@ret, ['tag'], "Element 'tag' is opened.");

# Test.
$obj->put(
	['b', 'other_tag'],
);
if ($tags_output_version < $tags_output_supported_version) {
	@ret = $obj->open_tags;
	SKIP: {
		skip "Warning isn't present.", 1, 1;
	};
} else {
	warning_like {
		@ret = $obj->open_tags;
	} qr{^Method open_tags\(\) is deprecated at}, 'Deprecation warning.';
}
is_deeply(\@ret, ['other_tag', 'tag'], 'Two elements are opened.');

# Test.
$obj->finalize;
if ($tags_output_version < $tags_output_supported_version) {
	@ret = $obj->open_tags;
	SKIP: {
		skip "Warning isn't present.", 1, 1;
	};
} else {
	warning_like {
		@ret = $obj->open_tags;
	} qr{^Method open_tags\(\) is deprecated at}, 'Deprecation warning.';
}
is_deeply(\@ret, [], 'No opened elements after finalize().');
