use strict;
use warnings;

use Tags::Output::Raw;
use Test::More 'tests' => 9;
use Test::NoWarnings;
use Test::Warn;

# Test.
my $obj = Tags::Output::Raw->new;
my @ret;
warning_like {
	@ret = $obj->open_tags;
} qr{^Method open_tags\(\) is deprecated at}, 'Deprecation warning.';
is_deeply(\@ret, [], 'List of open tags in begin.');

$obj->put(
	['b', 'element'],
);
warning_like {
	@ret = $obj->open_tags;
} qr{^Method open_tags\(\) is deprecated at}, 'Deprecation warning.';
is_deeply(\@ret, ['element'], 'List of open tags after adding element.');

# Test.
$obj->put(
	['b', 'other_element'],
);
warning_like {
	@ret = $obj->open_tags;
} qr{^Method open_tags\(\) is deprecated at}, 'Deprecation warning.';
is_deeply(\@ret, ['other_element', 'element'],
	'List of open tags after adding other element.');

# Test.
$obj->finalize;
warning_like {
	@ret = $obj->open_tags;
} qr{^Method open_tags\(\) is deprecated at}, 'Deprecation warning.';
is_deeply(\@ret, [], 'List of open tags after finalization.');
