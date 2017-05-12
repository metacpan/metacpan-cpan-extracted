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
    objects => [
        { title => 'title one', id => 'one_1' },
        { title => 'title two', id => 'two_2' },
    ],
    list => [1, 2, 3],
};

is_deeply($template->process([ '@objects', { '$id' => '$title'} ], $data), [ { one_1 => 'title one'}, { two_2 => 'title two'}], "List of objects" );
is_deeply($template->process([ '@objects', '$id', '$title' ], $data), [ 'one_1', 'title one', 'two_2', 'title two'], "List of scalars" );
is_deeply($template->process([ '@objects', ['$id', '$title'] ], $data), [ ['one_1', 'title one'], ['two_2', 'title two']], "List of scalars" );

is_deeply($template->process([ 1, '<', [ '@objects', { '$id' => '$title'} ], 2 ], $data), [ 1, { one_1 => 'title one'}, { two_2 => 'title two'}, 2], "'<' interpolation" );
is_deeply($template->process([ 1, [ '@-objects', { '$id' => '$title'} ], 2 ], $data), [ 1, { one_1 => 'title one'}, { two_2 => 'title two'}, 2], "'@-' interpolation" );

done_testing();

