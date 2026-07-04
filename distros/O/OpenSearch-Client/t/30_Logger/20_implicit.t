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
use OpenSearch::Client;

use Log::Any::Adapter;

Log::Any::Adapter->set( { category => 'opensearch.event' }, 'Stdout' );
Log::Any::Adapter->set( { category => 'opensearch.trace' }, 'Stderr' );

# default

isa_ok my $l = OpenSearch::Client->new->logger,
    'OpenSearch::Client::Logger::LogAny',
    'Default Logger';

isa_ok $l->log_handle->adapter, 'Log::Any::Adapter::Stdout',
    'Default - Log to Stdout';
isa_ok $l->trace_handle->adapter, 'Log::Any::Adapter::Stderr',
    'Default - Trace to Stderr';

# override

isa_ok $l
    = OpenSearch::Client->new( log_to => 'Stderr', trace_to => 'Stdout' )
    ->logger,
    'OpenSearch::Client::Logger::LogAny',
    'Override Logger';

isa_ok $l->log_handle->adapter, 'Log::Any::Adapter::Stderr',
    'Override - Log to Stderr';
isa_ok $l->trace_handle->adapter, 'Log::Any::Adapter::Stdout',
    'Override - Trace to Stdout';

done_testing;
