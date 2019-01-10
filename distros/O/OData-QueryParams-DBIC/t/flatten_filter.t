#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OData::QueryParams::DBIC;

use Data::Dumper;

my $sub = OData::QueryParams::DBIC->can('_flatten_filter');
ok $sub;

{
    my $object = {
        operator => 'eq',
        subject  => 'col1',
        value    => 'test',
        sub_type => 'column',
    };

    my %filter = $sub->($object);

    is_deeply \%filter, { col1 => { '=' => 'test' } };
}

{
    my $object = {
        operator => 'eq',
        subject  => 'col1',
        value    => 'test',
    };

    my %filter = $sub->($object);

    is_deeply \%filter, { col1 => { '=' => 'test' } };
}

{
    my $object = {
        operator => 'eq',
        subject  => 'col1',
        value    => 'test',
    };

    my %filter = $sub->($object, me => 1 );

    is_deeply \%filter, { col1 => { '=' => 'test' } };
}

done_testing();
