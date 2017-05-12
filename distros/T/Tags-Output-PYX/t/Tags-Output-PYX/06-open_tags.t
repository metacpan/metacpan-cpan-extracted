# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Output::PYX;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::PYX->new;
my @ret = $obj->open_tags;
is_deeply(\@ret, []);

# Test.
$obj->put(
	['b', 'tag'],
);
@ret = $obj->open_tags;
is_deeply(\@ret, ['tag']);

# Test.
$obj->put(
	['b', 'other_tag'],
);
@ret = $obj->open_tags;
is_deeply(\@ret, ['other_tag', 'tag']);

# Test.
$obj->finalize;
@ret = $obj->open_tags;
is_deeply(\@ret, []);
