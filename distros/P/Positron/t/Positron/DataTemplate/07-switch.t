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
    'one' => 1,
    'list' => [1],
    'empty_list' => [],
    'hash' => { 1 => 2 },
    'empty_hash' => {},
};

is_deeply($template->process( { '|one' => { 1 => 'eins', 2 => 'zwei', 3 => 'drei' }}, $data ), 'eins', "With scalar match");
is_deeply($template->process( { '|one' => { 1 => 'eins', 2 => 'zwei', 3 => 'drei', '|' => 'null' }}, $data ), 'eins', "With scalar match and default");
is_deeply($template->process( [ { '|two' => { 1 => 'eins', 2 => 'zwei', 3 => 'drei' }} ], $data ), [], "With no match and no default");
is_deeply($template->process( { '|two' => { 1 => 'eins', 2 => 'zwei', 3 => 'drei', '|' => 'null' }}, $data ), 'null', "With no match and default");

# TODO: what about list / hash valued keys? Count number of elements?

is_deeply($template->process( { '|one' => { 1 => '&list', 2 => '&empty_list', 3 => 'drei' }}, $data ), [1], "With list match");
is_deeply($template->process( { '|one' => { 1 => ['?one', { a => 'b' }, { c => 'd' }], 2 => '&empty_list'}}, $data ), { a => 'b' }, "With list match and conditional inside");
is_deeply($template->process( { '|two' => { 1 => '&list', '|' => '&hash'}}, $data ), { 1 => 2 }, "With no match and direct inclusion result");
is_deeply($template->process( { '|two' => { 1 => '&list', '|' => ['?one', { a => 'b' }, { c => 'd' }] }}, $data ), { a => 'b' }, "With list match and conditional inside");

done_testing();
