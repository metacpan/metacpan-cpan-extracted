#!/usr/bin/env perl
# Mock-backed unit tests translated from
# signalwire-python/tests/unit/rest/test_pagination_mock.py.
#
# Exercises SignalWire::REST::Pagination::PaginatedIterator end-to-end:
# constructor records http/path/params/data_key without fetching, and
# iterating walks the links.next cursor across multiple pages.
#
# We use GET /api/fabric/addresses (endpoint id fabric.list_fabric_addresses)
# because (a) the mock has a stable spec-derived endpoint id and (b) we
# can stage one-shot scenarios for it via MockTest::scenario_set.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use MockTest;
use SignalWire::REST::Pagination;

my $FABRIC_ADDRESSES_PATH        = '/api/fabric/addresses';
my $FABRIC_ADDRESSES_ENDPOINT_ID = 'fabric.list_fabric_addresses';

subtest 'TestPaginatedIterator' => sub {
    subtest 'test_init_state' => sub {
        # Constructor records http/path/params/data_key WITHOUT fetching.
        my $client = MockTest::client();
        my $it = SignalWire::REST::Pagination::PaginatedIterator->new(
            http     => $client->_http,
            path     => $FABRIC_ADDRESSES_PATH,
            params   => { page_size => 2 },
            data_key => 'data',
        );
        is($it->http,     $client->_http,           'http stored');
        is($it->path,     $FABRIC_ADDRESSES_PATH,   'path stored');
        is_deeply($it->params, { page_size => 2 },  'params stored');
        is($it->data_key, 'data',                   'data_key stored');
        is($it->_index,   0,                        'index starts at 0');
        is_deeply($it->_items, [],                  '_items starts empty');
        ok(!$it->_done,                             '_done starts false');
        # Journal must be empty - no HTTP went out.
        my $j = MockTest::journal_all();
        is(scalar(@$j), 0, 'journal empty after construction');
    };

    subtest 'test_iter_returns_self' => sub {
        my $client = MockTest::client();
        my $it = SignalWire::REST::Pagination::PaginatedIterator->new(
            http     => $client->_http,
            path     => $FABRIC_ADDRESSES_PATH,
            data_key => 'data',
        );
        # Call the dunder directly so the static coverage audit sees it.
        my $same = $it->__iter__;
        is($same, $it, '__iter__ returns self');
        # Still no HTTP yet.
        my $j = MockTest::journal_all();
        is(scalar(@$j), 0, 'journal empty after __iter__');
    };

    subtest 'test_next_pages_through_all_items' => sub {
        # MockTest::client() resets journal + scenarios. Stage two pages
        # AFTER reset so they survive.
        my $client = MockTest::client();
        # Page 1 has a next cursor.
        MockTest::scenario_set(
            $FABRIC_ADDRESSES_ENDPOINT_ID, 200,
            {
                data => [
                    { id => 'addr-1', name => 'first' },
                    { id => 'addr-2', name => 'second' },
                ],
                links => {
                    next => 'http://example.com/api/fabric/addresses?cursor=page2',
                },
            },
        );
        # Page 2 is terminal (no next).
        MockTest::scenario_set(
            $FABRIC_ADDRESSES_ENDPOINT_ID, 200,
            {
                data  => [{ id => 'addr-3', name => 'third' }],
                links => {},
            },
        );

        my $it = SignalWire::REST::Pagination::PaginatedIterator->new(
            http     => $client->_http,
            path     => $FABRIC_ADDRESSES_PATH,
            data_key => 'data',
        );
        my @collected = $it->all;
        # All three items, in order.
        is_deeply(
            [ map { $_->{id} } @collected ],
            [ 'addr-1', 'addr-2', 'addr-3' ],
            'collected ids match across pages',
        );
        # Journal must have exactly two GETs at the same path.
        my $j = MockTest::journal_all();
        my @gets = grep { $_->{path} eq $FABRIC_ADDRESSES_PATH } @$j;
        is(scalar(@gets), 2, 'two paginated GETs recorded');
        # The second fetch carries cursor=page2 from the first response's
        # links.next.
        is_deeply($gets[1]{query_params}{cursor}, ['page2'],
            'second fetch carries cursor=page2');
    };

    subtest 'test_next_raises_stop_iteration_when_done' => sub {
        # One terminal page.
        my $client = MockTest::client();
        MockTest::scenario_set(
            $FABRIC_ADDRESSES_ENDPOINT_ID, 200,
            {
                data  => [{ id => 'only-one' }],
                links => {},
            },
        );
        my $it = SignalWire::REST::Pagination::PaginatedIterator->new(
            http     => $client->_http,
            path     => $FABRIC_ADDRESSES_PATH,
            data_key => 'data',
        );
        # Call __next__ explicitly so the static coverage audit sees it.
        my $first = $it->__next__;
        is_deeply($first, { id => 'only-one' }, 'first __next__ returns item');
        # Exhausted - returns undef (Perl-idiomatic StopIteration).
        my $second = $it->__next__;
        ok(!defined $second, 'second __next__ returns undef (exhausted)');
    };
};

done_testing();
