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
    this => 'that',
    list => [1, 'one'],
    hash => { key => 'value' },
};

is_deeply($template->process('&this', $data), 'that', 'Direct string inclusion' );
is_deeply($template->process('&list', $data), [1, 'one'], 'Direct list inclusion' );
is_deeply($template->process('&hash', $data), { key => 'value' }, 'Direct list inclusion' );

is_deeply($template->process(['&this', '&list', ['&hash']], $data), ['that', [1, 'one'], [{ key => 'value' }]], 'Nested list inclusions' );
is_deeply($template->process({ key => '&hash', '&this' => '&list'}, $data), { key => { key => 'value'}, that => [1, 'one']},"Nested hash inclusions");

is_deeply($template->process(',this', $data), 'that', 'Direct string inclusion' );
is_deeply($template->process(',list', $data), [1, 'one'], 'Direct list inclusion' );
is_deeply($template->process(',hash', $data), { key => 'value' }, 'Direct list inclusion' );

is_deeply($template->process([',this', ',list', [',hash']], $data), ['that', [1, 'one'], [{ key => 'value' }]], 'Nested list inclusions' );
is_deeply($template->process({ key => ',hash', ',this' => ',list'}, $data), { key => { key => 'value'}, that => [1, 'one']},"Nested hash inclusions");

is_deeply($template->process([3, '<', '&list', 4], $data), [3, 1, 'one', 4], "'<' interpolation for lists");
is_deeply($template->process([3, '&-list', 4], $data), [3, 1, 'one', 4], "'&-' interpolation for lists");
is_deeply($template->process([3, '<', '&-list', 4], $data), [3, 1, 'one', 4], "double interpolation for lists");

is_deeply($template->process({ a => 0, '< 1' => '&hash'}, $data), { a => 0, key => 'value' }, "'<' interpolation for hashes");

done_testing();
