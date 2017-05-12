#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok('Positron::DataTemplate');
}

my $template = Positron::DataTemplate->new();

my $data = {
    'if' => 1,
    'false' => 0,
    'blank' => '',
    'list' => [1],
    'empty_list' => [],
    'hash' => { 1 => 2 },
    'empty_hash' => {},
};

is_deeply($template->process( [ '?if', 'then', 'else' ], $data ), 'then', "With scalar value");
is_deeply($template->process( [ '?if', [1, 2], [3, 4] ], $data ), [1, 2], "With array value");
is_deeply($template->process( [ 'foo', [ '?if', [1, 2], [3, 4] ], 'bar'], $data ), ['foo', [ 1, 2 ], 'bar' ], "Inside a list");

is_deeply($template->process( [ 'foo', [ '?-if', [1, 2], [3, 4] ], 'bar'], $data ), ['foo', 1, 2, 'bar' ], "Interpolation with -");
is_deeply($template->process( [ 'foo', '<', [ '?if', [1, 2], [3, 4] ], 'bar'], $data ), ['foo', 1, 2, 'bar' ], "Interpolation with <");
is_deeply($template->process( [ 'foo', '<', [ '?-if', [1, 2], [3, 4] ], 'bar'], $data ), ['foo', 1, 2, 'bar' ], "Interpolation with both");

is_deeply($template->process( { key => ['?if', 'value', 'non-value']}, $data ), { key => 'value' }, "As hash value");
is_deeply($template->process( [ 0, ['?if', 1 ] ], $data ), [0, 1], "No else-clause when true");
is_deeply($template->process( [ 0, ['?false', 1 ] ], $data ), [0], "No else-clause when false");

# Truthiness tests
is_deeply($template->process( ['?blank', 1, 2], $data ), 2, "Empty string counts as false");
is_deeply($template->process( ['?list', 1, 2], $data ), 1, "Full list counts as true");
is_deeply($template->process( ['?empty_list', 1, 2], $data ), 2, "Empty list counts as true");
is_deeply($template->process( ['?hash', 1, 2], $data ), 1, "Full hash counts as true");
is_deeply($template->process( ['?empty_hash', 1, 2], $data ), 2, "Empty hash counts as true");

is_deeply($template->process( [ '?if', '&list', 'else' ], $data ), [1], "Evaluate value");
is_deeply($template->process( [ '?if', ['?false', 3, 4 ], 'else' ], $data ), '4', "Double if");

# Hashes: interpolating and "conditional keys"

is_deeply(
    $template->process( { '< 1' => ['?if', { 'a' => 'b' }, { 'c' => 'd' }], 'this' => 'stays' }, $data),
    {'a' => 'b', 'this' => 'stays'}, "Conditional hash slice (true)"
);
is_deeply(
    $template->process( { '< 1' => ['?false', { 'a' => 'b' }, { 'c' => 'd' }], 'this' => 'stays' }, $data),
    {'c' => 'd', 'this' => 'stays'}, "Conditional hash slice (false)"
);
is_deeply(
    $template->process( { '?if' => { 'a' => 'b' }, 'this' => 'stays' }, $data),
    {'a' => 'b', 'this' => 'stays'}, "Conditional key (true)"
);
is_deeply(
    $template->process( { '?false' => { 'a' => 'b' }, 'this' => 'stays' }, $data),
    {'this' => 'stays'}, "Conditional key (false)"
);
done_testing();
