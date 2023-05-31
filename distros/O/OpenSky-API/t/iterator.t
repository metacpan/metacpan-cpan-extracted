#!/usr/bin/env perl

use lib 'lib';
use Test::Most;
use OpenSky::API::Utils::Iterator;

my $results = OpenSky::API::Utils::Iterator->new( rows => [qw/foo bar baz/] );

is $results->count, 3,     'We should have the correct number of results in our iterator';
is $results->first, 'foo', 'first() result should always be foo';
is $results->next,  'foo', 'Calling next() should return the first result';
is $results->first, 'foo', 'first() result should always be foo';
is $results->next,  'bar', 'Calling next() should return the second result';
is $results->first, 'foo', 'first() result should always be foo';
is $results->next,  'baz', 'Calling next() should return the third result';
ok !defined $results->next, '... and then undef when the iterator is exhausted';

ok $results->reset, 'We should be able to reset the iterator';
is $results->first, 'foo', 'first() result should always be foo';
is $results->next,  'foo', 'Calling next() should return the first result';
is $results->first, 'foo', 'first() result should always be foo';
is $results->next,  'bar', 'Calling next() should return the second result';
is $results->first, 'foo', 'first() result should always be foo';
is $results->next,  'baz', 'Calling next() should return the third result';
ok !defined $results->next, '... and then undef when the iterator is exhausted';

eq_or_diff [ $results->all ], [qw/foo bar baz/], 'all() should return all results';

done_testing;
