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
    numbers => {
        one => 1,
        two => 2,
    },
    lists => {
        en => [ 
            { title => 'one', id => 1 },
            { title => 'two', id => 2 },
        ],
        de => [
            { title => 'eins', id => 1 },
            { title => 'zwei', id => 2 },
        ],
    },
};

is_deeply($template->process(
    { '%numbers' => { 'key {$key}' => '$value', 'minus {$key}' => '-{$value}' } }, $data),
    { 'key one' => 1, 'minus one' => -1, 'key two' => 2, 'minus two' => -2 },
    "Hash with Keys and values"
);
is_deeply($template->process(
    { '%lists' => { '$key' => [ '@value', '$title', '$id'] } }, $data),
    { 'en' => ['one', 1, 'two', 2], 'de' => ['eins', 1, 'zwei', 2] },
    "Hash with lists as value"
);

done_testing();
