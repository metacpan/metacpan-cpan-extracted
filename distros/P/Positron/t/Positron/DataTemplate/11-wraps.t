#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok('Positron::DataTemplate');
}

my $template = Positron::DataTemplate->new();
$template->add_include_paths('t/Positron/DataTemplate/');

my $data = {
    title => 'The title',
    subtitle => 'The subtitle',
    list => [20, 21],
};

# This cannot work, for two reasons:
# 1) the contents of ':' will not be template-processed
# 2) ':' is not a valid environment key in P::Expression
# Meh, let's special-case it ;-)
#
is_deeply($template->process(
    [1, ': "wrap.json"', { color => 'red', subtitle => '$subtitle' }, 3], $data),
    [1, { version => 1.0, title => 'The title', contents => {
        color => 'red', subtitle => 'The subtitle', }, }, 3 ],
    "Wrap in list"
);

is_deeply($template->process(
    [1, ': "wrap_colon.json"', { color => 'red', subtitle => '$subtitle' }, 3], $data),
    [1, { version => 1.0, title => 'The title', contents => {
        color => 'red', subtitle => 'The subtitle', }, }, 3 ],
    "Wrap in list, ':' only"
);

# Hash-Key: auto-interpolate
is_deeply($template->process(
    { one => 1, ': "wrap.json"' => { color => 'red', subtitle => '$subtitle' }, two => 2}, $data),
    { one => 1, version => 1.0, title => 'The title', contents => {
        color => 'red', subtitle => 'The subtitle', }, two => 2},
    "Wrap in hash key"
);

is_deeply($template->process(
    { one => 1, ': "wrap_colon.json"' => { color => 'red', subtitle => '$subtitle' }, two => 2}, $data),
    { one => 1, version => 1.0, title => 'The title', contents => {
        color => 'red', subtitle => 'The subtitle', }, two => 2},
    "Wrap in hash key, : only"
);

# Hash-Value: auto-interpolate
is_deeply($template->process(
    { one => 1, wrap => ': "wrap.json"', two => 2}, $data),
    { one => 1, wrap => { version => 1.0, title => 'The title', contents => undef }, two => 2},
    "Wrap in hash value"
);

is_deeply($template->process(
    { one => 1, wrap => ': "wrap_colon.json"', two => 2}, $data),
    { one => 1, wrap => { version => 1.0, title => 'The title', contents => undef }, two => 2},
    "Wrap in hash value, : only"
);

# Interpolation

is_deeply($template->process(
    [1, ': "wrap_array.json"', ['&list' ], 3], $data),
    [1, [ 11, 'The title', [[20, 21]], 12,], 3 ],
    "Wrap of list"
);

is_deeply($template->process(
    [1, ':- "wrap_array.json"', [ '&-list' ], 3], $data),
    [1, 11, 'The title', [ 20, 21 ], 12, 3 ],
    "Wrap of list, and-minus"
);

is_deeply($template->process(
    [1, ':- "wrap_array.json"', [ '@-list', '&_' ], 3], $data),
    [1, 11, 'The title', 20, 21 , 12, 3 ],
    "Wrap of list, at-minus"
);


is_deeply($template->process(
    [1, ': "wrap_array_interp.json"', ['&list', 13 ], 3], $data),
    [1, [ 11, 'The title', [20, 21], 13, 12,], 3 ],
    "Wrap of list interp"
);

is_deeply($template->process(
    [1, ':- "wrap_array_interp.json"', [ '&-list', 13 ], 3], $data),
    [1, 11, 'The title', 20, 21, 13, 12, 3 ],
    "Wrap of list interp, and-minus"
);

is_deeply($template->process(
    [1, ':- "wrap_array_interp.json"', [ '@-list', '&_' ], 3], $data),
    [1, 11, 'The title', 20, 21 , 12, 3 ],
    "Wrap of list interp, at-minus"
);


is_deeply($template->process(
    [1, ': "wrap_array_minus.json"', ['&list', 13 ], 3], $data),
    [1, [ 11, 'The title', [20, 21], 13, 12,], 3 ],
    "Wrap of list minus"
);

is_deeply($template->process(
    [1, ':- "wrap_array_minus.json"', [ '&-list', 13 ], 3], $data),
    [1, 11, 'The title', 20, 21, 13, 12, 3 ],
    "Wrap of list minus, and-minus"
);

is_deeply($template->process(
    [1, ':- "wrap_array_minus.json"', [ '@-list', '&_' ], 3], $data),
    [1, 11, 'The title', 20, 21 , 12, 3 ],
    "Wrap of list minus, at-minus"
);

done_testing();
