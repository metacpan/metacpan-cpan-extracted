# OpenSearch::Client is an unofficial client for OpenSearch. 
# It is derived from Search::Elasticsearch version 7.714
# License details from the original work are contained in the
# NOTICE file distributed with this work.
#
#-----------------------------------------------------------------------
# OpenSearch::Client
#-----------------------------------------------------------------------
# Copyright 2026 Mark Dootson
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use Test::More;
use Test::Deep;
use Test::Exception;
use strict;
use warnings;
use lib 't/lib';


plan skip_all => "Skipping Bulk Helpers" unless $ENV{OS_TEST_BULK_HELPERS};

$ENV{OS_VERSION} = '3_0';
my $os = do "os_sync.pl" or die( $@ || $! );

my $TRUE  = $os->transport->serializer->decode('{"true":true}')->{true};
my $FALSE = $os->transport->serializer->decode('{"true":false}')->{true};

diag qq(\nUsing ) . ref($TRUE) . q( to provide "true" refs);
diag qq(Using ) . ref($FALSE) . q( to provide "false" refs);

my $b = $os->bulk_helper(
    max_count   => 0,
    max_size    => 0,
    on_error    => undef              
);

$b->_serializer->_set_canonical;

## STRINGS ARE NUMBERS

ok $b->add_action(
    index => {
        index        => 'foo',
        id           => 1,
        source       => { foo => 'bar' },
    },
    ),
    'Strings are numbers';

cmp_deeply $b->_buffer,
    [
    q({"index":{"_id":"1","_index":"foo"}}),
    q({"foo":"bar"}),
    ],
    "Strings are numbers in buffer";

is $b->_buffer_size,  51, "Strings are numbers buffer size";
is $b->_buffer_count, 1,  "Strings are numbers buffer count";

$b->clear_buffer;

## NUMBERS ARE STRINGS

ok $b->add_action(
    index => {
        index        => 'foo',
        id           => "1",
        version      => "1",
        version_type => 'external',
        source       => { foo => 'bar' },
    },
    ),
    'Numbers are strings';

cmp_deeply $b->_buffer,
    [
    q({"index":{"_id":"1","_index":"foo","version":1,"version_type":"external"}}),
    q({"foo":"bar"}),
    ],
    "Numbers are strings in buffer";

is $b->_buffer_size,  89, "Numbers are strings buffer size";
is $b->_buffer_count, 1,  "Numbers are strings buffer count";

$b->clear_buffer;

## BOOLEANS ARE SIMPLE REFS

ok $b->add_action(
    update => {
        index        => 'foo',
        id           => "1",
        doc           => { foo => 'bar' },
        doc_as_upsert => \1
    },
    update => {
        index        => 'foo',
        id           => "2",
        doc           => { foo => 'bar' },
        doc_as_upsert => \0
    },
    ),
    'Booleans are simple refs';

cmp_deeply $b->_buffer,
    [
    q({"update":{"_id":"1","_index":"foo"}}),
    q({"doc":{"foo":"bar"},"doc_as_upsert":true}),
    q({"update":{"_id":"2","_index":"foo"}}),
    q({"doc":{"foo":"bar"},"doc_as_upsert":false})
    ],
    "Booleans are simple refs in buffer";
is $b->_buffer_size,  163, "Booleans are simple refs buffer size";
is $b->_buffer_count, 2,   "Booleans are simple refs buffer count";

$b->clear_buffer;

## BOOLEANS ARE NUMBERS

ok $b->add_action(
    update => {
        index         => 'foo',
        id            => "1",
        doc           => { foo => 'bar' },
        doc_as_upsert => 1
    },
    update => {
        index         => 'foo',
        id            => "2",
        doc           => { foo => 'bar' },
        doc_as_upsert => 0
    },
    ),
    'Booleans are numbers';

cmp_deeply $b->_buffer,
    [
    q({"update":{"_id":"1","_index":"foo"}}),
    q({"doc":{"foo":"bar"},"doc_as_upsert":true}),
    q({"update":{"_id":"2","_index":"foo"}}),
    q({"doc":{"foo":"bar"},"doc_as_upsert":false})
    ],
    "Booleans are numbers in buffer";
is $b->_buffer_size,  163, "Booleans are numbers buffer size";
is $b->_buffer_count, 2,   "Booleans are numbers buffer count";

$b->clear_buffer;

## BOOLEANS ARE STRINGS

ok $b->add_action(
    update => {
        index         => 'foo',
        id            => "1",
        doc           => { foo => 'bar' },
        doc_as_upsert => 'true'
    },
    update => {
        index         => 'foo',
        id            => "2",
        doc           => { foo => 'bar' },
        doc_as_upsert => 'false'
    },
    update => {
        index         => 'foo',
        id            => "3",
        doc           => { foo => 'bar' },
        doc_as_upsert => 'err'
    },
    ),
    'Booleans are strings';

cmp_deeply $b->_buffer,
    [
    q({"update":{"_id":"1","_index":"foo"}}),
    q({"doc":{"foo":"bar"},"doc_as_upsert":true}),
    q({"update":{"_id":"2","_index":"foo"}}),
    q({"doc":{"foo":"bar"},"doc_as_upsert":false}),
    q({"update":{"_id":"3","_index":"foo"}}),
    q({"doc":{"foo":"bar"},"doc_as_upsert":false})
    ],
    "Booleans are strings in buffer";
is $b->_buffer_size,  245, "Booleans are strings buffer size";
is $b->_buffer_count, 3,   "Booleans are strings buffer count";

$b->clear_buffer;

## BOOLEANS ARE CLASSES

ok $b->add_action(
    update => {
        index         => 'foo',
        id            => "1",
        doc           => { foo => 'bar' },
        doc_as_upsert => $TRUE,
    },
    update => {
        index         => 'foo',
        id            => "2",
        doc           => { foo => 'bar' },
        doc_as_upsert => $FALSE,
    },
    ),
    'Booleans are classes';

cmp_deeply $b->_buffer,
    [
    q({"update":{"_id":"1","_index":"foo"}}),
    q({"doc":{"foo":"bar"},"doc_as_upsert":true}),
    q({"update":{"_id":"2","_index":"foo"}}),
    q({"doc":{"foo":"bar"},"doc_as_upsert":false})
    ],
    "Booleans are classes in buffer";
is $b->_buffer_size,  163, "Booleans are classes buffer size";
is $b->_buffer_count, 2,   "Booleans are classes buffer count";

$b->clear_buffer;


done_testing;
