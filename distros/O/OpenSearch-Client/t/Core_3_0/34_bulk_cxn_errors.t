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
use Log::Any::Adapter;

plan skip_all => "Skipping Bulk Helpers" unless $ENV{OS_TEST_BULK_HELPERS};

$ENV{OS_VERSION}   = '3_0';
$ENV{OS}           = '10.255.255.1:9200';
$ENV{OS_SKIP_PING} = 1;
$ENV{OS_CXN_POOL}  = 'Static';
$ENV{OS_TIMEOUT}   = 1;

my $es = do "os_sync.pl" or die( $@ || $! );

# Check that the buffer is not cleared on a NoNodes exception

my $b = $es->bulk_helper( index => 'foo', type => 'bar' );
$b->create_docs( { foo => 'bar' } );

is $b->_buffer_count, 1, "Buffer count pre-flush";
throws_ok { $b->flush } 'OpenSearch::Client::Error::NoNodes';
is $b->_buffer_count, 1, "Buffer count post-flush";

done_testing;
