use strict;
use warnings;

use Tags::Output::Indent;
use Test::More 'tests' => 9;
use Test::Warn;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::Indent->new;
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
