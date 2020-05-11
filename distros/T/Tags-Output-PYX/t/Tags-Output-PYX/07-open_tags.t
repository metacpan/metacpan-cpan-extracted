use strict;
use warnings;

use Tags::Output::PYX;
use Test::More 'tests' => 9;
use Test::NoWarnings;
use Test::Warn;

# Test.
my $obj = Tags::Output::PYX->new;
my @ret;
warning_like {
	@ret = $obj->open_tags;
} qr{^Method open_tags\(\) is deprecated at}, 'Deprecation warning.';
is_deeply(\@ret, []);

# Test.
$obj->put(
	['b', 'tag'],
);
warning_like {
	@ret = $obj->open_tags;
} qr{^Method open_tags\(\) is deprecated at}, 'Deprecation warning.';
is_deeply(\@ret, ['tag']);

# Test.
$obj->put(
	['b', 'other_tag'],
);
warning_like {
	@ret = $obj->open_tags;
} qr{^Method open_tags\(\) is deprecated at}, 'Deprecation warning.';
is_deeply(\@ret, ['other_tag', 'tag']);

# Test.
$obj->finalize;
warning_like {
	@ret = $obj->open_tags;
} qr{^Method open_tags\(\) is deprecated at}, 'Deprecation warning.';
is_deeply(\@ret, []);
