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
my $es = do "os_sync.pl" or die( $@ || $! );
my $b = $es->bulk_helper;

$b->_serializer->_set_canonical;

## EMPTY

ok $b->add_action(), 'Empty add action';

## INDEX ACTIONS ##

ok $b->add_action(
    index => {
        index        => 'foo',
        id           => 1,
        pipeline     => 'foo',
        routing      => 1,
        version      => 1,
        version_type => 'external',
        source       => { foo => 'bar' },
    },
    index => {
        _index        => 'foo',
        _id           => 2,
        _routing      => 2,
        _version      => 1,
        _version_type => 'external',
        source        => { foo => 'bar' },

    }
    ),
    'Add index actions';

cmp_deeply $b->_buffer,
    [
    q({"index":{"_id":"1","_index":"foo","pipeline":"foo","routing":"1","version":1,"version_type":"external"}}),
    q({"foo":"bar"}),
    q({"index":{"_id":"2","_index":"foo","routing":"2","version":1,"version_type":"external"}}),
    q({"foo":"bar"})
    ],
    "Index actions in buffer";

is $b->_buffer_size,  223, "Index actions buffer size";
is $b->_buffer_count, 2,   "Index actions buffer count";

$b->clear_buffer;

## CREATE ACTIONS ##

ok $b->add_action(
    create => {
        index        => 'foo',
        id           => 1,
        routing      => 1,
        pipeline     => 'foo',
        version      => 1,
        version_type => 'external',
        source       => { foo => 'bar' },
    },
    create => {
        _index        => 'foo',
        _id           => 2,
        _routing      => 2,
        _version      => 1,
        _version_type => 'external',
        source        => { foo => 'bar' },
    }
    ),
    'Add create actions';

cmp_deeply $b->_buffer,
    [
    q({"create":{"_id":"1","_index":"foo","pipeline":"foo","routing":"1","version":1,"version_type":"external"}}),
    q({"foo":"bar"}),
    q({"create":{"_id":"2","_index":"foo","routing":"2","version":1,"version_type":"external"}}),
    q({"foo":"bar"})
    ],
    "Create actions in buffer";
is $b->_buffer_size,  225, "Create actions buffer size";
is $b->_buffer_count, 2,   "Create actions buffer count";

$b->clear_buffer;

## DELETE ACTIONS ##

ok $b->add_action(
    delete => {
        index        => 'foo',
        id           => 1,
        routing      => 1,
        version      => 1,
        version_type => 'external',
    },
    delete => {
        _index       => 'foo',
        _id          => 2,
        _routing     => 2,
        _version     => 1,
        version_type => 'external',
    }
    ),
    'Add delete actions';

cmp_deeply $b->_buffer,
    [
    q({"delete":{"_id":"1","_index":"foo","routing":"1","version":1,"version_type":"external"}}),
    q({"delete":{"_id":"2","_index":"foo","routing":"2","version":1,"version_type":"external"}}),
    ],
    "Delete actions in buffer";

is $b->_buffer_size,  180, "Delete actions buffer size";
is $b->_buffer_count, 2,   "Delete actions buffer count";

$b->clear_buffer;

## UPDATE ACTIONS ##

ok $b->add_action(
    update => {
        index             => 'foo',
        id                => 1,
        routing           => 1,
        version           => 1,
        version_type      => 'external',
        doc               => { foo => 'bar' },
        doc_as_upsert     => \1
    },
    update => {
        _index            => 'foo',
        _id               => 1,
        _routing          => 1,
        _version          => 1,
        _version_type     => 'external',
        script            => 'ctx._source+=1',
        scripted_upsert   => \1,
    }
    ),
    'Add update actions';
    
cmp_deeply $b->_buffer,
    [
    q({"update":{"_id":"1","_index":"foo","routing":"1","version":1,"version_type":"external"}}),
    q({"doc":{"foo":"bar"},"doc_as_upsert":true}),
    q({"update":{"_id":"1","_index":"foo","routing":"1","version":1,"version_type":"external"}}),
    q({"script":"ctx._source+=1","scripted_upsert":true})
    ],
    "Update actions in buffer";

is $b->_buffer_size,  274, "Update actions buffer size";
is $b->_buffer_count, 2,   "Update actions buffer count";

$b->clear_buffer;

## ERRORS ##
throws_ok { $b->add_action( 'foo' => {} ) } qr/Unrecognised action/,
    'Bad action';

throws_ok { $b->add_action( 'index', 'bar' ) } qr/Missing <params>/,
    'Missing params';

throws_ok { $b->add_action( index => { } ) }
qr/Missing .*<index>/, 'Missing index';
throws_ok { $b->add_action( index => { index => 'i' } ) }
qr/Missing <source>/, 'Missing source';

throws_ok {
    $b->add_action(
        index => { index => 'i', source => {}, foo => 1 } );
}
qr/Unknown params/, 'Unknown params';

done_testing;
