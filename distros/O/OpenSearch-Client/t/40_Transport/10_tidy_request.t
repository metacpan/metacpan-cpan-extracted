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

isa_ok my $t = OpenSearch::Client->new->transport,
    'OpenSearch::Client::Transport';
test_tidy( 'Empty', {}, {} );
test_tidy( 'Method', { method => 'POST' }, { method => 'POST' } );
test_tidy( 'Path',   { path   => '/foo' }, { path   => '/foo' } );
test_tidy( 'QS', { qs => { foo => 'bar' } }, { qs => { foo => 'bar' } } );

test_tidy(
    'Body - Str',
    { body => 'foo' },
    {   body      => 'foo',
        data      => 'foo',
        serialize => 'std',
        mime_type => 'application/json',
    }
);

test_tidy(
    'Body - Hash',
    { body => { foo => 'bar' } },
    {   body      => { foo => 'bar' },
        data      => '{"foo":"bar"}',
        serialize => 'std',
        mime_type => 'application/json',
    }
);

test_tidy(
    'Body - Array',
    { body => [ { foo => 'bar' } ] },
    {   body      => [ { foo => 'bar' } ],
        data      => '[{"foo":"bar"}]',
        serialize => 'std',
        mime_type => 'application/json',
    }
);

test_tidy(
    'Body - Bulk',
    { body => [ { foo => 'bar' } ], serialize => 'bulk' },
    {   body      => [ { foo => 'bar' } ],
        data      => qq({"foo":"bar"}\n),
        serialize => 'bulk',
        mime_type => 'application/x-ndjson',
    }
);

test_tidy(
    'MimeType',
    { mime_type => 'text/plain', body => 'foo' },
    {   mime_type => 'text/plain',
        body      => 'foo',
        data      => 'foo',
        serialize => 'std'
    }
);

#===================================
sub test_tidy {
#===================================
    my ( $title, $params, $test ) = @_;
    $test = {
        method => 'GET',
        path   => '/',
        qs     => {},
        ignore => [],
        %$test
    };
    cmp_deeply $t->tidy_request($params), $test, $title;
}

done_testing;
