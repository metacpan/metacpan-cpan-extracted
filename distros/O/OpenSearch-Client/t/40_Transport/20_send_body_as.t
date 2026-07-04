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
use OpenSearch::Client;

my $t = OpenSearch::Client->new( send_get_body_as => 'GET' )->transport;

test_tidy( 'GET-empty', { path => '/_search' }, {} );
test_tidy(
    'GET-body',
    { path => '/_search', body => { foo => 'bar' } },
    {   body      => { foo => 'bar' },
        data      => '{"foo":"bar"}',
        method    => 'GET',
        mime_type => 'application/json',
        serialize => 'std',
    }
);

$t = OpenSearch::Client->new( send_get_body_as => 'POST' )->transport;

test_tidy( 'POST-empty', { path => '/_search' }, {} );
test_tidy(
    'POST-eody',
    { path => '/_search', body => { foo => 'bar' } },
    {   body      => { foo => 'bar' },
        data      => '{"foo":"bar"}',
        method    => 'POST',
        mime_type => 'application/json',
        serialize => 'std',
    }
);

$t = OpenSearch::Client->new( send_get_body_as => 'source' )->transport;

test_tidy( 'source-empty', { path => '/_search' }, {} );
test_tidy(
    'source-body',
    { path => '/_search', body => { foo => 'bar' } },
    {   method    => 'GET',
        qs        => { source => '{"foo":"bar"}' },
        mime_type => 'application/json',
        serialize => 'std',
    }
);

#===================================
sub test_tidy {
#===================================
    my ( $title, $params, $test ) = @_;
    $test = {
        method => 'GET',
        path   => '/_search',
        qs     => {},
        ignore => [],
        %$test
    };
    cmp_deeply $t->tidy_request($params), $test, $title;
}

done_testing;
