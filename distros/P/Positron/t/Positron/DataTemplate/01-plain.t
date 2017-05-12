#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok('Positron::DataTemplate');
}

my $template = Positron::DataTemplate->new();

# Idempotencies on plain old data
is_deeply($template->process(), undef, "No input, undefined output");
is_deeply($template->process(undef, {}), undef, "Undefined input, undefined output");
is_deeply($template->process('', {}), '', "Empty input, empty output");
is_deeply($template->process(0, {}), 0, "Zero input, zero output");
is_deeply($template->process({ foo => 1, bar => [0, 1, 2] }, {}), { foo => 1, bar => [0, 1, 2] }, "plain input, plain output");

# plain interpolations: '>' and '> 1'

is_deeply($template->process([1, '<', [2, 3], 4], {}), [1, 2, 3, 4], "'<' interpolates lists");
is_deeply($template->process({ a => 1, '< 1' => { b => 2 }}, {}), { a => 1, b => 2 }, "'<' interpolates hashes");

done_testing();
