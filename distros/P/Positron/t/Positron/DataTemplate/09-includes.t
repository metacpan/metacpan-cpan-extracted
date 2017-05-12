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
    'list' => [{ id => 1, title => 'eins'}, { id => 2, title => 'zwei' }],
    'hash' => { 1 => 2 },
};

is_deeply($template->process( [1, '. "plain.json"', 2], $data ), [1, { one => 1 }, 2], "Include a plain file");
is_deeply($template->process( { plain => '. "plain.json"' }, $data ), { plain => { one => 1 }}, "Include a plain file in a hash");
is_deeply($template->process( [1, '. "structure.json"', 2], $data ), [1, { one => { 1 => 2 }, two => ['eins', 'zwei'] }, 2], "Include a file with structure");

is_deeply($template->process( [1, '. "lists.json"', 2], $data ), [1, [2, [3, 4], 5 ], 2], "Include a list file");
is_deeply($template->process( [1, '.- "lists.json"', 2], $data ), [1, 2, [3, 4], 5, 2], "Include a list file with -");
is_deeply($template->process( [1, '<', '. "lists.json"', 2], $data ), [1, 2, [3, 4], 5, 2], "Include a list file with <");

is_deeply($template->process( { two => 2, '< 1' => '. "plain.json"' }, $data ), { one => 1, two => 2 }, "Include a plain file in a hash with <");

done_testing();
