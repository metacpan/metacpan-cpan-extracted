#!/usr/bin/env perl -w

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Test::MockModule;

use Net::Google::Drive::Simple::Item;

like(
    dies { Net::Google::Drive::Simple::Item->new },
    qr/new is expecting one hashref/,
    "new without arg"
);

like(
    dies { Net::Google::Drive::Simple::Item->new( data => [] ) },
    qr/new is expecting one hashref/,
    "new without hash ref"
);

my $data = {
    fruit => 'apple',
    size  => 42,
    color => 'red',
    list  => [ 1 .. 3 ],
    hash  => { 1 .. 4 },
};

my $item = Net::Google::Drive::Simple::Item->new($data);

isa_ok $item, 'Net::Google::Drive::Simple::Item';

is $item->fruit, 'apple', 'fruit';
is $item->Fruit, 'apple', 'Fruit';
is $item->FruiT, 'apple', 'FruiT';
is $item->FRUIT, 'apple', 'FRUIT';

is $item->size, 42, 'size';

is $item->color, 'red', 'color is red';
is $item->list, [ 1 .. 3 ], 'a list';
is $item->hash, { 1 .. 4 }, 'one hash';

like(
    dies {
        $item->boom
    },
    qr/Cannot find any attribute named 'boom'/,
    "unknown attribute"
);

$data->{mimeType} = undef;

is $item->is_folder, 0, 'not a folder';
is $item->is_file,   1, 'maybe a file';

$data->{mimeType} = 'application/vnd.google-apps.folder';

is $item->is_folder, 1, 'this is a folder';
is $item->is_file,   0, 'not a file';

done_testing;
