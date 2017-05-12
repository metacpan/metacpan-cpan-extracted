#!perl
use lib qw( t/lib );
use strict;
use warnings;
use Test::More tests => 9;
use TAP::Filter;
use TAP::Filter::Iterator;

{
    eval { TAP::Filter->add_filter( 'FakeFilter' ) };
    ok !$@, 'add_filter';
    my @filters = TAP::Filter->get_filters;
    is scalar @filters, 1, 'one filter';
    isa_ok $filters[0], 'TAP::Filter::Iterator';
    isa_ok $filters[0], 'FakeFilter';
}

{
    eval { TAP::Filter->add_filter( TAP::Filter::Iterator->new ) };
    ok !$@, 'add_filter again';
    my @filters = TAP::Filter->get_filters;
    is scalar @filters, 2, 'two filters';
    isa_ok $filters[0], 'TAP::Filter::Iterator';
    isa_ok $filters[0], 'FakeFilter';
    isa_ok $filters[1], 'TAP::Filter::Iterator';
}
