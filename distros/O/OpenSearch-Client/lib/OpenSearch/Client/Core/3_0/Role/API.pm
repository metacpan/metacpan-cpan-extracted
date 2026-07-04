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

package OpenSearch::Client::Core::3_0::Role::API;
$OpenSearch::Client::Core::3_0::Role::API::VERSION = '3.007002';

use Moo::Role;
with 'OpenSearch::Client::Role::API';

use OpenSearch::Client::Util qw(throw);
use namespace::clean;

has 'api_version' => ( is => 'ro', default => '3_0' );

our %API;

sub api {
    my $name = $_[1] || return \%API;
    return $API{$name}
        || throw( 'Internal', "Unknown api name ($name)" );
}

%API = (
        
    'bulk_helper.metadata_qs' => { params => {
        '_source'                 => '_source',
        '_source_excludes'        => '_source_excludes',
        '_source_includes'        => '_source_includes',
        'index'                   => 'index',
        'pipeline'                => 'pipeline',
        'refresh'                 => 'refresh',
        'require_alias'           => 'require_alias',
        'routing'                 => 'routing',
        'timeout'                 => 'timeout',
        'type'                    => 'type',
        'wait_for_active_shards'  => 'wait_for_active_shards',

        'source'                  => '_source',
        'source_excludes'         => '_source_excludes',
        'source_includes'         => '_source_includes',
        '_index'                  => 'index',
        '_pipeline'               => 'pipeline',
        '_refresh'                => 'refresh',
        '_require_alias'          => 'require_alias',
        '_routing'                => 'routing',
        '_timeout'                => 'timeout',
        '_type'                   => 'type',
        '_wait_for_active_shards' => 'wait_for_active_shards',
         # Common API query parameters
        'error_trace'             => 'error_trace',
        'filter_path'             => 'filter_path',
        'human'                   => 'human',
        'pretty'                  => 'pretty',
        # 'source'                  => 'source', # not for 
    }},
    
    'bulk_helper.metadata_action' => { params => {
        _index          => '_index', 
        _id             => '_id',
        _require_alias  => '_require_alias',
        routing         => 'routing',
        version         => 'version',
        version_type    => 'version_type',
        if_seq_no       => 'if_seq_no',
        if_primary_term => 'if_primary_term',
        pipeline        => 'pipeline',
        index           => '_index', 
        id              => '_id',
        require_alias   => '_require_alias',
        _routing         => 'routing',
        _version         => 'version',
        _version_type    => 'version_type',
        _if_seq_no       => 'if_seq_no',
        _if_primary_term => 'if_primary_term',
        _pipeline        => 'pipeline',
    }},
    
    'bulk_helper.action_data_types' => { params => {
        _index          => 'string', 
        _id             => 'string',
        _require_alias  => 'boolean',
        routing         => 'string',
        version         => 'number',
        version_type    => 'string',
        if_seq_no       => 'number',
        if_primary_term => 'number',
        pipeline        => 'string',
     }},
             
     'bulk_helper.update_data_types' => { params => {
        doc             => 'REF',
        doc_as_upsert   => 'boolean',
        upsert          => 'REF',
        script          => 'REF',
        params          => 'REF',
        scripted_upsert => 'boolean',
     }},
     
## AUTO GENERATED API START


    '_core.bulk' => {
        body    => { required => 1 },
        doc     => 'https://opensearch.org/docs/latest/api-reference/document-apis/bulk/',
        method  => 'POST',
        parts   => { index => {}},
        paths   => [
            [ { index => 0 }, "{index}", "_bulk" ],
            [ {}, "_bulk" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            '_source'                 => 'list',
            '_source_excludes'        => 'list',
            '_source_includes'        => 'list',
            'index'                   => 'string',
            'pipeline'                => 'string',
            'refresh'                 => 'boolean|string',
            'require_alias'           => 'boolean',
            'routing'                 => 'string',
            'timeout'                 => 'string',
            'type'                    => 'string',
            'wait_for_active_shards'  => 'string',
             # Common API query parameters
            'error_trace'             => 'boolean',
            'filter_path'             => 'list',
            'human'                   => 'boolean',
            'pretty'                  => 'boolean',
            'source'                  => 'string',
        },
        serialize => 'bulk',
    },

    '_core.bulk_stream' => {
        body    => { required => 1 },
        doc     => 'https://opensearch.org/docs/latest/api-reference/document-apis/bulk-streaming/',
        method  => 'POST',
        parts   => { index => {}},
        paths   => [
            [ { index => 0 }, "{index}", "_bulk", "stream" ],
            [ {}, "_bulk", "stream" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            '_source'                 => 'list',
            '_source_excludes'        => 'list',
            '_source_includes'        => 'list',
            'batch_interval'          => 'string',
            'batch_size'              => 'number',
            'pipeline'                => 'string',
            'refresh'                 => 'boolean|string',
            'require_alias'           => 'boolean',
            'routing'                 => 'list',
            'timeout'                 => 'string',
            'type'                    => 'string',
            'wait_for_active_shards'  => 'string',
             # Common API query parameters
            'error_trace'             => 'boolean',
            'filter_path'             => 'list',
            'human'                   => 'boolean',
            'pretty'                  => 'boolean',
            'source'                  => 'string',
        },
        serialize => 'bulk',
    },

    '_core.clear_scroll' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/scroll/',
        method  => 'DELETE',
        parts   => { scroll_id => {  multi => 1 }},
        paths   => [
            [ { scroll_id => 2 }, "_search", "scroll", "{scroll_id}" ],
            [ {}, "_search", "scroll" ]
        ],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    '_core.count' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/count/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 0 }, "{index}", "_count" ],
            [ {}, "_count" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'    => 'boolean',
            'analyze_wildcard'    => 'boolean',
            'analyzer'            => 'string',
            'default_operator'    => 'string',
            'df'                  => 'string',
            'expand_wildcards'    => 'list',
            'ignore_throttled'    => 'boolean',
            'ignore_unavailable'  => 'boolean',
            'lenient'             => 'boolean',
            'min_score'           => 'number',
            'preference'          => 'string',
            'q'                   => 'string',
            'routing'             => 'list',
            'terminate_after'     => 'number',
             # Common API query parameters
            'error_trace'         => 'boolean',
            'filter_path'         => 'list',
            'human'               => 'boolean',
            'pretty'              => 'boolean',
            'source'              => 'string',
        },
    },

    '_core.create' => {
        body    => { required => 1 },
        doc     => 'https://opensearch.org/docs/latest/api-reference/document-apis/index-document/',
        method  => 'POST',
        parts   => { id => {  required => 1 }, index => {  required => 1 }},
        paths   => [[ { index => 0, id => 2 }, "{index}", "_create", "{id}" ]],
        qs      => {
             # Endpoint specific query parameters
            'pipeline'                => 'string',
            'refresh'                 => 'boolean|string',
            'routing'                 => 'list',
            'timeout'                 => 'string',
            'version'                 => 'number',
            'version_type'            => 'string',
            'wait_for_active_shards'  => 'string',
             # Common API query parameters
            'error_trace'             => 'boolean',
            'filter_path'             => 'list',
            'human'                   => 'boolean',
            'pretty'                  => 'boolean',
            'source'                  => 'string',
        },
    },

    '_core.create_pit' => {
        doc     => 'https://opensearch.org/docs/latest/search-plugins/point-in-time-api/#create-a-pit',
        method  => 'POST',
        parts   => { index => {  multi => 1,  required => 1 }},
        paths   => [[ { index => 0 }, "{index}", "_search", "point_in_time" ]],
        qs      => {
             # Endpoint specific query parameters
            'allow_partial_pit_creation'  => 'boolean',
            'expand_wildcards'            => 'list',
            'keep_alive'                  => 'string',
            'preference'                  => 'string',
            'routing'                     => 'list',
             # Common API query parameters
            'error_trace'                 => 'boolean',
            'filter_path'                 => 'list',
            'human'                       => 'boolean',
            'pretty'                      => 'boolean',
            'source'                      => 'string',
        },
    },

    '_core.delete' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/document-apis/delete-document/',
        method  => 'DELETE',
        parts   => { id => {  required => 1 }, index => {  required => 1 }},
        paths   => [[ { index => 0, id => 2 }, "{index}", "_doc", "{id}" ]],
        qs      => {
             # Endpoint specific query parameters
            'if_primary_term'         => 'number',
            'if_seq_no'               => 'number',
            'refresh'                 => 'boolean|string',
            'routing'                 => 'list',
            'timeout'                 => 'string',
            'version'                 => 'number',
            'version_type'            => 'string',
            'wait_for_active_shards'  => 'string',
             # Common API query parameters
            'error_trace'             => 'boolean',
            'filter_path'             => 'list',
            'human'                   => 'boolean',
            'pretty'                  => 'boolean',
            'source'                  => 'string',
        },
    },

    '_core.delete_all_pits' => {
        doc     => 'https://opensearch.org/docs/latest/search-plugins/point-in-time-api/#delete-pits',
        method  => 'DELETE',
        parts   => {},
        paths   => [[ {}, "_search", "point_in_time", "_all" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    '_core.delete_by_query' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/document-apis/delete-by-query/',
        method  => 'POST',
        parts   => { index => {  multi => 1,  required => 1 }},
        paths   => [[ { index => 0 }, "{index}", "_delete_by_query" ]],
        qs      => {
             # Endpoint specific query parameters
            '_source'                 => 'list',
            '_source_excludes'        => 'list',
            '_source_includes'        => 'list',
            'allow_no_indices'        => 'boolean',
            'analyze_wildcard'        => 'boolean',
            'analyzer'                => 'string',
            'conflicts'               => 'string',
            'default_operator'        => 'string',
            'df'                      => 'string',
            'expand_wildcards'        => 'list',
            'from'                    => 'number',
            'ignore_unavailable'      => 'boolean',
            'lenient'                 => 'boolean',
            'max_docs'                => 'number',
            'preference'              => 'string',
            'q'                       => 'string',
            'refresh'                 => 'boolean|string',
            'request_cache'           => 'boolean',
            'requests_per_second'     => 'number',
            'routing'                 => 'list',
            'scroll'                  => 'string',
            'scroll_size'             => 'number',
            'search_timeout'          => 'string',
            'search_type'             => 'string',
            'size'                    => 'number',
            'slices'                  => 'number|string',
            'sort'                    => 'list',
            'stats'                   => 'list',
            'terminate_after'         => 'number',
            'timeout'                 => 'string',
            'version'                 => 'boolean',
            'wait_for_active_shards'  => 'string',
            'wait_for_completion'     => 'boolean',
             # Common API query parameters
            'error_trace'             => 'boolean',
            'filter_path'             => 'list',
            'human'                   => 'boolean',
            'pretty'                  => 'boolean',
            'source'                  => 'string',
        },
    },

    '_core.delete_by_query_rethrottle' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/',
        method  => 'POST',
        parts   => { task_id => {  required => 1 }},
        paths   => [[ { task_id => 1 }, "_delete_by_query", "{task_id}", "_rethrottle" ]],
        qs      => {
             # Endpoint specific query parameters
            'requests_per_second'  => 'number',
             # Common API query parameters
            'error_trace'          => 'boolean',
            'filter_path'          => 'list',
            'human'                => 'boolean',
            'pretty'               => 'boolean',
            'source'               => 'string',
        },
    },

    '_core.delete_pit' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/search-plugins/point-in-time-api/#delete-pits',
        method  => 'DELETE',
        parts   => {},
        paths   => [[ {}, "_search", "point_in_time" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    '_core.delete_script' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/script-apis/delete-script/',
        method  => 'DELETE',
        parts   => { id => {  required => 1 }},
        paths   => [[ { id => 1 }, "_scripts", "{id}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    '_core.exists' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/document-apis/get-documents/',
        method  => 'HEAD',
        parts   => { id => {  required => 1 }, index => {  required => 1 }},
        paths   => [[ { index => 0, id => 2 }, "{index}", "_doc", "{id}" ]],
        qs      => {
             # Endpoint specific query parameters
            '_source'           => 'list',
            '_source_excludes'  => 'list',
            '_source_includes'  => 'list',
            'preference'        => 'string',
            'realtime'          => 'boolean',
            'refresh'           => 'boolean|string',
            'routing'           => 'list',
            'stored_fields'     => 'list',
            'version'           => 'number',
            'version_type'      => 'string',
             # Common API query parameters
            'error_trace'       => 'boolean',
            'filter_path'       => 'list',
            'human'             => 'boolean',
            'pretty'            => 'boolean',
            'source'            => 'string',
        },
    },

    '_core.exists_source' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/document-apis/get-documents/',
        method  => 'HEAD',
        parts   => { id => {  required => 1 }, index => {  required => 1 }},
        paths   => [[ { index => 0, id => 2 }, "{index}", "_source", "{id}" ]],
        qs      => {
             # Endpoint specific query parameters
            '_source'           => 'list',
            '_source_excludes'  => 'list',
            '_source_includes'  => 'list',
            'preference'        => 'string',
            'realtime'          => 'boolean',
            'refresh'           => 'boolean|string',
            'routing'           => 'list',
            'version'           => 'number',
            'version_type'      => 'string',
             # Common API query parameters
            'error_trace'       => 'boolean',
            'filter_path'       => 'list',
            'human'             => 'boolean',
            'pretty'            => 'boolean',
            'source'            => 'string',
        },
    },

    '_core.explain' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/explain/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => { id => {  required => 1 }, index => {  required => 1 }},
        paths   => [[ { index => 0, id => 2 }, "{index}", "_explain", "{id}" ]],
        qs      => {
             # Endpoint specific query parameters
            '_source'           => 'list',
            '_source_excludes'  => 'list',
            '_source_includes'  => 'list',
            'analyze_wildcard'  => 'boolean',
            'analyzer'          => 'string',
            'default_operator'  => 'string',
            'df'                => 'string',
            'lenient'           => 'boolean',
            'preference'        => 'string',
            'q'                 => 'string',
            'routing'           => 'list',
            'stored_fields'     => 'list',
             # Common API query parameters
            'error_trace'       => 'boolean',
            'filter_path'       => 'list',
            'human'             => 'boolean',
            'pretty'            => 'boolean',
            'source'            => 'string',
        },
    },

    '_core.field_caps' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/field-types/supported-field-types/alias/#using-aliases-in-field-capabilities-api-operations',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 0 }, "{index}", "_field_caps" ],
            [ {}, "_field_caps" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'    => 'boolean',
            'expand_wildcards'    => 'list',
            'fields'              => 'list',
            'ignore_unavailable'  => 'boolean',
            'include_unmapped'    => 'boolean',
             # Common API query parameters
            'error_trace'         => 'boolean',
            'filter_path'         => 'list',
            'human'               => 'boolean',
            'pretty'              => 'boolean',
            'source'              => 'string',
        },
    },

    '_core.get' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/document-apis/get-documents/',
        method  => 'GET',
        parts   => { id => {  required => 1 }, index => {  required => 1 }},
        paths   => [[ { index => 0, id => 2 }, "{index}", "_doc", "{id}" ]],
        qs      => {
             # Endpoint specific query parameters
            '_source'           => 'list',
            '_source_excludes'  => 'list',
            '_source_includes'  => 'list',
            'preference'        => 'string',
            'realtime'          => 'boolean',
            'refresh'           => 'boolean|string',
            'routing'           => 'list',
            'stored_fields'     => 'list',
            'version'           => 'number',
            'version_type'      => 'string',
             # Common API query parameters
            'error_trace'       => 'boolean',
            'filter_path'       => 'list',
            'human'             => 'boolean',
            'pretty'            => 'boolean',
            'source'            => 'string',
        },
    },

    '_core.get_all_pits' => {
        doc     => 'https://opensearch.org/docs/latest/search-plugins/point-in-time-api/#list-all-pits',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_search", "point_in_time", "_all" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    '_core.get_script' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/script-apis/get-stored-script/',
        method  => 'GET',
        parts   => { id => {  required => 1 }},
        paths   => [[ { id => 1 }, "_scripts", "{id}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'master_timeout'           => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    '_core.get_script_context' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/script-apis/get-script-contexts/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_script_context" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    '_core.get_script_languages' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/script-apis/get-script-language/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_script_language" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    '_core.get_source' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/document-apis/get-documents/',
        method  => 'GET',
        parts   => { id => {  required => 1 }, index => {  required => 1 }},
        paths   => [[ { index => 0, id => 2 }, "{index}", "_source", "{id}" ]],
        qs      => {
             # Endpoint specific query parameters
            '_source'           => 'list',
            '_source_excludes'  => 'list',
            '_source_includes'  => 'list',
            'preference'        => 'string',
            'realtime'          => 'boolean',
            'refresh'           => 'boolean|string',
            'routing'           => 'list',
            'version'           => 'number',
            'version_type'      => 'string',
             # Common API query parameters
            'error_trace'       => 'boolean',
            'filter_path'       => 'list',
            'human'             => 'boolean',
            'pretty'            => 'boolean',
            'source'            => 'string',
        },
    },

    '_core.index' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/document-apis/index-document/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'POST', alternate => 'PUT', check => { body => 0, paths => 1 } },
        parts   => { id => {}, index => {  required => 1 }},
        paths   => [
            [ { index => 0, id => 2 }, "{index}", "_doc", "{id}" ],
            [ { index => 0 }, "{index}", "_doc" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'if_primary_term'         => 'number',
            'if_seq_no'               => 'number',
            'op_type'                 => 'string',
            'pipeline'                => 'string',
            'refresh'                 => 'boolean|string',
            'require_alias'           => 'boolean',
            'routing'                 => 'list',
            'timeout'                 => 'string',
            'version'                 => 'number',
            'version_type'            => 'string',
            'wait_for_active_shards'  => 'string',
             # Common API query parameters
            'error_trace'             => 'boolean',
            'filter_path'             => 'list',
            'human'                   => 'boolean',
            'pretty'                  => 'boolean',
            'source'                  => 'string',
        },
    },

    '_core.info' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "" ]],
        qs      => {},
    },

    '_core.mget' => {
        body    => { required => 1 },
        doc     => 'https://opensearch.org/docs/latest/api-reference/document-apis/multi-get/',
        method  => 'POST',
        parts   => { index => {}},
        paths   => [
            [ { index => 0 }, "{index}", "_mget" ],
            [ {}, "_mget" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            '_source'           => 'list',
            '_source_excludes'  => 'list',
            '_source_includes'  => 'list',
            'preference'        => 'string',
            'realtime'          => 'boolean',
            'refresh'           => 'boolean|string',
            'routing'           => 'list',
            'stored_fields'     => 'list',
             # Common API query parameters
            'error_trace'       => 'boolean',
            'filter_path'       => 'list',
            'human'             => 'boolean',
            'pretty'            => 'boolean',
            'source'            => 'string',
        },
    },

    '_core.msearch' => {
        body    => { required => 1 },
        doc     => 'https://opensearch.org/docs/latest/api-reference/multi-search/',
        method  => 'POST',
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 0 }, "{index}", "_msearch" ],
            [ {}, "_msearch" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'allow_partial_results'          => 'boolean',
            'ccs_minimize_roundtrips'        => 'boolean',
            'max_concurrent_searches'        => 'number',
            'max_concurrent_shard_requests'  => 'number',
            'pre_filter_shard_size'          => 'number',
            'rest_total_hits_as_int'         => 'boolean',
            'search_type'                    => 'string',
            'typed_keys'                     => 'boolean',
             # Common API query parameters
            'error_trace'                    => 'boolean',
            'filter_path'                    => 'list',
            'human'                          => 'boolean',
            'pretty'                         => 'boolean',
            'source'                         => 'string',
        },
        serialize => 'bulk',
    },

    '_core.msearch_template' => {
        body    => { required => 1 },
        doc     => 'https://opensearch.org/docs/latest/search-plugins/search-template/',
        method  => 'POST',
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 0 }, "{index}", "_msearch", "template" ],
            [ {}, "_msearch", "template" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'ccs_minimize_roundtrips'  => 'boolean',
            'max_concurrent_searches'  => 'number',
            'rest_total_hits_as_int'   => 'boolean',
            'search_type'              => 'string',
            'typed_keys'               => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
        serialize => 'bulk',
    },

    '_core.mtermvectors' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/api-reference/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => { index => {}},
        paths   => [
            [ { index => 0 }, "{index}", "_mtermvectors" ],
            [ {}, "_mtermvectors" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'field_statistics'  => 'boolean',
            'fields'            => 'list',
            'ids'               => 'list',
            'offsets'           => 'boolean',
            'payloads'          => 'boolean',
            'positions'         => 'boolean',
            'preference'        => 'string',
            'realtime'          => 'boolean',
            'routing'           => 'list',
            'term_statistics'   => 'boolean',
            'version'           => 'number',
            'version_type'      => 'string',
             # Common API query parameters
            'error_trace'       => 'boolean',
            'filter_path'       => 'list',
            'human'             => 'boolean',
            'pretty'            => 'boolean',
            'source'            => 'string',
        },
    },

    '_core.ping' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/',
        method  => 'HEAD',
        parts   => {},
        paths   => [[ {}, "" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    '_core.put_script' => {
        body    => { required => 1 },
        doc     => 'https://opensearch.org/docs/latest/api-reference/script-apis/create-stored-script/',
        method  => 'PUT',
        parts   => { context => {}, id => {  required => 1 }},
        paths   => [
            [ { id => 1, context => 2 }, "_scripts", "{id}", "{context}" ],
            [ { id => 1 }, "_scripts", "{id}" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'context'                  => 'string',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    '_core.rank_eval' => {
        body    => { required => 1 },
        doc     => 'https://opensearch.org/docs/latest/api-reference/rank-eval/',
        method  => 'POST',
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 0 }, "{index}", "_rank_eval" ],
            [ {}, "_rank_eval" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'    => 'boolean',
            'expand_wildcards'    => 'list',
            'ignore_unavailable'  => 'boolean',
            'search_type'         => 'string',
             # Common API query parameters
            'error_trace'         => 'boolean',
            'filter_path'         => 'list',
            'human'               => 'boolean',
            'pretty'              => 'boolean',
            'source'              => 'string',
        },
    },

    '_core.reindex' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/im-plugin/reindex-data/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_reindex" ]],
        qs      => {
             # Endpoint specific query parameters
            'max_docs'                => 'number',
            'refresh'                 => 'boolean|string',
            'requests_per_second'     => 'number',
            'require_alias'           => 'boolean',
            'scroll'                  => 'string',
            'slices'                  => 'number|string',
            'timeout'                 => 'string',
            'wait_for_active_shards'  => 'string',
            'wait_for_completion'     => 'boolean',
             # Common API query parameters
            'error_trace'             => 'boolean',
            'filter_path'             => 'list',
            'human'                   => 'boolean',
            'pretty'                  => 'boolean',
            'source'                  => 'string',
        },
    },

    '_core.reindex_rethrottle' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/',
        method  => 'POST',
        parts   => { task_id => {  required => 1 }},
        paths   => [[ { task_id => 1 }, "_reindex", "{task_id}", "_rethrottle" ]],
        qs      => {
             # Endpoint specific query parameters
            'requests_per_second'  => 'number',
             # Common API query parameters
            'error_trace'          => 'boolean',
            'filter_path'          => 'list',
            'human'                => 'boolean',
            'pretty'               => 'boolean',
            'source'               => 'string',
        },
    },

    '_core.render_search_template' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/search-plugins/search-template/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => { id => {}},
        paths   => [
            [ { id => 2 }, "_render", "template", "{id}" ],
            [ {}, "_render", "template" ]
        ],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    '_core.scripts_painless_execute' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/script-apis/exec-script/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => {},
        paths   => [[ {}, "_scripts", "painless", "_execute" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    '_core.scroll' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/scroll/#path-and-http-methods',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => { scroll_id => {}},
        paths   => [
            [ { scroll_id => 2 }, "_search", "scroll", "{scroll_id}" ],
            [ {}, "_search", "scroll" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'rest_total_hits_as_int'  => 'boolean',
            'scroll'                  => 'string',
            'scroll_id'               => 'string',
             # Common API query parameters
            'error_trace'             => 'boolean',
            'filter_path'             => 'list',
            'human'                   => 'boolean',
            'pretty'                  => 'boolean',
            'source'                  => 'string',
        },
    },

    '_core.search' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/search/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 0 }, "{index}", "_search" ],
            [ {}, "_search" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            '_source'                        => 'list',
            '_source_excludes'               => 'list',
            '_source_includes'               => 'list',
            'allow_no_indices'               => 'boolean',
            'allow_partial_search_results'   => 'boolean',
            'analyze_wildcard'               => 'boolean',
            'analyzer'                       => 'string',
            'batched_reduce_size'            => 'number',
            'cancel_after_time_interval'     => 'string',
            'ccs_minimize_roundtrips'        => 'boolean',
            'default_operator'               => 'string',
            'df'                             => 'string',
            'docvalue_fields'                => 'list',
            'expand_wildcards'               => 'list',
            'explain'                        => 'boolean',
            'from'                           => 'number',
            'ignore_throttled'               => 'boolean',
            'ignore_unavailable'             => 'boolean',
            'include_named_queries_score'    => 'boolean',
            'index'                          => 'list',
            'lenient'                        => 'boolean',
            'max_concurrent_shard_requests'  => 'number',
            'phase_took'                     => 'boolean',
            'pre_filter_shard_size'          => 'number',
            'preference'                     => 'string',
            'q'                              => 'string',
            'request_cache'                  => 'boolean',
            'rest_total_hits_as_int'         => 'boolean',
            'routing'                        => 'list',
            'scroll'                         => 'string',
            'search_pipeline'                => 'string',
            'search_type'                    => 'string',
            'seq_no_primary_term'            => 'boolean',
            'size'                           => 'number',
            'sort'                           => 'list',
            'stats'                          => 'list',
            'stored_fields'                  => 'list',
            'suggest_field'                  => 'string',
            'suggest_mode'                   => 'string',
            'suggest_size'                   => 'number',
            'suggest_text'                   => 'string',
            'terminate_after'                => 'number',
            'timeout'                        => 'string',
            'track_scores'                   => 'boolean',
            'track_total_hits'               => 'boolean|number',
            'typed_keys'                     => 'boolean',
            'verbose_pipeline'               => 'boolean',
            'version'                        => 'boolean',
             # Common API query parameters
            'error_trace'                    => 'boolean',
            'filter_path'                    => 'list',
            'human'                          => 'boolean',
            'pretty'                         => 'boolean',
            'source'                         => 'string',
        },
    },

    '_core.search_shards' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/api-reference/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 0 }, "{index}", "_search_shards" ],
            [ {}, "_search_shards" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'    => 'boolean',
            'expand_wildcards'    => 'list',
            'ignore_unavailable'  => 'boolean',
            'local'               => 'boolean',
            'preference'          => 'string',
            'routing'             => 'list',
             # Common API query parameters
            'error_trace'         => 'boolean',
            'filter_path'         => 'list',
            'human'               => 'boolean',
            'pretty'              => 'boolean',
            'source'              => 'string',
        },
    },

    '_core.search_template' => {
        body    => { required => 1 },
        doc     => 'https://opensearch.org/docs/latest/search-plugins/search-template/',
        method  => 'POST',
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 0 }, "{index}", "_search", "template" ],
            [ {}, "_search", "template" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'         => 'boolean',
            'ccs_minimize_roundtrips'  => 'boolean',
            'expand_wildcards'         => 'list',
            'explain'                  => 'boolean',
            'ignore_throttled'         => 'boolean',
            'ignore_unavailable'       => 'boolean',
            'phase_took'               => 'boolean',
            'preference'               => 'string',
            'profile'                  => 'boolean',
            'rest_total_hits_as_int'   => 'boolean',
            'routing'                  => 'list',
            'scroll'                   => 'string',
            'search_pipeline'          => 'string',
            'search_type'              => 'string',
            'typed_keys'               => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    '_core.termvectors' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/api-reference/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => { id => {}, index => {  required => 1 }},
        paths   => [
            [ { index => 0, id => 2 }, "{index}", "_termvectors", "{id}" ],
            [ { index => 0 }, "{index}", "_termvectors" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'field_statistics'  => 'boolean',
            'fields'            => 'list',
            'offsets'           => 'boolean',
            'payloads'          => 'boolean',
            'positions'         => 'boolean',
            'preference'        => 'string',
            'realtime'          => 'boolean',
            'routing'           => 'list',
            'term_statistics'   => 'boolean',
            'version'           => 'number',
            'version_type'      => 'string',
             # Common API query parameters
            'error_trace'       => 'boolean',
            'filter_path'       => 'list',
            'human'             => 'boolean',
            'pretty'            => 'boolean',
            'source'            => 'string',
        },
    },

    '_core.update' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/document-apis/update-document/',
        method  => 'POST',
        parts   => { id => {  required => 1 }, index => {  required => 1 }},
        paths   => [[ { index => 0, id => 2 }, "{index}", "_update", "{id}" ]],
        qs      => {
             # Endpoint specific query parameters
            '_source'                 => 'list',
            '_source_excludes'        => 'list',
            '_source_includes'        => 'list',
            'if_primary_term'         => 'number',
            'if_seq_no'               => 'number',
            'lang'                    => 'string',
            'refresh'                 => 'boolean|string',
            'require_alias'           => 'boolean',
            'retry_on_conflict'       => 'number',
            'routing'                 => 'list',
            'timeout'                 => 'string',
            'wait_for_active_shards'  => 'string',
             # Common API query parameters
            'error_trace'             => 'boolean',
            'filter_path'             => 'list',
            'human'                   => 'boolean',
            'pretty'                  => 'boolean',
            'source'                  => 'string',
        },
    },

    '_core.update_by_query' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/document-apis/update-by-query/',
        method  => 'POST',
        parts   => { index => {  multi => 1,  required => 1 }},
        paths   => [[ { index => 0 }, "{index}", "_update_by_query" ]],
        qs      => {
             # Endpoint specific query parameters
            '_source'                 => 'list',
            '_source_excludes'        => 'list',
            '_source_includes'        => 'list',
            'allow_no_indices'        => 'boolean',
            'analyze_wildcard'        => 'boolean',
            'analyzer'                => 'string',
            'conflicts'               => 'string',
            'default_operator'        => 'string',
            'df'                      => 'string',
            'expand_wildcards'        => 'list',
            'from'                    => 'number',
            'ignore_unavailable'      => 'boolean',
            'lenient'                 => 'boolean',
            'max_docs'                => 'number',
            'pipeline'                => 'string',
            'preference'              => 'string',
            'q'                       => 'string',
            'refresh'                 => 'boolean|string',
            'request_cache'           => 'boolean',
            'requests_per_second'     => 'number',
            'routing'                 => 'list',
            'scroll'                  => 'string',
            'scroll_size'             => 'number',
            'search_timeout'          => 'string',
            'search_type'             => 'string',
            'size'                    => 'number',
            'slices'                  => 'number|string',
            'sort'                    => 'list',
            'stats'                   => 'list',
            'terminate_after'         => 'number',
            'timeout'                 => 'string',
            'version'                 => 'boolean',
            'wait_for_active_shards'  => 'string',
            'wait_for_completion'     => 'boolean',
             # Common API query parameters
            'error_trace'             => 'boolean',
            'filter_path'             => 'list',
            'human'                   => 'boolean',
            'pretty'                  => 'boolean',
            'source'                  => 'string',
        },
    },

    '_core.update_by_query_rethrottle' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/',
        method  => 'POST',
        parts   => { task_id => {  required => 1 }},
        paths   => [[ { task_id => 1 }, "_update_by_query", "{task_id}", "_rethrottle" ]],
        qs      => {
             # Endpoint specific query parameters
            'requests_per_second'  => 'number',
             # Common API query parameters
            'error_trace'          => 'boolean',
            'filter_path'          => 'list',
            'human'                => 'boolean',
            'pretty'               => 'boolean',
            'source'               => 'string',
        },
    },

    'asynchronous_search.delete' => {
        doc     => 'https://opensearch.org/docs/latest/search-plugins/async/index/#delete-searches-and-results',
        method  => 'DELETE',
        parts   => { id => {  required => 1 }},
        paths   => [[ { id => 2 }, "_plugins", "_asynchronous_search", "{id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'asynchronous_search.get' => {
        doc     => 'https://opensearch.org/docs/latest/search-plugins/async/index/#get-partial-results',
        method  => 'GET',
        parts   => { id => {  required => 1 }},
        paths   => [[ { id => 2 }, "_plugins", "_asynchronous_search", "{id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'asynchronous_search.search' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/search-plugins/async/index/#rest-api',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_asynchronous_search" ]],
        qs      => {
             # Endpoint specific query parameters
            'index'                        => 'string',
            'keep_alive'                   => 'string',
            'keep_on_completion'           => 'boolean',
            'wait_for_completion_timeout'  => 'string',
             # Common API query parameters
            'error_trace'                  => 'boolean',
            'filter_path'                  => 'list',
            'human'                        => 'boolean',
            'pretty'                       => 'boolean',
            'source'                       => 'string',
        },
    },

    'asynchronous_search.stats' => {
        doc     => 'https://opensearch.org/docs/latest/search-plugins/async/index/#monitor-stats',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_asynchronous_search", "stats" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'cat.aliases' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cat/cat-aliases/',
        method  => 'GET',
        parts   => { name => {  multi => 1 }},
        paths   => [
            [ { name => 2 }, "_cat", "aliases", "{name}" ],
            [ {}, "_cat", "aliases" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'expand_wildcards'  => 'list',
            'format'            => 'string',
            'h'                 => 'list',
            'help'              => 'boolean',
            'local'             => 'boolean',
            's'                 => 'list',
            'v'                 => 'boolean',
             # Common API query parameters
            'error_trace'       => 'boolean',
            'filter_path'       => 'list',
            'human'             => 'boolean',
            'pretty'            => 'boolean',
            'source'            => 'string',
        },
    },

    'cat.all_pit_segments' => {
        doc     => 'https://opensearch.org/docs/latest/search-plugins/point-in-time-api/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_cat", "pit_segments", "_all" ]],
        qs      => {
             # Endpoint specific query parameters
            'bytes'        => 'string',
            'format'       => 'string',
            'h'            => 'list',
            'help'         => 'boolean',
            's'            => 'list',
            'v'            => 'boolean',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'cat.allocation' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cat/cat-allocation/',
        method  => 'GET',
        parts   => { node_id => {  multi => 1 }},
        paths   => [
            [ { node_id => 2 }, "_cat", "allocation", "{node_id}" ],
            [ {}, "_cat", "allocation" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'bytes'                    => 'string',
            'cluster_manager_timeout'  => 'string',
            'format'                   => 'string',
            'h'                        => 'list',
            'help'                     => 'boolean',
            'local'                    => 'boolean',
            'master_timeout'           => 'string',
            's'                        => 'list',
            'v'                        => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'cat.cluster_manager' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cat/cat-cluster_manager/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_cat", "cluster_manager" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'format'                   => 'string',
            'h'                        => 'list',
            'help'                     => 'boolean',
            'local'                    => 'boolean',
            'master_timeout'           => 'string',
            's'                        => 'list',
            'v'                        => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'cat.count' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cat/cat-count/',
        method  => 'GET',
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 2 }, "_cat", "count", "{index}" ],
            [ {}, "_cat", "count" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'format'       => 'string',
            'h'            => 'list',
            'help'         => 'boolean',
            's'            => 'list',
            'v'            => 'boolean',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'cat.fielddata' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cat/cat-field-data/',
        method  => 'GET',
        parts   => { fields => {  multi => 1 }},
        paths   => [
            [ { fields => 2 }, "_cat", "fielddata", "{fields}" ],
            [ {}, "_cat", "fielddata" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'bytes'        => 'string',
            'fields'       => 'list',
            'format'       => 'string',
            'h'            => 'list',
            'help'         => 'boolean',
            's'            => 'list',
            'v'            => 'boolean',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'cat.health' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cat/cat-health/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_cat", "health" ]],
        qs      => {
             # Endpoint specific query parameters
            'format'       => 'string',
            'h'            => 'list',
            'help'         => 'boolean',
            's'            => 'list',
            'time'         => 'string',
            'ts'           => 'boolean',
            'v'            => 'boolean',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'cat.help' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cat/index/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_cat" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'cat.indices' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cat/cat-indices/',
        method  => 'GET',
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 2 }, "_cat", "indices", "{index}" ],
            [ {}, "_cat", "indices" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'bytes'                      => 'string',
            'cluster_manager_timeout'    => 'string',
            'expand_wildcards'           => 'list',
            'format'                     => 'string',
            'h'                          => 'list',
            'health'                     => 'string',
            'help'                       => 'boolean',
            'include_unloaded_segments'  => 'boolean',
            'local'                      => 'boolean',
            'master_timeout'             => 'string',
            'pri'                        => 'boolean',
            's'                          => 'list',
            'time'                       => 'string',
            'v'                          => 'boolean',
             # Common API query parameters
            'error_trace'                => 'boolean',
            'filter_path'                => 'list',
            'human'                      => 'boolean',
            'pretty'                     => 'boolean',
            'source'                     => 'string',
        },
    },

    'cat.master' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cat/cat-cluster_manager/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_cat", "master" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'format'                   => 'string',
            'h'                        => 'list',
            'help'                     => 'boolean',
            'local'                    => 'boolean',
            'master_timeout'           => 'string',
            's'                        => 'list',
            'v'                        => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'cat.nodeattrs' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cat/cat-nodeattrs/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_cat", "nodeattrs" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'format'                   => 'string',
            'h'                        => 'list',
            'help'                     => 'boolean',
            'local'                    => 'boolean',
            'master_timeout'           => 'string',
            's'                        => 'list',
            'v'                        => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'cat.nodes' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cat/cat-nodes/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_cat", "nodes" ]],
        qs      => {
             # Endpoint specific query parameters
            'bytes'                    => 'string',
            'cluster_manager_timeout'  => 'string',
            'format'                   => 'string',
            'full_id'                  => 'boolean',
            'h'                        => 'list',
            'help'                     => 'boolean',
            'local'                    => 'boolean',
            'master_timeout'           => 'string',
            's'                        => 'list',
            'time'                     => 'string',
            'v'                        => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'cat.pending_tasks' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cat/cat-pending-tasks/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_cat", "pending_tasks" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'format'                   => 'string',
            'h'                        => 'list',
            'help'                     => 'boolean',
            'local'                    => 'boolean',
            'master_timeout'           => 'string',
            's'                        => 'list',
            'time'                     => 'string',
            'v'                        => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'cat.pit_segments' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/search-plugins/point-in-time-api/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_cat", "pit_segments" ]],
        qs      => {
             # Endpoint specific query parameters
            'bytes'        => 'string',
            'format'       => 'string',
            'h'            => 'list',
            'help'         => 'boolean',
            's'            => 'list',
            'v'            => 'boolean',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'cat.plugins' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cat/cat-plugins/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_cat", "plugins" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'format'                   => 'string',
            'h'                        => 'list',
            'help'                     => 'boolean',
            'local'                    => 'boolean',
            'master_timeout'           => 'string',
            's'                        => 'list',
            'v'                        => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'cat.recovery' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cat/cat-plugins/',
        method  => 'GET',
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 2 }, "_cat", "recovery", "{index}" ],
            [ {}, "_cat", "recovery" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'active_only'  => 'boolean',
            'bytes'        => 'string',
            'detailed'     => 'boolean',
            'format'       => 'string',
            'h'            => 'list',
            'help'         => 'boolean',
            'index'        => 'list',
            's'            => 'list',
            'time'         => 'string',
            'v'            => 'boolean',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'cat.repositories' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cat/cat-repositories/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_cat", "repositories" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'format'                   => 'string',
            'h'                        => 'list',
            'help'                     => 'boolean',
            'local'                    => 'boolean',
            'master_timeout'           => 'string',
            's'                        => 'list',
            'v'                        => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'cat.segment_replication' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cat/cat-segment-replication/',
        method  => 'GET',
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 2 }, "_cat", "segment_replication", "{index}" ],
            [ {}, "_cat", "segment_replication" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'active_only'         => 'boolean',
            'allow_no_indices'    => 'boolean',
            'bytes'               => 'string',
            'completed_only'      => 'boolean',
            'detailed'            => 'boolean',
            'expand_wildcards'    => 'list',
            'format'              => 'string',
            'h'                   => 'list',
            'help'                => 'boolean',
            'ignore_throttled'    => 'boolean',
            'ignore_unavailable'  => 'boolean',
            'index'               => 'list',
            's'                   => 'list',
            'shards'              => 'list',
            'time'                => 'string',
            'timeout'             => 'string',
            'v'                   => 'boolean',
             # Common API query parameters
            'error_trace'         => 'boolean',
            'filter_path'         => 'list',
            'human'               => 'boolean',
            'pretty'              => 'boolean',
            'source'              => 'string',
        },
    },

    'cat.segments' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cat/cat-segments/',
        method  => 'GET',
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 2 }, "_cat", "segments", "{index}" ],
            [ {}, "_cat", "segments" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'bytes'                    => 'string',
            'cluster_manager_timeout'  => 'string',
            'format'                   => 'string',
            'h'                        => 'list',
            'help'                     => 'boolean',
            'master_timeout'           => 'string',
            's'                        => 'list',
            'v'                        => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'cat.shards' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cat/cat-shards/',
        method  => 'GET',
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 2 }, "_cat", "shards", "{index}" ],
            [ {}, "_cat", "shards" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'bytes'                    => 'string',
            'cluster_manager_timeout'  => 'string',
            'format'                   => 'string',
            'h'                        => 'list',
            'help'                     => 'boolean',
            'local'                    => 'boolean',
            'master_timeout'           => 'string',
            's'                        => 'list',
            'time'                     => 'string',
            'v'                        => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'cat.snapshots' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cat/cat-snapshots/',
        method  => 'GET',
        parts   => { repository => {  multi => 1 }},
        paths   => [
            [ { repository => 2 }, "_cat", "snapshots", "{repository}" ],
            [ {}, "_cat", "snapshots" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'format'                   => 'string',
            'h'                        => 'list',
            'help'                     => 'boolean',
            'ignore_unavailable'       => 'boolean',
            'master_timeout'           => 'string',
            'repository'               => 'list',
            's'                        => 'list',
            'time'                     => 'string',
            'v'                        => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'cat.tasks' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cat/cat-tasks/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_cat", "tasks" ]],
        qs      => {
             # Endpoint specific query parameters
            'actions'         => 'list',
            'detailed'        => 'boolean',
            'format'          => 'string',
            'h'               => 'list',
            'help'            => 'boolean',
            'nodes'           => 'list',
            'parent_task_id'  => 'string',
            's'               => 'list',
            'time'            => 'string',
            'v'               => 'boolean',
             # Common API query parameters
            'error_trace'     => 'boolean',
            'filter_path'     => 'list',
            'human'           => 'boolean',
            'pretty'          => 'boolean',
            'source'          => 'string',
        },
    },

    'cat.templates' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cat/cat-templates/',
        method  => 'GET',
        parts   => { name => {}},
        paths   => [
            [ { name => 2 }, "_cat", "templates", "{name}" ],
            [ {}, "_cat", "templates" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'format'                   => 'string',
            'h'                        => 'list',
            'help'                     => 'boolean',
            'local'                    => 'boolean',
            'master_timeout'           => 'string',
            's'                        => 'list',
            'v'                        => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'cat.thread_pool' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cat/cat-thread-pool/',
        method  => 'GET',
        parts   => { thread_pool_patterns => {  multi => 1 }},
        paths   => [
            [ { thread_pool_patterns => 2 }, "_cat", "thread_pool", "{thread_pool_patterns}" ],
            [ {}, "_cat", "thread_pool" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'format'                   => 'string',
            'h'                        => 'list',
            'help'                     => 'boolean',
            'local'                    => 'boolean',
            'master_timeout'           => 'string',
            's'                        => 'list',
            'size'                     => 'number',
            'v'                        => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'cluster.allocation_explain' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/cluster-api/cluster-allocation/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => {},
        paths   => [[ {}, "_cluster", "allocation", "explain" ]],
        qs      => {
             # Endpoint specific query parameters
            'include_disk_info'      => 'boolean',
            'include_yes_decisions'  => 'boolean',
             # Common API query parameters
            'error_trace'            => 'boolean',
            'filter_path'            => 'list',
            'human'                  => 'boolean',
            'pretty'                 => 'boolean',
            'source'                 => 'string',
        },
    },

    'cluster.delete_component_template' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/cluster-api/index/',
        method  => 'DELETE',
        parts   => { name => {  required => 1 }},
        paths   => [[ { name => 1 }, "_component_template", "{name}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'cluster.delete_decommission_awareness' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cluster-api/cluster-decommission/#example-decommissioning-and-recommissioning-a-zone',
        method  => 'DELETE',
        parts   => {},
        paths   => [[ {}, "_cluster", "decommission", "awareness" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'cluster.delete_voting_config_exclusions' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/cluster-api/index/',
        method  => 'DELETE',
        parts   => {},
        paths   => [[ {}, "_cluster", "voting_config_exclusions" ]],
        qs      => {
             # Endpoint specific query parameters
            'wait_for_removal'  => 'boolean',
             # Common API query parameters
            'error_trace'       => 'boolean',
            'filter_path'       => 'list',
            'human'             => 'boolean',
            'pretty'            => 'boolean',
            'source'            => 'string',
        },
    },

    'cluster.delete_weighted_routing' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/cluster-api/cluster-awareness/#example-deleting-weights',
        method  => 'DELETE',
        parts   => {},
        paths   => [[ {}, "_cluster", "routing", "awareness", "weights" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'cluster.exists_component_template' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/cluster-api/index/',
        method  => 'HEAD',
        parts   => { name => {  required => 1 }},
        paths   => [[ { name => 1 }, "_component_template", "{name}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'local'                    => 'boolean',
            'master_timeout'           => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'cluster.get_component_template' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/cluster-api/index/',
        method  => 'GET',
        parts   => { name => {}},
        paths   => [
            [ { name => 1 }, "_component_template", "{name}" ],
            [ {}, "_component_template" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'flat_settings'            => 'boolean',
            'local'                    => 'boolean',
            'master_timeout'           => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'cluster.get_decommission_awareness' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cluster-api/cluster-decommission/#example-getting-zone-decommission-status',
        method  => 'GET',
        parts   => { awareness_attribute_name => {  required => 1 }},
        paths   => [[ { awareness_attribute_name => 3 }, "_cluster", "decommission", "awareness", "{awareness_attribute_name}", "_status" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'cluster.get_settings' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cluster-api/cluster-settings/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_cluster", "settings" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'flat_settings'            => 'boolean',
            'include_defaults'         => 'boolean',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'cluster.get_weighted_routing' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cluster-api/cluster-awareness/#example-getting-weights-for-all-zones',
        method  => 'GET',
        parts   => { attribute => {  required => 1 }},
        paths   => [[ { attribute => 3 }, "_cluster", "routing", "awareness", "{attribute}", "weights" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'cluster.health' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cluster-api/cluster-health/',
        method  => 'GET',
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 2 }, "_cluster", "health", "{index}" ],
            [ {}, "_cluster", "health" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'awareness_attribute'              => 'string',
            'cluster_manager_timeout'          => 'string',
            'expand_wildcards'                 => 'list',
            'level'                            => 'string',
            'local'                            => 'boolean',
            'master_timeout'                   => 'string',
            'timeout'                          => 'string',
            'wait_for_active_shards'           => 'string',
            'wait_for_events'                  => 'string',
            'wait_for_no_initializing_shards'  => 'boolean',
            'wait_for_no_relocating_shards'    => 'boolean',
            'wait_for_nodes'                   => 'number|string',
            'wait_for_status'                  => 'string',
             # Common API query parameters
            'error_trace'                      => 'boolean',
            'filter_path'                      => 'list',
            'human'                            => 'boolean',
            'pretty'                           => 'boolean',
            'source'                           => 'string',
        },
    },

    'cluster.pending_tasks' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/cluster-api/index/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_cluster", "pending_tasks" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'local'                    => 'boolean',
            'master_timeout'           => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'cluster.post_voting_config_exclusions' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/cluster-api/index/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_cluster", "voting_config_exclusions" ]],
        qs      => {
             # Endpoint specific query parameters
            'node_ids'     => 'list',
            'node_names'   => 'list',
            'timeout'      => 'string',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'cluster.put_component_template' => {
        body    => { required => 1 },
        doc     => 'https://opensearch.org/docs/latest/im-plugin/index-templates/#use-component-templates-to-create-an-index-template',
        method  => 'PUT',
        parts   => { name => {  required => 1 }},
        paths   => [[ { name => 1 }, "_component_template", "{name}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'create'                   => 'boolean',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'cluster.put_decommission_awareness' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cluster-api/cluster-decommission/#example-decommissioning-and-recommissioning-a-zone',
        method  => 'PUT',
        parts   => { awareness_attribute_name => {  required => 1 }, awareness_attribute_value => {  required => 1 }},
        paths   => [[ { awareness_attribute_name => 3, awareness_attribute_value => 4 }, "_cluster", "decommission", "awareness", "{awareness_attribute_name}", "{awareness_attribute_value}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'cluster.put_settings' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/cluster-settings/',
        method  => 'PUT',
        parts   => {},
        paths   => [[ {}, "_cluster", "settings" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'flat_settings'            => 'boolean',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'cluster.put_weighted_routing' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/cluster-api/cluster-awareness/#example-weighted-round-robin-search',
        method  => 'PUT',
        parts   => { attribute => {  required => 1 }},
        paths   => [[ { attribute => 3 }, "_cluster", "routing", "awareness", "{attribute}", "weights" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'cluster.remote_info' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/remote-info/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_remote", "info" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'cluster.reroute' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/api-reference/cluster-api/index/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_cluster", "reroute" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'dry_run'                  => 'boolean',
            'explain'                  => 'boolean',
            'master_timeout'           => 'string',
            'metric'                   => 'list',
            'retry_failed'             => 'boolean',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'cluster.state' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/cluster-api/index/',
        method  => 'GET',
        parts   => { index => {  multi => 1 }, metric => {  multi => 1 }},
        paths   => [
            [ { metric => 2, index => 3 }, "_cluster", "state", "{metric}", "{index}" ],
            [ { metric => 2 }, "_cluster", "state", "{metric}" ],
            [ {}, "_cluster", "state" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'           => 'boolean',
            'cluster_manager_timeout'    => 'string',
            'expand_wildcards'           => 'list',
            'flat_settings'              => 'boolean',
            'ignore_unavailable'         => 'boolean',
            'local'                      => 'boolean',
            'master_timeout'             => 'string',
            'wait_for_metadata_version'  => 'number',
            'wait_for_timeout'           => 'string',
             # Common API query parameters
            'error_trace'                => 'boolean',
            'filter_path'                => 'list',
            'human'                      => 'boolean',
            'pretty'                     => 'boolean',
            'source'                     => 'string',
        },
    },

    'cluster.stats' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/cluster-api/cluster-stats/',
        method  => 'GET',
        parts   => { index_metric => {  multi => 1 }, metric => {  multi => 1 }, node_id => {  multi => 1 }},
        paths   => [
            [ { metric => 2, index_metric => 3, node_id => 5 }, "_cluster", "stats", "{metric}", "{index_metric}", "nodes", "{node_id}" ],
            [ { metric => 2, node_id => 4 }, "_cluster", "stats", "{metric}", "nodes", "{node_id}" ],
            [ { node_id => 3 }, "_cluster", "stats", "nodes", "{node_id}" ],
            [ {}, "_cluster", "stats" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'flat_settings'  => 'boolean',
            'timeout'        => 'string',
             # Common API query parameters
            'error_trace'    => 'boolean',
            'filter_path'    => 'list',
            'human'          => 'boolean',
            'pretty'         => 'boolean',
            'source'         => 'string',
        },
    },

    'dangling_indices.delete_dangling_index' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/index-apis/dangling-index/',
        method  => 'DELETE',
        parts   => { index_uuid => {  required => 1 }},
        paths   => [[ { index_uuid => 1 }, "_dangling", "{index_uuid}" ]],
        qs      => {
             # Endpoint specific query parameters
            'accept_data_loss'         => 'boolean',
            'cluster_manager_timeout'  => 'string',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'dangling_indices.import_dangling_index' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/index-apis/dangling-index/',
        method  => 'POST',
        parts   => { index_uuid => {  required => 1 }},
        paths   => [[ { index_uuid => 1 }, "_dangling", "{index_uuid}" ]],
        qs      => {
             # Endpoint specific query parameters
            'accept_data_loss'         => 'boolean',
            'cluster_manager_timeout'  => 'string',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'dangling_indices.list_dangling_indices' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/index-apis/dangling-index/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_dangling" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'flow_framework.create' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/automating-configurations/api/create-workflow/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_flow_framework", "workflow" ]],
        qs      => {
             # Endpoint specific query parameters
            'provision'      => 'boolean',
            'reprovision'    => 'boolean',
            'update_fields'  => 'boolean',
            'use_case'       => 'string',
            'validation'     => 'string',
             # Common API query parameters
            'error_trace'    => 'boolean',
            'filter_path'    => 'list',
            'human'          => 'boolean',
            'pretty'         => 'boolean',
            'source'         => 'string',
        },
    },

    'flow_framework.delete' => {
        doc     => 'https://opensearch.org/docs/latest/automating-configurations/api/delete-workflow/',
        method  => 'DELETE',
        parts   => { workflow_id => {  required => 1 }},
        paths   => [[ { workflow_id => 3 }, "_plugins", "_flow_framework", "workflow", "{workflow_id}" ]],
        qs      => {
             # Endpoint specific query parameters
            'clear_status'  => 'boolean',
             # Common API query parameters
            'error_trace'   => 'boolean',
            'filter_path'   => 'list',
            'human'         => 'boolean',
            'pretty'        => 'boolean',
            'source'        => 'string',
        },
    },

    'flow_framework.deprovision' => {
        doc     => 'https://opensearch.org/docs/latest/automating-configurations/api/deprovision-workflow/',
        method  => 'POST',
        parts   => { workflow_id => {  required => 1 }},
        paths   => [[ { workflow_id => 3 }, "_plugins", "_flow_framework", "workflow", "{workflow_id}", "_deprovision" ]],
        qs      => {
             # Endpoint specific query parameters
            'allow_delete'  => 'string',
             # Common API query parameters
            'error_trace'   => 'boolean',
            'filter_path'   => 'list',
            'human'         => 'boolean',
            'pretty'        => 'boolean',
            'source'        => 'string',
        },
    },

    'flow_framework.get' => {
        doc     => 'https://opensearch.org/docs/latest/automating-configurations/api/get-workflow/',
        method  => 'GET',
        parts   => { workflow_id => {  required => 1 }},
        paths   => [[ { workflow_id => 3 }, "_plugins", "_flow_framework", "workflow", "{workflow_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'flow_framework.get_status' => {
        doc     => 'https://opensearch.org/docs/latest/automating-configurations/api/get-workflow-status/',
        method  => 'GET',
        parts   => { workflow_id => {  required => 1 }},
        paths   => [[ { workflow_id => 3 }, "_plugins", "_flow_framework", "workflow", "{workflow_id}", "_status" ]],
        qs      => {
             # Endpoint specific query parameters
            'all'          => 'boolean',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'flow_framework.get_steps' => {
        doc     => 'https://opensearch.org/docs/latest/automating-configurations/api/get-workflow-steps/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_flow_framework", "workflow", "_steps" ]],
        qs      => {
             # Endpoint specific query parameters
            'workflow_step'  => 'string',
             # Common API query parameters
            'error_trace'    => 'boolean',
            'filter_path'    => 'list',
            'human'          => 'boolean',
            'pretty'         => 'boolean',
            'source'         => 'string',
        },
    },

    'flow_framework.provision' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/automating-configurations/api/provision-workflow/',
        method  => 'POST',
        parts   => { workflow_id => {  required => 1 }},
        paths   => [[ { workflow_id => 3 }, "_plugins", "_flow_framework", "workflow", "{workflow_id}", "_provision" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'flow_framework.search' => {
        body    => { required => 1 },
        doc     => 'https://opensearch.org/docs/latest/automating-configurations/api/provision-workflow/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_flow_framework", "workflow", "_search" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'flow_framework.search_state' => {
        body    => { required => 1 },
        doc     => 'https://opensearch.org/docs/latest/automating-configurations/api/search-workflow-state/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_flow_framework", "workflow", "state", "_search" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'flow_framework.update' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/automating-configurations/api/create-workflow/',
        method  => 'PUT',
        parts   => { workflow_id => {  required => 1 }},
        paths   => [[ { workflow_id => 3 }, "_plugins", "_flow_framework", "workflow", "{workflow_id}" ]],
        qs      => {
             # Endpoint specific query parameters
            'provision'      => 'boolean',
            'reprovision'    => 'boolean',
            'update_fields'  => 'boolean',
            'use_case'       => 'string',
            'validation'     => 'string',
             # Common API query parameters
            'error_trace'    => 'boolean',
            'filter_path'    => 'list',
            'human'          => 'boolean',
            'pretty'         => 'boolean',
            'source'         => 'string',
        },
    },

    'geospatial.delete_ip2geo_datasource' => {
        doc     => 'https://docs.opensearch.org/docs/latest/ingest-pipelines/processors/ip2geo/#deleting-the-ip2geo-data-source',
        method  => 'DELETE',
        parts   => { name => {  required => 1 }},
        paths   => [[ { name => 4 }, "_plugins", "geospatial", "ip2geo", "datasource", "{name}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'geospatial.geojson_upload_post' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/docs/latest/ingest-pipelines/processors/ip2geo',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "geospatial", "geojson", "_upload" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'geospatial.geojson_upload_put' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/docs/latest/ingest-pipelines/processors/ip2geo',
        method  => 'PUT',
        parts   => {},
        paths   => [[ {}, "_plugins", "geospatial", "geojson", "_upload" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'geospatial.get_ip2geo_datasource' => {
        doc     => 'https://docs.opensearch.org/docs/latest/ingest-pipelines/processors/ip2geo/#sending-a-get-request',
        method  => 'GET',
        parts   => { name => {  multi => 1 }},
        paths   => [
            [ { name => 4 }, "_plugins", "geospatial", "ip2geo", "datasource", "{name}" ],
            [ {}, "_plugins", "geospatial", "ip2geo", "datasource" ]
        ],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'geospatial.get_upload_stats' => {
        doc     => 'https://docs.opensearch.org/docs/latest/ingest-pipelines/processors/ip2geo',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "geospatial", "_upload", "stats" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'geospatial.put_ip2geo_datasource' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/docs/latest/ingest-pipelines/processors/ip2geo/#data-source-options',
        method  => 'PUT',
        parts   => { name => {  required => 1 }},
        paths   => [[ { name => 4 }, "_plugins", "geospatial", "ip2geo", "datasource", "{name}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'geospatial.put_ip2geo_datasource_settings' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/docs/latest/ingest-pipelines/processors/ip2geo/#updating-an-ip2geo-data-source',
        method  => 'PUT',
        parts   => { name => {  required => 1 }},
        paths   => [[ { name => 4 }, "_plugins", "geospatial", "ip2geo", "datasource", "{name}", "_settings" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'indices.add_block' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/index-apis/index/',
        method  => 'PUT',
        parts   => { block => {  required => 1 }, index => {  multi => 1,  required => 1 }},
        paths   => [[ { index => 0, block => 2 }, "{index}", "_block", "{block}" ]],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'         => 'boolean',
            'cluster_manager_timeout'  => 'string',
            'expand_wildcards'         => 'list',
            'ignore_unavailable'       => 'boolean',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.analyze' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/analyze-apis/perform-text-analysis/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => { index => {}},
        paths   => [
            [ { index => 0 }, "{index}", "_analyze" ],
            [ {}, "_analyze" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'index'        => 'string',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'indices.clear_cache' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/index-apis/clear-index-cache/',
        method  => 'POST',
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 0 }, "{index}", "_cache", "clear" ],
            [ {}, "_cache", "clear" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'    => 'boolean',
            'expand_wildcards'    => 'list',
            'fielddata'           => 'boolean',
            'fields'              => 'list',
            'file'                => 'boolean',
            'ignore_unavailable'  => 'boolean',
            'index'               => 'list',
            'query'               => 'boolean',
            'request'             => 'boolean',
             # Common API query parameters
            'error_trace'         => 'boolean',
            'filter_path'         => 'list',
            'human'               => 'boolean',
            'pretty'              => 'boolean',
            'source'              => 'string',
        },
    },

    'indices.clone' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/index-apis/clone/',
        method  => 'POST',
        parts   => { index => {  required => 1 }, target => {  required => 1 }},
        paths   => [[ { index => 0, target => 2 }, "{index}", "_clone", "{target}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'master_timeout'           => 'string',
            'task_execution_timeout'   => 'string',
            'timeout'                  => 'string',
            'wait_for_active_shards'   => 'string',
            'wait_for_completion'      => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.close' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/index-apis/close-index/',
        method  => 'POST',
        parts   => { index => {  multi => 1,  required => 1 }},
        paths   => [[ { index => 0 }, "{index}", "_close" ]],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'         => 'boolean',
            'cluster_manager_timeout'  => 'string',
            'expand_wildcards'         => 'list',
            'ignore_unavailable'       => 'boolean',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
            'wait_for_active_shards'   => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.create' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/index-apis/create-index/',
        method  => 'PUT',
        parts   => { index => {  required => 1 }},
        paths   => [[ { index => 0 }, "{index}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
            'wait_for_active_shards'   => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.create_data_stream' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/im-plugin/data-streams/',
        method  => 'PUT',
        parts   => { name => {  required => 1 }},
        paths   => [[ { name => 1 }, "_data_stream", "{name}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'indices.data_streams_stats' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/data-streams/',
        method  => 'GET',
        parts   => { name => {  multi => 1 }},
        paths   => [
            [ { name => 1 }, "_data_stream", "{name}", "_stats" ],
            [ {}, "_data_stream", "_stats" ]
        ],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'indices.delete' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/index-apis/delete-index/',
        method  => 'DELETE',
        parts   => { index => {  multi => 1,  required => 1 }},
        paths   => [[ { index => 0 }, "{index}" ]],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'         => 'boolean',
            'cluster_manager_timeout'  => 'string',
            'expand_wildcards'         => 'list',
            'ignore_unavailable'       => 'boolean',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.delete_alias' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/index-alias/#delete-aliases',
        method  => 'DELETE',
        parts   => { index => {  multi => 1,  required => 1 }, name => {  multi => 1,  required => 1 }},
        paths   => [
            [ { index => 0, name => 2 }, "{index}", "_alias", "{name}" ],
            [ { index => 0, name => 2 }, "{index}", "_aliases", "{name}" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.delete_data_stream' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/data-streams/',
        method  => 'DELETE',
        parts   => { name => {  multi => 1,  required => 1 }},
        paths   => [[ { name => 1 }, "_data_stream", "{name}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'indices.delete_index_template' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/index-templates/#delete-a-template',
        method  => 'DELETE',
        parts   => { name => {  required => 1 }},
        paths   => [[ { name => 1 }, "_index_template", "{name}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.delete_template' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/index-apis/index/',
        method  => 'DELETE',
        parts   => { name => {  required => 1 }},
        paths   => [[ { name => 1 }, "_template", "{name}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.exists' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/index-apis/exists/',
        method  => 'HEAD',
        parts   => { index => {  multi => 1,  required => 1 }},
        paths   => [[ { index => 0 }, "{index}" ]],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'         => 'boolean',
            'cluster_manager_timeout'  => 'string',
            'expand_wildcards'         => 'list',
            'flat_settings'            => 'boolean',
            'ignore_unavailable'       => 'boolean',
            'include_defaults'         => 'boolean',
            'local'                    => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.exists_alias' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/index-apis/index/',
        method  => 'HEAD',
        parts   => { index => {  multi => 1 }, name => {  multi => 1,  required => 1 }},
        paths   => [
            [ { index => 0, name => 2 }, "{index}", "_alias", "{name}" ],
            [ { name => 1 }, "_alias", "{name}" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'    => 'boolean',
            'expand_wildcards'    => 'list',
            'ignore_unavailable'  => 'boolean',
            'local'               => 'boolean',
             # Common API query parameters
            'error_trace'         => 'boolean',
            'filter_path'         => 'list',
            'human'               => 'boolean',
            'pretty'              => 'boolean',
            'source'              => 'string',
        },
    },

    'indices.exists_index_template' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/index-templates/',
        method  => 'HEAD',
        parts   => { name => {  required => 1 }},
        paths   => [[ { name => 1 }, "_index_template", "{name}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'flat_settings'            => 'boolean',
            'local'                    => 'boolean',
            'master_timeout'           => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.exists_template' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/index-apis/index/',
        method  => 'HEAD',
        parts   => { name => {  multi => 1,  required => 1 }},
        paths   => [[ { name => 1 }, "_template", "{name}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'flat_settings'            => 'boolean',
            'local'                    => 'boolean',
            'master_timeout'           => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.flush' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/index-apis/index/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 0 }, "{index}", "_flush" ],
            [ {}, "_flush" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'    => 'boolean',
            'expand_wildcards'    => 'list',
            'force'               => 'boolean',
            'ignore_unavailable'  => 'boolean',
            'wait_if_ongoing'     => 'boolean',
             # Common API query parameters
            'error_trace'         => 'boolean',
            'filter_path'         => 'list',
            'human'               => 'boolean',
            'pretty'              => 'boolean',
            'source'              => 'string',
        },
    },

    'indices.forcemerge' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/index-apis/index/',
        method  => 'POST',
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 0 }, "{index}", "_forcemerge" ],
            [ {}, "_forcemerge" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'      => 'boolean',
            'expand_wildcards'      => 'list',
            'flush'                 => 'boolean',
            'ignore_unavailable'    => 'boolean',
            'max_num_segments'      => 'number',
            'only_expunge_deletes'  => 'boolean',
            'primary_only'          => 'boolean',
            'wait_for_completion'   => 'boolean',
             # Common API query parameters
            'error_trace'           => 'boolean',
            'filter_path'           => 'list',
            'human'                 => 'boolean',
            'pretty'                => 'boolean',
            'source'                => 'string',
        },
    },

    'indices.get' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/index-apis/get-index/',
        method  => 'GET',
        parts   => { index => {  multi => 1,  required => 1 }},
        paths   => [[ { index => 0 }, "{index}" ]],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'         => 'boolean',
            'cluster_manager_timeout'  => 'string',
            'expand_wildcards'         => 'list',
            'flat_settings'            => 'boolean',
            'ignore_unavailable'       => 'boolean',
            'include_defaults'         => 'boolean',
            'local'                    => 'boolean',
            'master_timeout'           => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.get_alias' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/index-alias/',
        method  => 'GET',
        parts   => { index => {  multi => 1 }, name => {  multi => 1 }},
        paths   => [
            [ { index => 0, name => 2 }, "{index}", "_alias", "{name}" ],
            [ { name => 1 }, "_alias", "{name}" ],
            [ { index => 0 }, "{index}", "_alias" ],
            [ {}, "_alias" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'    => 'boolean',
            'expand_wildcards'    => 'list',
            'ignore_unavailable'  => 'boolean',
            'local'               => 'boolean',
             # Common API query parameters
            'error_trace'         => 'boolean',
            'filter_path'         => 'list',
            'human'               => 'boolean',
            'pretty'              => 'boolean',
            'source'              => 'string',
        },
    },

    'indices.get_data_stream' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/data-streams/',
        method  => 'GET',
        parts   => { name => {  multi => 1 }},
        paths   => [
            [ { name => 1 }, "_data_stream", "{name}" ],
            [ {}, "_data_stream" ]
        ],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'indices.get_field_mapping' => {
        doc     => 'https://opensearch.org/docs/latest/field-types/index/',
        method  => 'GET',
        parts   => { fields => {  multi => 1,  required => 1 }, index => {  multi => 1 }},
        paths   => [
            [ { index => 0, fields => 3 }, "{index}", "_mapping", "field", "{fields}" ],
            [ { fields => 2 }, "_mapping", "field", "{fields}" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'    => 'boolean',
            'expand_wildcards'    => 'list',
            'ignore_unavailable'  => 'boolean',
            'include_defaults'    => 'boolean',
            'local'               => 'boolean',
             # Common API query parameters
            'error_trace'         => 'boolean',
            'filter_path'         => 'list',
            'human'               => 'boolean',
            'pretty'              => 'boolean',
            'source'              => 'string',
        },
    },

    'indices.get_index_template' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/index-templates/',
        method  => 'GET',
        parts   => { name => {}},
        paths   => [
            [ { name => 1 }, "_index_template", "{name}" ],
            [ {}, "_index_template" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'flat_settings'            => 'boolean',
            'local'                    => 'boolean',
            'master_timeout'           => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.get_mapping' => {
        doc     => 'https://opensearch.org/docs/latest/field-types/index/#get-a-mapping',
        method  => 'GET',
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 0 }, "{index}", "_mapping" ],
            [ {}, "_mapping" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'         => 'boolean',
            'cluster_manager_timeout'  => 'string',
            'expand_wildcards'         => 'list',
            'ignore_unavailable'       => 'boolean',
            'index'                    => 'list',
            'local'                    => 'boolean',
            'master_timeout'           => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.get_settings' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/index-apis/get-settings/',
        method  => 'GET',
        parts   => { index => {  multi => 1 }, name => {  multi => 1 }},
        paths   => [
            [ { index => 0, name => 2 }, "{index}", "_settings", "{name}" ],
            [ { name => 1 }, "_settings", "{name}" ],
            [ { index => 0 }, "{index}", "_settings" ],
            [ {}, "_settings" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'         => 'boolean',
            'cluster_manager_timeout'  => 'string',
            'expand_wildcards'         => 'list',
            'flat_settings'            => 'boolean',
            'ignore_unavailable'       => 'boolean',
            'include_defaults'         => 'boolean',
            'local'                    => 'boolean',
            'master_timeout'           => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.get_template' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/index-apis/index/',
        method  => 'GET',
        parts   => { name => {  multi => 1 }},
        paths   => [
            [ { name => 1 }, "_template", "{name}" ],
            [ {}, "_template" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'flat_settings'            => 'boolean',
            'local'                    => 'boolean',
            'master_timeout'           => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.get_upgrade' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/index-apis/index/',
        method  => 'GET',
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 0 }, "{index}", "_upgrade" ],
            [ {}, "_upgrade" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'    => 'boolean',
            'expand_wildcards'    => 'list',
            'ignore_unavailable'  => 'boolean',
             # Common API query parameters
            'error_trace'         => 'boolean',
            'filter_path'         => 'list',
            'human'               => 'boolean',
            'pretty'              => 'boolean',
            'source'              => 'string',
        },
    },

    'indices.open' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/index-apis/open-index/',
        method  => 'POST',
        parts   => { index => {  multi => 1,  required => 1 }},
        paths   => [[ { index => 0 }, "{index}", "_open" ]],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'         => 'boolean',
            'cluster_manager_timeout'  => 'string',
            'expand_wildcards'         => 'list',
            'ignore_unavailable'       => 'boolean',
            'master_timeout'           => 'string',
            'task_execution_timeout'   => 'string',
            'timeout'                  => 'string',
            'wait_for_active_shards'   => 'string',
            'wait_for_completion'      => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.put_alias' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/index-apis/update-alias/',
        method  => 'PUT',
        parts   => { index => {  multi => 1 }, name => {}},
        paths   => [
            [ { index => 0, name => 2 }, "{index}", "_alias", "{name}" ],
            [ { index => 0, name => 2 }, "{index}", "_aliases", "{name}" ],
            [ { name => 1 }, "_alias", "{name}" ],
            [ { name => 1 }, "_aliases", "{name}" ],
            [ { index => 0 }, "{index}", "_alias" ],
            [ { index => 0 }, "{index}", "_aliases" ],
            [ {}, "_alias" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.put_index_template' => {
        body    => { required => 1 },
        doc     => 'https://opensearch.org/docs/latest/im-plugin/index-templates/',
        method  => 'PUT',
        parts   => { name => {  required => 1 }},
        paths   => [[ { name => 1 }, "_index_template", "{name}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cause'                    => 'string',
            'cluster_manager_timeout'  => 'string',
            'create'                   => 'boolean',
            'master_timeout'           => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.put_mapping' => {
        body    => { required => 1 },
        doc     => 'https://opensearch.org/docs/latest/api-reference/index-apis/put-mapping/',
        method  => 'PUT',
        parts   => { index => {  multi => 1,  required => 1 }},
        paths   => [[ { index => 0 }, "{index}", "_mapping" ]],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'         => 'boolean',
            'cluster_manager_timeout'  => 'string',
            'expand_wildcards'         => 'list',
            'ignore_unavailable'       => 'boolean',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
            'write_index_only'         => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.put_settings' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/index-apis/update-settings/',
        method  => 'PUT',
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 0 }, "{index}", "_settings" ],
            [ {}, "_settings" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'         => 'boolean',
            'cluster_manager_timeout'  => 'string',
            'expand_wildcards'         => 'list',
            'flat_settings'            => 'boolean',
            'ignore_unavailable'       => 'boolean',
            'master_timeout'           => 'string',
            'preserve_existing'        => 'boolean',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.put_template' => {
        body    => { required => 1 },
        doc     => 'https://opensearch.org/docs/latest/im-plugin/index-templates/',
        method  => 'PUT',
        parts   => { name => {  required => 1 }},
        paths   => [[ { name => 1 }, "_template", "{name}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'create'                   => 'boolean',
            'master_timeout'           => 'string',
            'order'                    => 'number',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.recovery' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/index-apis/index/',
        method  => 'GET',
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 0 }, "{index}", "_recovery" ],
            [ {}, "_recovery" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'active_only'  => 'boolean',
            'detailed'     => 'boolean',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'indices.refresh' => {
        doc     => 'https://opensearch.org/docs/latest/tuning-your-cluster/availability-and-recovery/remote-store/index/#refresh-level-and-request-level-durability',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 0 }, "{index}", "_refresh" ],
            [ {}, "_refresh" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'    => 'boolean',
            'expand_wildcards'    => 'list',
            'ignore_unavailable'  => 'boolean',
             # Common API query parameters
            'error_trace'         => 'boolean',
            'filter_path'         => 'list',
            'human'               => 'boolean',
            'pretty'              => 'boolean',
            'source'              => 'string',
        },
    },

    'indices.resolve_index' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/index-apis/index/',
        method  => 'GET',
        parts   => { name => {  multi => 1,  required => 1 }},
        paths   => [[ { name => 2 }, "_resolve", "index", "{name}" ]],
        qs      => {
             # Endpoint specific query parameters
            'expand_wildcards'  => 'list',
             # Common API query parameters
            'error_trace'       => 'boolean',
            'filter_path'       => 'list',
            'human'             => 'boolean',
            'pretty'            => 'boolean',
            'source'            => 'string',
        },
    },

    'indices.rollover' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/dashboards/im-dashboards/rollover/',
        method  => 'POST',
        parts   => { alias => {  required => 1 }, new_index => {}},
        paths   => [
            [ { alias => 0, new_index => 2 }, "{alias}", "_rollover", "{new_index}" ],
            [ { alias => 0 }, "{alias}", "_rollover" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'dry_run'                  => 'boolean',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
            'wait_for_active_shards'   => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.segments' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/index-apis/index/',
        method  => 'GET',
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 0 }, "{index}", "_segments" ],
            [ {}, "_segments" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'    => 'boolean',
            'expand_wildcards'    => 'list',
            'ignore_unavailable'  => 'boolean',
            'verbose'             => 'boolean',
             # Common API query parameters
            'error_trace'         => 'boolean',
            'filter_path'         => 'list',
            'human'               => 'boolean',
            'pretty'              => 'boolean',
            'source'              => 'string',
        },
    },

    'indices.shard_stores' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/index-apis/index/',
        method  => 'GET',
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 0 }, "{index}", "_shard_stores" ],
            [ {}, "_shard_stores" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'    => 'boolean',
            'expand_wildcards'    => 'list',
            'ignore_unavailable'  => 'boolean',
            'status'              => 'list',
             # Common API query parameters
            'error_trace'         => 'boolean',
            'filter_path'         => 'list',
            'human'               => 'boolean',
            'pretty'              => 'boolean',
            'source'              => 'string',
        },
    },

    'indices.shrink' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/index-apis/shrink-index/',
        method  => 'POST',
        parts   => { index => {  required => 1 }, target => {  required => 1 }},
        paths   => [[ { index => 0, target => 2 }, "{index}", "_shrink", "{target}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'copy_settings'            => 'boolean',
            'master_timeout'           => 'string',
            'task_execution_timeout'   => 'string',
            'timeout'                  => 'string',
            'wait_for_active_shards'   => 'string',
            'wait_for_completion'      => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.simulate_index_template' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/api-reference/index-apis/index/',
        method  => 'POST',
        parts   => { name => {  required => 1 }},
        paths   => [[ { name => 2 }, "_index_template", "_simulate_index", "{name}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'master_timeout'           => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.simulate_template' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/api-reference/index-apis/index/',
        method  => 'POST',
        parts   => { name => {}},
        paths   => [
            [ { name => 2 }, "_index_template", "_simulate", "{name}" ],
            [ {}, "_index_template", "_simulate" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'cause'                    => 'string',
            'cluster_manager_timeout'  => 'string',
            'create'                   => 'boolean',
            'master_timeout'           => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.split' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/index-apis/split/',
        method  => 'POST',
        parts   => { index => {  required => 1 }, target => {  required => 1 }},
        paths   => [[ { index => 0, target => 2 }, "{index}", "_split", "{target}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'copy_settings'            => 'boolean',
            'master_timeout'           => 'string',
            'task_execution_timeout'   => 'string',
            'timeout'                  => 'string',
            'wait_for_active_shards'   => 'string',
            'wait_for_completion'      => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.stats' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/index-apis/index/',
        method  => 'GET',
        parts   => { index => {  multi => 1 }, metric => {  multi => 1 }},
        paths   => [
            [ { index => 0, metric => 2 }, "{index}", "_stats", "{metric}" ],
            [ { metric => 1 }, "_stats", "{metric}" ],
            [ { index => 0 }, "{index}", "_stats" ],
            [ {}, "_stats" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'completion_fields'           => 'list',
            'expand_wildcards'            => 'list',
            'fielddata_fields'            => 'list',
            'fields'                      => 'list',
            'forbid_closed_indices'       => 'boolean',
            'groups'                      => 'list',
            'include_segment_file_sizes'  => 'boolean',
            'include_unloaded_segments'   => 'boolean',
            'level'                       => 'string',
             # Common API query parameters
            'error_trace'                 => 'boolean',
            'filter_path'                 => 'list',
            'human'                       => 'boolean',
            'pretty'                      => 'boolean',
            'source'                      => 'string',
        },
    },

    'indices.update_aliases' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/index-apis/alias/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_aliases" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'indices.upgrade' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/index-apis/index/',
        method  => 'POST',
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 0 }, "{index}", "_upgrade" ],
            [ {}, "_upgrade" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'allow_no_indices'       => 'boolean',
            'expand_wildcards'       => 'list',
            'ignore_unavailable'     => 'boolean',
            'only_ancient_segments'  => 'boolean',
            'wait_for_completion'    => 'boolean',
             # Common API query parameters
            'error_trace'            => 'boolean',
            'filter_path'            => 'list',
            'human'                  => 'boolean',
            'pretty'                 => 'boolean',
            'source'                 => 'string',
        },
    },

    'indices.validate_query' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/api-reference/index-apis/index/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 0 }, "{index}", "_validate", "query" ],
            [ {}, "_validate", "query" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'all_shards'          => 'boolean',
            'allow_no_indices'    => 'boolean',
            'analyze_wildcard'    => 'boolean',
            'analyzer'            => 'string',
            'default_operator'    => 'string',
            'df'                  => 'string',
            'expand_wildcards'    => 'list',
            'explain'             => 'boolean',
            'ignore_unavailable'  => 'boolean',
            'lenient'             => 'boolean',
            'q'                   => 'string',
            'rewrite'             => 'boolean',
             # Common API query parameters
            'error_trace'         => 'boolean',
            'filter_path'         => 'list',
            'human'               => 'boolean',
            'pretty'              => 'boolean',
            'source'              => 'string',
        },
    },

    'ingest.delete_pipeline' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/ingest-apis/delete-ingest/',
        method  => 'DELETE',
        parts   => { id => {  required => 1 }},
        paths   => [[ { id => 2 }, "_ingest", "pipeline", "{id}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'ingest.get_pipeline' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/ingest-apis/get-ingest/',
        method  => 'GET',
        parts   => { id => {}},
        paths   => [
            [ { id => 2 }, "_ingest", "pipeline", "{id}" ],
            [ {}, "_ingest", "pipeline" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'master_timeout'           => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'ingest.processor_grok' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/ingest-apis/index/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_ingest", "processor", "grok" ]],
        qs      => {
             # Endpoint specific query parameters
            's'            => 'boolean',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ingest.put_pipeline' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ingest-pipelines/create-ingest/',
        method  => 'PUT',
        parts   => { id => {  required => 1 }},
        paths   => [[ { id => 2 }, "_ingest", "pipeline", "{id}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'ingest.simulate' => {
        body    => { required => 1 },
        doc     => 'https://opensearch.org/docs/latest/api-reference/ingest-apis/simulate-ingest/',
        method  => 'POST',
        parts   => { id => {}},
        paths   => [
            [ { id => 2 }, "_ingest", "pipeline", "{id}", "_simulate" ],
            [ {}, "_ingest", "pipeline", "_simulate" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'verbose'      => 'boolean',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ingestion.get_state' => {
        doc     => 'https://docs.opensearch.org/docs/latest/api-reference/document-apis/pull-based-ingestion-management/',
        method  => 'GET',
        parts   => { index => {  required => 1 }},
        paths   => [[ { index => 0 }, "{index}", "ingestion", "_state" ]],
        qs      => {
             # Endpoint specific query parameters
            'next_token'   => 'string',
            'size'         => 'number',
            'timeout'      => 'string',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ingestion.pause' => {
        doc     => 'https://docs.opensearch.org/docs/latest/api-reference/document-apis/pull-based-ingestion-management/',
        method  => 'POST',
        parts   => { index => {  required => 1 }},
        paths   => [[ { index => 0 }, "{index}", "ingestion", "_pause" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'ingestion.resume' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/docs/latest/api-reference/document-apis/pull-based-ingestion-management/',
        method  => 'POST',
        parts   => { index => {  required => 1 }},
        paths   => [[ { index => 0 }, "{index}", "ingestion", "_resume" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'insights.top_queries' => {
        doc     => 'https://docs.opensearch.org/latest/observing-your-data/query-insights/index/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_insights", "top_queries" ]],
        qs      => {
             # Endpoint specific query parameters
            'type'         => 'string',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ism.add_policy' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/im-plugin/ism/api/#add-policy',
        method  => 'POST',
        parts   => { index => {}},
        paths   => [
            [ { index => 3 }, "_plugins", "_ism", "add", "{index}" ],
            [ {}, "_plugins", "_ism", "add" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'index'        => 'string',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ism.change_policy' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/im-plugin/ism/api/#update-managed-index-policy',
        method  => 'POST',
        parts   => { index => {}},
        paths   => [
            [ { index => 3 }, "_plugins", "_ism", "change_policy", "{index}" ],
            [ {}, "_plugins", "_ism", "change_policy" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'index'        => 'string',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ism.delete_policy' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/ism/api/#delete-policy',
        method  => 'DELETE',
        parts   => { policy_id => {  required => 1 }},
        paths   => [[ { policy_id => 3 }, "_plugins", "_ism", "policies", "{policy_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ism.exists_policy' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/ism/api/#get-policy',
        method  => 'HEAD',
        parts   => { policy_id => {  required => 1 }},
        paths   => [[ { policy_id => 3 }, "_plugins", "_ism", "policies", "{policy_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ism.explain_policy' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/im-plugin/ism/api/#explain-index',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => { index => {}},
        paths   => [
            [ { index => 3 }, "_plugins", "_ism", "explain", "{index}" ],
            [ {}, "_plugins", "_ism", "explain" ]
        ],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ism.get_policies' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/ism/api/#get-policy',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_ism", "policies" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ism.get_policy' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/ism/api/#put-policy',
        method  => 'GET',
        parts   => { policy_id => {  required => 1 }},
        paths   => [[ { policy_id => 3 }, "_plugins", "_ism", "policies", "{policy_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ism.put_policies' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/im-plugin/ism/api/#create-policy',
        method  => 'PUT',
        parts   => {},
        paths   => [[ {}, "_plugins", "_ism", "policies" ]],
        qs      => {
             # Endpoint specific query parameters
            'if_primary_term'  => 'number',
            'if_seq_no'        => 'number',
            'policyID'         => 'string',
             # Common API query parameters
            'error_trace'      => 'boolean',
            'filter_path'      => 'list',
            'human'            => 'boolean',
            'pretty'           => 'boolean',
            'source'           => 'string',
        },
    },

    'ism.put_policy' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/im-plugin/ism/api/#create-policy',
        method  => 'PUT',
        parts   => { policy_id => {  required => 1 }},
        paths   => [[ { policy_id => 3 }, "_plugins", "_ism", "policies", "{policy_id}" ]],
        qs      => {
             # Endpoint specific query parameters
            'if_primary_term'  => 'number',
            'if_seq_no'        => 'number',
             # Common API query parameters
            'error_trace'      => 'boolean',
            'filter_path'      => 'list',
            'human'            => 'boolean',
            'pretty'           => 'boolean',
            'source'           => 'string',
        },
    },

    'ism.refresh_search_analyzers' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/refresh-analyzer/',
        method  => 'POST',
        parts   => { index => {  required => 1 }},
        paths   => [[ { index => 2 }, "_plugins", "_refresh_search_analyzers", "{index}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ism.remove_policy' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/ism/api/#remove-policy',
        method  => 'POST',
        parts   => { index => {}},
        paths   => [
            [ { index => 3 }, "_plugins", "_ism", "remove", "{index}" ],
            [ {}, "_plugins", "_ism", "remove" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'index'        => 'string',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ism.retry_index' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/im-plugin/ism/api/#retry-failed-index',
        method  => 'POST',
        parts   => { index => {}},
        paths   => [
            [ { index => 3 }, "_plugins", "_ism", "retry", "{index}" ],
            [ {}, "_plugins", "_ism", "retry" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'index'        => 'string',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'knn.delete_model' => {
        doc     => 'https://docs.opensearch.org/latest/vector-search/api/knn/#delete-a-model',
        method  => 'DELETE',
        parts   => { model_id => {  required => 1 }},
        paths   => [[ { model_id => 3 }, "_plugins", "_knn", "models", "{model_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'knn.get_model' => {
        doc     => 'https://docs.opensearch.org/latest/vector-search/api/knn/#get-a-model',
        method  => 'GET',
        parts   => { model_id => {  required => 1 }},
        paths   => [[ { model_id => 3 }, "_plugins", "_knn", "models", "{model_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'knn.search_models' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/vector-search/api/knn/#search-for-a-model',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => {},
        paths   => [[ {}, "_plugins", "_knn", "models", "_search" ]],
        qs      => {
             # Endpoint specific query parameters
            '_source'                        => 'list',
            '_source_excludes'               => 'list',
            '_source_includes'               => 'list',
            'allow_no_indices'               => 'boolean',
            'allow_partial_search_results'   => 'boolean',
            'analyze_wildcard'               => 'boolean',
            'analyzer'                       => 'string',
            'batched_reduce_size'            => 'number',
            'ccs_minimize_roundtrips'        => 'boolean',
            'default_operator'               => 'string',
            'df'                             => 'string',
            'docvalue_fields'                => 'list',
            'expand_wildcards'               => 'list',
            'explain'                        => 'boolean',
            'from'                           => 'number',
            'ignore_throttled'               => 'boolean',
            'ignore_unavailable'             => 'boolean',
            'lenient'                        => 'boolean',
            'max_concurrent_shard_requests'  => 'number',
            'pre_filter_shard_size'          => 'number',
            'preference'                     => 'string',
            'q'                              => 'string',
            'request_cache'                  => 'boolean',
            'rest_total_hits_as_int'         => 'boolean',
            'routing'                        => 'list',
            'scroll'                         => 'string',
            'search_type'                    => 'string',
            'seq_no_primary_term'            => 'boolean',
            'size'                           => 'number',
            'sort'                           => 'list',
            'stats'                          => 'list',
            'stored_fields'                  => 'list',
            'suggest_field'                  => 'string',
            'suggest_mode'                   => 'string',
            'suggest_size'                   => 'number',
            'suggest_text'                   => 'string',
            'terminate_after'                => 'number',
            'timeout'                        => 'string',
            'track_scores'                   => 'boolean',
            'track_total_hits'               => 'boolean',
            'typed_keys'                     => 'boolean',
            'version'                        => 'boolean',
             # Common API query parameters
            'error_trace'                    => 'boolean',
            'filter_path'                    => 'list',
            'human'                          => 'boolean',
            'pretty'                         => 'boolean',
            'source'                         => 'string',
        },
    },

    'knn.stats' => {
        doc     => 'https://docs.opensearch.org/latest/vector-search/api/knn/#stats',
        method  => 'GET',
        parts   => { node_id => {  multi => 1 }, stat => {  multi => 1 }},
        paths   => [
            [ { node_id => 2, stat => 4 }, "_plugins", "_knn", "{node_id}", "stats", "{stat}" ],
            [ { stat => 3 }, "_plugins", "_knn", "stats", "{stat}" ],
            [ { node_id => 2 }, "_plugins", "_knn", "{node_id}", "stats" ],
            [ {}, "_plugins", "_knn", "stats" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'timeout'      => 'string',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'knn.train_model' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/vector-search/api/knn/#train-a-model',
        method  => 'POST',
        parts   => { model_id => {}},
        paths   => [
            [ { model_id => 3 }, "_plugins", "_knn", "models", "{model_id}", "_train" ],
            [ {}, "_plugins", "_knn", "models", "_train" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'preference'   => 'string',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'knn.warmup' => {
        doc     => 'https://docs.opensearch.org/latest/vector-search/api/knn/#warmup-operation',
        method  => 'GET',
        parts   => { index => {  multi => 1,  required => 1 }},
        paths   => [[ { index => 3 }, "_plugins", "_knn", "warmup", "{index}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'list.help' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/list/index/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_list" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'list.indices' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/list/list-indices/',
        method  => 'GET',
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 2 }, "_list", "indices", "{index}" ],
            [ {}, "_list", "indices" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'bytes'                      => 'string',
            'cluster_manager_timeout'    => 'string',
            'expand_wildcards'           => 'list',
            'format'                     => 'string',
            'h'                          => 'list',
            'health'                     => 'string',
            'help'                       => 'boolean',
            'include_unloaded_segments'  => 'boolean',
            'local'                      => 'boolean',
            'master_timeout'             => 'string',
            'next_token'                 => 'string',
            'pri'                        => 'boolean',
            's'                          => 'list',
            'size'                       => 'number',
            'sort'                       => 'string',
            'time'                       => 'string',
            'v'                          => 'boolean',
             # Common API query parameters
            'error_trace'                => 'boolean',
            'filter_path'                => 'list',
            'human'                      => 'boolean',
            'pretty'                     => 'boolean',
            'source'                     => 'string',
        },
    },

    'list.shards' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/list/list-shards/',
        method  => 'GET',
        parts   => { index => {  multi => 1 }},
        paths   => [
            [ { index => 2 }, "_list", "shards", "{index}" ],
            [ {}, "_list", "shards" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'bytes'                    => 'string',
            'cluster_manager_timeout'  => 'string',
            'format'                   => 'string',
            'h'                        => 'list',
            'help'                     => 'boolean',
            'local'                    => 'boolean',
            'master_timeout'           => 'string',
            'next_token'               => 'string',
            's'                        => 'list',
            'size'                     => 'number',
            'sort'                     => 'string',
            'time'                     => 'string',
            'v'                        => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'ltr.add_features_to_set' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'POST',
        parts   => { name => {  required => 1 }, store => {}},
        paths   => [
            [ { store => 1, name => 3 }, "_ltr", "{store}", "_featureset", "{name}", "_addfeatures" ],
            [ { name => 2 }, "_ltr", "_featureset", "{name}", "_addfeatures" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'merge'        => 'boolean',
            'routing'      => 'string',
            'version'      => 'number',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.add_features_to_set_by_query' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'POST',
        parts   => { name => {  required => 1 }, query => {  required => 1 }, store => {}},
        paths   => [
            [ { store => 1, name => 3, query => 5 }, "_ltr", "{store}", "_featureset", "{name}", "_addfeatures", "{query}" ],
            [ { name => 2, query => 4 }, "_ltr", "_featureset", "{name}", "_addfeatures", "{query}" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'merge'        => 'boolean',
            'routing'      => 'string',
            'version'      => 'number',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.cache_stats' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_ltr", "_cachestats" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.clear_cache' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'POST',
        parts   => { store => {}},
        paths   => [
            [ { store => 1 }, "_ltr", "{store}", "_clearcache" ],
            [ {}, "_ltr", "_clearcache" ]
        ],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.create_default_store' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'PUT',
        parts   => {},
        paths   => [[ {}, "_ltr" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.create_feature' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'PUT',
        parts   => { id => {  required => 1 }, store => {}},
        paths   => [
            [ { store => 1, id => 3 }, "_ltr", "{store}", "_feature", "{id}" ],
            [ { id => 2 }, "_ltr", "_feature", "{id}" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'routing'      => 'string',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.create_featureset' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'PUT',
        parts   => { id => {  required => 1 }, store => {}},
        paths   => [
            [ { store => 1, id => 3 }, "_ltr", "{store}", "_featureset", "{id}" ],
            [ { id => 2 }, "_ltr", "_featureset", "{id}" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'routing'      => 'string',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.create_model' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'PUT',
        parts   => { id => {  required => 1 }, store => {}},
        paths   => [
            [ { store => 1, id => 3 }, "_ltr", "{store}", "_model", "{id}" ],
            [ { id => 2 }, "_ltr", "_model", "{id}" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'routing'      => 'string',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.create_model_from_set' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'POST',
        parts   => { name => {  required => 1 }, store => {}},
        paths   => [
            [ { store => 1, name => 3 }, "_ltr", "{store}", "_featureset", "{name}", "_createmodel" ],
            [ { name => 2 }, "_ltr", "_featureset", "{name}", "_createmodel" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'routing'      => 'string',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.create_store' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'PUT',
        parts   => { store => {  required => 1 }},
        paths   => [[ { store => 1 }, "_ltr", "{store}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.delete_default_store' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'DELETE',
        parts   => {},
        paths   => [[ {}, "_ltr" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.delete_feature' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'DELETE',
        parts   => { id => {  required => 1 }, store => {}},
        paths   => [
            [ { store => 1, id => 3 }, "_ltr", "{store}", "_feature", "{id}" ],
            [ { id => 2 }, "_ltr", "_feature", "{id}" ]
        ],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.delete_featureset' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'DELETE',
        parts   => { id => {  required => 1 }, store => {}},
        paths   => [
            [ { store => 1, id => 3 }, "_ltr", "{store}", "_featureset", "{id}" ],
            [ { id => 2 }, "_ltr", "_featureset", "{id}" ]
        ],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.delete_model' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'DELETE',
        parts   => { id => {  required => 1 }, store => {}},
        paths   => [
            [ { store => 1, id => 3 }, "_ltr", "{store}", "_model", "{id}" ],
            [ { id => 2 }, "_ltr", "_model", "{id}" ]
        ],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.delete_store' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'DELETE',
        parts   => { store => {  required => 1 }},
        paths   => [[ { store => 1 }, "_ltr", "{store}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.get_feature' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'GET',
        parts   => { id => {  required => 1 }, store => {}},
        paths   => [
            [ { store => 1, id => 3 }, "_ltr", "{store}", "_feature", "{id}" ],
            [ { id => 2 }, "_ltr", "_feature", "{id}" ]
        ],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.get_featureset' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'GET',
        parts   => { id => {  required => 1 }, store => {}},
        paths   => [
            [ { store => 1, id => 3 }, "_ltr", "{store}", "_featureset", "{id}" ],
            [ { id => 2 }, "_ltr", "_featureset", "{id}" ]
        ],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.get_model' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'GET',
        parts   => { id => {  required => 1 }, store => {}},
        paths   => [
            [ { store => 1, id => 3 }, "_ltr", "{store}", "_model", "{id}" ],
            [ { id => 2 }, "_ltr", "_model", "{id}" ]
        ],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.get_store' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'GET',
        parts   => { store => {  required => 1 }},
        paths   => [[ { store => 1 }, "_ltr", "{store}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.list_stores' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_ltr" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.search_features' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'GET',
        parts   => { store => {}},
        paths   => [
            [ { store => 1 }, "_ltr", "{store}", "_feature" ],
            [ {}, "_ltr", "_feature" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'from'         => 'number',
            'prefix'       => 'string',
            'size'         => 'number',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.search_featuresets' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'GET',
        parts   => { store => {}},
        paths   => [
            [ { store => 1 }, "_ltr", "{store}", "_featureset" ],
            [ {}, "_ltr", "_featureset" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'from'         => 'number',
            'prefix'       => 'string',
            'size'         => 'number',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.search_models' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'GET',
        parts   => { store => {}},
        paths   => [
            [ { store => 1 }, "_ltr", "{store}", "_model" ],
            [ {}, "_ltr", "_model" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'from'         => 'number',
            'prefix'       => 'string',
            'size'         => 'number',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.stats' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'GET',
        parts   => { node_id => {  multi => 1 }, stat => {  multi => 1 }},
        paths   => [
            [ { node_id => 2, stat => 4 }, "_plugins", "_ltr", "{node_id}", "stats", "{stat}" ],
            [ { stat => 3 }, "_plugins", "_ltr", "stats", "{stat}" ],
            [ { node_id => 2 }, "_plugins", "_ltr", "{node_id}", "stats" ],
            [ {}, "_plugins", "_ltr", "stats" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'timeout'      => 'string',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.update_feature' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'POST',
        parts   => { id => {  required => 1 }, store => {}},
        paths   => [
            [ { store => 1, id => 3 }, "_ltr", "{store}", "_feature", "{id}" ],
            [ { id => 2 }, "_ltr", "_feature", "{id}" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'routing'      => 'string',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ltr.update_featureset' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ltr/index/',
        method  => 'POST',
        parts   => { id => {  required => 1 }, store => {}},
        paths   => [
            [ { store => 1, id => 3 }, "_ltr", "{store}", "_featureset", "{id}" ],
            [ { id => 2 }, "_ltr", "_featureset", "{id}" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'routing'      => 'string',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.add_agentic_memory' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => { memory_container_id => {  required => 1 }},
        paths   => [[ { memory_container_id => 3 }, "_plugins", "_ml", "memory_containers", "{memory_container_id}", "memories" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.chunk_model' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => { chunk_number => {  required => 1 }, model_id => {  required => 1 }},
        paths   => [[ { model_id => 3, chunk_number => 5 }, "_plugins", "_ml", "models", "{model_id}", "chunk", "{chunk_number}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.create_connector' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_ml", "connectors", "_create" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.create_controller' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => { model_id => {  required => 1 }},
        paths   => [[ { model_id => 3 }, "_plugins", "_ml", "controllers", "{model_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.create_memory' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_ml", "memory" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.create_memory_container' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_ml", "memory_containers", "_create" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.create_memory_container_session' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => { memory_container_id => {  required => 1 }},
        paths   => [[ { memory_container_id => 3 }, "_plugins", "_ml", "memory_containers", "{memory_container_id}", "memories", "sessions" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.create_message' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => { memory_id => {  required => 1 }},
        paths   => [[ { memory_id => 3 }, "_plugins", "_ml", "memory", "{memory_id}", "messages" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.create_model_meta' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_ml", "models", "meta" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.delete_agent' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'DELETE',
        parts   => { agent_id => {  required => 1 }},
        paths   => [[ { agent_id => 3 }, "_plugins", "_ml", "agents", "{agent_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.delete_agentic_memory' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'DELETE',
        parts   => { id => {  required => 1 }, memory_container_id => {  required => 1 }, type => {  required => 1 }},
        paths   => [[ { memory_container_id => 3, type => 5, id => 6 }, "_plugins", "_ml", "memory_containers", "{memory_container_id}", "memories", "{type}", "{id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.delete_agentic_memory_query' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => { memory_container_id => {  required => 1 }, type => {  required => 1 }},
        paths   => [[ { memory_container_id => 3, type => 5 }, "_plugins", "_ml", "memory_containers", "{memory_container_id}", "memories", "{type}", "_delete_by_query" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.delete_connector' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'DELETE',
        parts   => { connector_id => {  required => 1 }},
        paths   => [[ { connector_id => 3 }, "_plugins", "_ml", "connectors", "{connector_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.delete_controller' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'DELETE',
        parts   => { model_id => {  required => 1 }},
        paths   => [[ { model_id => 3 }, "_plugins", "_ml", "controllers", "{model_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.delete_memory' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'DELETE',
        parts   => { memory_id => {  required => 1 }},
        paths   => [[ { memory_id => 3 }, "_plugins", "_ml", "memory", "{memory_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.delete_memory_container' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'DELETE',
        parts   => { memory_container_id => {  required => 1 }},
        paths   => [[ { memory_container_id => 3 }, "_plugins", "_ml", "memory_containers", "{memory_container_id}" ]],
        qs      => {
             # Endpoint specific query parameters
            'delete_all_memories'  => 'boolean',
            'delete_memories'      => 'list',
             # Common API query parameters
            'error_trace'          => 'boolean',
            'filter_path'          => 'list',
            'human'                => 'boolean',
            'pretty'               => 'boolean',
            'source'               => 'string',
        },
    },

    'ml.delete_model' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'DELETE',
        parts   => { model_id => {  required => 1 }},
        paths   => [[ { model_id => 3 }, "_plugins", "_ml", "models", "{model_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.delete_model_group' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'DELETE',
        parts   => { model_group_id => {  required => 1 }},
        paths   => [[ { model_group_id => 3 }, "_plugins", "_ml", "model_groups", "{model_group_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.delete_task' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'DELETE',
        parts   => { task_id => {  required => 1 }},
        paths   => [[ { task_id => 3 }, "_plugins", "_ml", "tasks", "{task_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.deploy_model' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => { model_id => {  required => 1 }},
        paths   => [[ { model_id => 3 }, "_plugins", "_ml", "models", "{model_id}", "_deploy" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.execute_agent' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => { agent_id => {  required => 1 }},
        paths   => [[ { agent_id => 3 }, "_plugins", "_ml", "agents", "{agent_id}", "_execute" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.execute_agent_stream' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => { agent_id => {  required => 1 }},
        paths   => [[ { agent_id => 3 }, "_plugins", "_ml", "agents", "{agent_id}", "_execute", "stream" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.execute_algorithm' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => { algorithm_name => {  required => 1 }},
        paths   => [[ { algorithm_name => 3 }, "_plugins", "_ml", "_execute", "{algorithm_name}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.execute_tool' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => { tool_name => {  required => 1 }},
        paths   => [[ { tool_name => 4 }, "_plugins", "_ml", "tools", "_execute", "{tool_name}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.get_agent' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'GET',
        parts   => { agent_id => {  required => 1 }},
        paths   => [[ { agent_id => 3 }, "_plugins", "_ml", "agents", "{agent_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.get_agentic_memory' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'GET',
        parts   => { id => {  required => 1 }, memory_container_id => {  required => 1 }, type => {  required => 1 }},
        paths   => [[ { memory_container_id => 3, type => 5, id => 6 }, "_plugins", "_ml", "memory_containers", "{memory_container_id}", "memories", "{type}", "{id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.get_all_memories' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_ml", "memory" ]],
        qs      => {
             # Endpoint specific query parameters
            'max_results'  => 'number',
            'next_token'   => 'number',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.get_all_messages' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'GET',
        parts   => { memory_id => {  required => 1 }},
        paths   => [[ { memory_id => 3 }, "_plugins", "_ml", "memory", "{memory_id}", "messages" ]],
        qs      => {
             # Endpoint specific query parameters
            'max_results'  => 'number',
            'next_token'   => 'number',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.get_all_tools' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_ml", "tools" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.get_connector' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'GET',
        parts   => { connector_id => {  required => 1 }},
        paths   => [[ { connector_id => 3 }, "_plugins", "_ml", "connectors", "{connector_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.get_controller' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'GET',
        parts   => { model_id => {  required => 1 }},
        paths   => [[ { model_id => 3 }, "_plugins", "_ml", "controllers", "{model_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.get_memory' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'GET',
        parts   => { memory_id => {  required => 1 }},
        paths   => [[ { memory_id => 3 }, "_plugins", "_ml", "memory", "{memory_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.get_memory_container' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'GET',
        parts   => { memory_container_id => {  required => 1 }},
        paths   => [[ { memory_container_id => 3 }, "_plugins", "_ml", "memory_containers", "{memory_container_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.get_message' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'GET',
        parts   => { message_id => {  required => 1 }},
        paths   => [[ { message_id => 4 }, "_plugins", "_ml", "memory", "message", "{message_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.get_message_traces' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'GET',
        parts   => { message_id => {  required => 1 }},
        paths   => [[ { message_id => 4 }, "_plugins", "_ml", "memory", "message", "{message_id}", "traces" ]],
        qs      => {
             # Endpoint specific query parameters
            'max_results'  => 'number',
            'next_token'   => 'number',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.get_model' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'GET',
        parts   => { model_id => {  required => 1 }},
        paths   => [[ { model_id => 3 }, "_plugins", "_ml", "models", "{model_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.get_model_group' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'GET',
        parts   => { model_group_id => {  required => 1 }},
        paths   => [[ { model_group_id => 3 }, "_plugins", "_ml", "model_groups", "{model_group_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.get_profile' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_ml", "profile" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.get_profile_models' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'GET',
        parts   => { model_id => {}},
        paths   => [
            [ { model_id => 4 }, "_plugins", "_ml", "profile", "models", "{model_id}" ],
            [ {}, "_plugins", "_ml", "profile", "models" ]
        ],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.get_profile_tasks' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'GET',
        parts   => { task_id => {}},
        paths   => [
            [ { task_id => 4 }, "_plugins", "_ml", "profile", "tasks", "{task_id}" ],
            [ {}, "_plugins", "_ml", "profile", "tasks" ]
        ],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.get_stats' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'GET',
        parts   => { node_id => {}, stat => {  multi => 1 }},
        paths   => [
            [ { node_id => 2, stat => 4 }, "_plugins", "_ml", "{node_id}", "stats", "{stat}" ],
            [ { stat => 3 }, "_plugins", "_ml", "stats", "{stat}" ],
            [ { node_id => 2 }, "_plugins", "_ml", "{node_id}", "stats" ],
            [ {}, "_plugins", "_ml", "stats" ]
        ],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.get_task' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'GET',
        parts   => { task_id => {  required => 1 }},
        paths   => [[ { task_id => 3 }, "_plugins", "_ml", "tasks", "{task_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.get_tool' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'GET',
        parts   => { tool_name => {  required => 1 }},
        paths   => [[ { tool_name => 3 }, "_plugins", "_ml", "tools", "{tool_name}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.load_model' => {
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => { model_id => {  required => 1 }},
        paths   => [[ { model_id => 3 }, "_plugins", "_ml", "models", "{model_id}", "_load" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.predict' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => { algorithm_name => {  required => 1 }, model_id => {  required => 1 }},
        paths   => [[ { algorithm_name => 3, model_id => 4 }, "_plugins", "_ml", "_predict", "{algorithm_name}", "{model_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.predict_model' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => { model_id => {  required => 1 }},
        paths   => [[ { model_id => 3 }, "_plugins", "_ml", "models", "{model_id}", "_predict" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.predict_model_stream' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => { model_id => {  required => 1 }},
        paths   => [[ { model_id => 3 }, "_plugins", "_ml", "models", "{model_id}", "_predict", "stream" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.register_agents' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_ml", "agents", "_register" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.register_model' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_ml", "models", "_register" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.register_model_group' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_ml", "model_groups", "_register" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.register_model_meta' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_ml", "models", "_register_meta" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.search_agentic_memory' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'GET',
        parts   => { memory_container_id => {  required => 1 }, type => {  required => 1 }},
        paths   => [[ { memory_container_id => 3, type => 5 }, "_plugins", "_ml", "memory_containers", "{memory_container_id}", "memories", "{type}", "_search" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.search_agents' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => {},
        paths   => [[ {}, "_plugins", "_ml", "agents", "_search" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.search_connectors' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => {},
        paths   => [[ {}, "_plugins", "_ml", "connectors", "_search" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.search_memory' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => {},
        paths   => [[ {}, "_plugins", "_ml", "memory", "_search" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.search_memory_container' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => {},
        paths   => [[ {}, "_plugins", "_ml", "memory_containers", "_search" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.search_message' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => { memory_id => {  required => 1 }},
        paths   => [[ { memory_id => 3 }, "_plugins", "_ml", "memory", "{memory_id}", "_search" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.search_model_group' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => {},
        paths   => [[ {}, "_plugins", "_ml", "model_groups", "_search" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.search_models' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => {},
        paths   => [[ {}, "_plugins", "_ml", "models", "_search" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.search_tasks' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => {},
        paths   => [[ {}, "_plugins", "_ml", "tasks", "_search" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.train' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => { algorithm_name => {  required => 1 }},
        paths   => [[ { algorithm_name => 3 }, "_plugins", "_ml", "_train", "{algorithm_name}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.train_predict' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => { algorithm_name => {  required => 1 }},
        paths   => [[ { algorithm_name => 3 }, "_plugins", "_ml", "_train_predict", "{algorithm_name}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.undeploy_model' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => { model_id => {}},
        paths   => [
            [ { model_id => 3 }, "_plugins", "_ml", "models", "{model_id}", "_undeploy" ],
            [ {}, "_plugins", "_ml", "models", "_undeploy" ]
        ],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.unload_model' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => { model_id => {}},
        paths   => [
            [ { model_id => 3 }, "_plugins", "_ml", "models", "{model_id}", "_unload" ],
            [ {}, "_plugins", "_ml", "models", "_unload" ]
        ],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.update_agentic_memory' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'PUT',
        parts   => { id => {  required => 1 }, memory_container_id => {  required => 1 }, type => {  required => 1 }},
        paths   => [[ { memory_container_id => 3, type => 5, id => 6 }, "_plugins", "_ml", "memory_containers", "{memory_container_id}", "memories", "{type}", "{id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.update_connector' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'PUT',
        parts   => { connector_id => {  required => 1 }},
        paths   => [[ { connector_id => 3 }, "_plugins", "_ml", "connectors", "{connector_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.update_controller' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'PUT',
        parts   => { model_id => {  required => 1 }},
        paths   => [[ { model_id => 3 }, "_plugins", "_ml", "controllers", "{model_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.update_memory' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'PUT',
        parts   => { memory_id => {  required => 1 }},
        paths   => [[ { memory_id => 3 }, "_plugins", "_ml", "memory", "{memory_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.update_memory_container' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'PUT',
        parts   => { memory_container_id => {  required => 1 }},
        paths   => [[ { memory_container_id => 3 }, "_plugins", "_ml", "memory_containers", "{memory_container_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.update_message' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'PUT',
        parts   => { message_id => {  required => 1 }},
        paths   => [[ { message_id => 4 }, "_plugins", "_ml", "memory", "message", "{message_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.update_model' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'PUT',
        parts   => { model_id => {  required => 1 }},
        paths   => [[ { model_id => 3 }, "_plugins", "_ml", "models", "{model_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.update_model_group' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'PUT',
        parts   => { model_group_id => {  required => 1 }},
        paths   => [[ { model_group_id => 3 }, "_plugins", "_ml", "model_groups", "{model_group_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.upload_chunk' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => { chunk_number => {  required => 1 }, model_id => {  required => 1 }},
        paths   => [[ { model_id => 3, chunk_number => 5 }, "_plugins", "_ml", "models", "{model_id}", "upload_chunk", "{chunk_number}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ml.upload_model' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/ml-commons-plugin/api/index/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_ml", "models", "_upload" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'neural.stats' => {
        doc     => 'https://docs.opensearch.org/latest/vector-search/api/neural/',
        method  => 'GET',
        parts   => { node_id => {}, stat => {  multi => 1 }},
        paths   => [
            [ { node_id => 2, stat => 4 }, "_plugins", "_neural", "{node_id}", "stats", "{stat}" ],
            [ { stat => 3 }, "_plugins", "_neural", "stats", "{stat}" ],
            [ { node_id => 2 }, "_plugins", "_neural", "{node_id}", "stats" ],
            [ {}, "_plugins", "_neural", "stats" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'flat_stat_paths'           => 'boolean',
            'include_all_nodes'         => 'boolean',
            'include_individual_nodes'  => 'boolean',
            'include_info'              => 'boolean',
            'include_metadata'          => 'boolean',
             # Common API query parameters
            'error_trace'               => 'boolean',
            'filter_path'               => 'list',
            'human'                     => 'boolean',
            'pretty'                    => 'boolean',
            'source'                    => 'string',
        },
    },

    'nodes.hot_threads' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/nodes-apis/nodes-hot-threads/',
        method  => 'GET',
        parts   => { node_id => {  multi => 1 }},
        paths   => [
            [ { node_id => 1 }, "_nodes", "{node_id}", "hot_threads" ],
            [ {}, "_nodes", "hot_threads" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'ignore_idle_threads'  => 'boolean',
            'interval'             => 'string',
            'snapshots'            => 'number',
            'threads'              => 'number',
            'timeout'              => 'string',
            'type'                 => 'string',
             # Common API query parameters
            'error_trace'          => 'boolean',
            'filter_path'          => 'list',
            'human'                => 'boolean',
            'pretty'               => 'boolean',
            'source'               => 'string',
        },
    },

    'nodes.info' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/nodes-apis/nodes-info/',
        method  => 'GET',
        parts   => { metric => {  multi => 1 }, node_id => {  multi => 1 }},
        paths   => [
            [ { node_id => 1, metric => 2 }, "_nodes", "{node_id}", "{metric}" ],
            [ { metric => 1 }, "_nodes", "{metric}" ],
            [ { node_id => 1 }, "_nodes", "{node_id}" ],
            [ {}, "_nodes" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'flat_settings'  => 'boolean',
            'timeout'        => 'string',
             # Common API query parameters
            'error_trace'    => 'boolean',
            'filter_path'    => 'list',
            'human'          => 'boolean',
            'pretty'         => 'boolean',
            'source'         => 'string',
        },
    },

    'nodes.reload_secure_settings' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/nodes-apis/nodes-reload-secure/',
        method  => 'POST',
        parts   => { node_id => {  multi => 1 }},
        paths   => [
            [ { node_id => 1 }, "_nodes", "{node_id}", "reload_secure_settings" ],
            [ {}, "_nodes", "reload_secure_settings" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'timeout'      => 'string',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'nodes.stats' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/nodes-apis/nodes-usage/',
        method  => 'GET',
        parts   => { index_metric => {  multi => 1 }, metric => {  multi => 1 }, node_id => {  multi => 1 }},
        paths   => [
            [ { node_id => 1, metric => 3, index_metric => 4 }, "_nodes", "{node_id}", "stats", "{metric}", "{index_metric}" ],
            [ { metric => 2, index_metric => 3 }, "_nodes", "stats", "{metric}", "{index_metric}" ],
            [ { node_id => 1, metric => 3 }, "_nodes", "{node_id}", "stats", "{metric}" ],
            [ { metric => 2 }, "_nodes", "stats", "{metric}" ],
            [ { node_id => 1 }, "_nodes", "{node_id}", "stats" ],
            [ {}, "_nodes", "stats" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'completion_fields'           => 'list',
            'fielddata_fields'            => 'list',
            'fields'                      => 'list',
            'groups'                      => 'list',
            'include_segment_file_sizes'  => 'boolean',
            'level'                       => 'string',
            'timeout'                     => 'string',
            'types'                       => 'list',
             # Common API query parameters
            'error_trace'                 => 'boolean',
            'filter_path'                 => 'list',
            'human'                       => 'boolean',
            'pretty'                      => 'boolean',
            'source'                      => 'string',
        },
    },

    'nodes.usage' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/nodes-apis/index/',
        method  => 'GET',
        parts   => { metric => {  multi => 1 }, node_id => {  multi => 1 }},
        paths   => [
            [ { node_id => 1, metric => 3 }, "_nodes", "{node_id}", "usage", "{metric}" ],
            [ { metric => 2 }, "_nodes", "usage", "{metric}" ],
            [ { node_id => 1 }, "_nodes", "{node_id}", "usage" ],
            [ {}, "_nodes", "usage" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'timeout'      => 'string',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'notifications.create_config' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/observing-your-data/notifications/api/#create-channel-configuration',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_notifications", "configs" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'notifications.delete_config' => {
        doc     => 'https://opensearch.org/docs/latest/observing-your-data/notifications/api/#delete-channel-configuration',
        method  => 'DELETE',
        parts   => { config_id => {  required => 1 }},
        paths   => [[ { config_id => 3 }, "_plugins", "_notifications", "configs", "{config_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'notifications.delete_configs' => {
        doc     => 'https://opensearch.org/docs/latest/observing-your-data/notifications/api/#delete-channel-configuration',
        method  => 'DELETE',
        parts   => {},
        paths   => [[ {}, "_plugins", "_notifications", "configs" ]],
        qs      => {
             # Endpoint specific query parameters
            'config_id'       => 'string',
            'config_id_list'  => 'string',
             # Common API query parameters
            'error_trace'     => 'boolean',
            'filter_path'     => 'list',
            'human'           => 'boolean',
            'pretty'          => 'boolean',
            'source'          => 'string',
        },
    },

    'notifications.get_config' => {
        doc     => 'https://docs.opensearch.org/latest/observing-your-data/notifications/index/',
        method  => 'GET',
        parts   => { config_id => {  required => 1 }},
        paths   => [[ { config_id => 3 }, "_plugins", "_notifications", "configs", "{config_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'notifications.get_configs' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/observing-your-data/notifications/api/#list-all-notification-configurations',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_notifications", "configs" ]],
        qs      => {
             # Endpoint specific query parameters
            'chime.url'                                     => 'string',
            'chime.url.keyword'                             => 'string',
            'config_id'                                     => 'string',
            'config_id_list'                                => 'list',
            'config_type'                                   => 'string',
            'created_time_ms'                               => 'number',
            'description'                                   => 'string',
            'description.keyword'                           => 'string',
            'email.email_account_id'                        => 'string',
            'email.email_group_id_list'                     => 'string',
            'email.recipient_list.recipient'                => 'string',
            'email.recipient_list.recipient.keyword'        => 'string',
            'email_group.recipient_list.recipient'          => 'string',
            'email_group.recipient_list.recipient.keyword'  => 'string',
            'is_enabled'                                    => 'boolean',
            'last_updated_time_ms'                          => 'number',
            'microsoft_teams.url'                           => 'string',
            'microsoft_teams.url.keyword'                   => 'string',
            'name'                                          => 'string',
            'name.keyword'                                  => 'string',
            'query'                                         => 'string',
            'ses_account.from_address'                      => 'string',
            'ses_account.from_address.keyword'              => 'string',
            'ses_account.region'                            => 'string',
            'ses_account.role_arn'                          => 'string',
            'ses_account.role_arn.keyword'                  => 'string',
            'slack.url'                                     => 'string',
            'slack.url.keyword'                             => 'string',
            'smtp_account.from_address'                     => 'string',
            'smtp_account.from_address.keyword'             => 'string',
            'smtp_account.host'                             => 'string',
            'smtp_account.host.keyword'                     => 'string',
            'smtp_account.method'                           => 'string',
            'sns.role_arn'                                  => 'string',
            'sns.role_arn.keyword'                          => 'string',
            'sns.topic_arn'                                 => 'string',
            'sns.topic_arn.keyword'                         => 'string',
            'text_query'                                    => 'string',
            'webhook.url'                                   => 'string',
            'webhook.url.keyword'                           => 'string',
             # Common API query parameters
            'error_trace'                                   => 'boolean',
            'filter_path'                                   => 'list',
            'human'                                         => 'boolean',
            'pretty'                                        => 'boolean',
            'source'                                        => 'string',
        },
    },

    'notifications.list_channels' => {
        doc     => 'https://opensearch.org/docs/latest/observing-your-data/notifications/api/#list-all-notification-channels',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_notifications", "channels" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'notifications.list_features' => {
        doc     => 'https://opensearch.org/docs/latest/observing-your-data/notifications/api/#list-supported-channel-configurations',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_notifications", "features" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'notifications.send_test' => {
        doc     => 'https://opensearch.org/docs/latest/observing-your-data/notifications/api/#send-test-notification',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => { config_id => {  required => 1 }},
        paths   => [[ { config_id => 4 }, "_plugins", "_notifications", "feature", "test", "{config_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'notifications.update_config' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/observing-your-data/notifications/api/#update-channel-configuration',
        method  => 'PUT',
        parts   => { config_id => {  required => 1 }},
        paths   => [[ { config_id => 3 }, "_plugins", "_notifications", "configs", "{config_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'observability.create_object' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/observing-your-data/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_observability", "object" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'observability.delete_object' => {
        doc     => 'https://docs.opensearch.org/latest/observing-your-data/',
        method  => 'DELETE',
        parts   => { object_id => {  required => 1 }},
        paths   => [[ { object_id => 3 }, "_plugins", "_observability", "object", "{object_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'observability.delete_objects' => {
        doc     => 'https://docs.opensearch.org/latest/observing-your-data/',
        method  => 'DELETE',
        parts   => {},
        paths   => [[ {}, "_plugins", "_observability", "object" ]],
        qs      => {
             # Endpoint specific query parameters
            'objectId'      => 'string',
            'objectIdList'  => 'string',
             # Common API query parameters
            'error_trace'   => 'boolean',
            'filter_path'   => 'list',
            'human'         => 'boolean',
            'pretty'        => 'boolean',
            'source'        => 'string',
        },
    },

    'observability.get_localstats' => {
        doc     => 'https://docs.opensearch.org/latest/observing-your-data/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_observability", "_local", "stats" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'observability.get_object' => {
        doc     => 'https://docs.opensearch.org/latest/observing-your-data/',
        method  => 'GET',
        parts   => { object_id => {  required => 1 }},
        paths   => [[ { object_id => 3 }, "_plugins", "_observability", "object", "{object_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'observability.list_objects' => {
        doc     => 'https://docs.opensearch.org/latest/observing-your-data/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_observability", "object" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'observability.update_object' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/observing-your-data/',
        method  => 'PUT',
        parts   => { object_id => {  required => 1 }},
        paths   => [[ { object_id => 3 }, "_plugins", "_observability", "object", "{object_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ppl.explain' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/search-plugins/sql/sql-ppl-api/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_ppl", "_explain" ]],
        qs      => {
             # Endpoint specific query parameters
            'format'       => 'string',
            'sanitize'     => 'boolean',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ppl.get_stats' => {
        doc     => 'https://opensearch.org/docs/latest/search-plugins/sql/monitoring/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_ppl", "stats" ]],
        qs      => {
             # Endpoint specific query parameters
            'format'       => 'string',
            'sanitize'     => 'boolean',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ppl.post_stats' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/search-plugins/sql/monitoring/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_ppl", "stats" ]],
        qs      => {
             # Endpoint specific query parameters
            'format'       => 'string',
            'sanitize'     => 'boolean',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ppl.query' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/search-plugins/sql/sql-ppl-api/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_ppl" ]],
        qs      => {
             # Endpoint specific query parameters
            'format'       => 'string',
            'sanitize'     => 'boolean',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'query.datasource_delete' => {
        doc     => 'https://docs.opensearch.org/latest/observing-your-data/prometheusmetrics/',
        method  => 'DELETE',
        parts   => { datasource_name => {  required => 1 }},
        paths   => [[ { datasource_name => 3 }, "_plugins", "_query", "_datasources", "{datasource_name}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'query.datasource_retrieve' => {
        doc     => 'https://docs.opensearch.org/latest/observing-your-data/prometheusmetrics/',
        method  => 'GET',
        parts   => { datasource_name => {  required => 1 }},
        paths   => [[ { datasource_name => 3 }, "_plugins", "_query", "_datasources", "{datasource_name}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'query.datasources_create' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/observing-your-data/prometheusmetrics/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_query", "_datasources" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'query.datasources_list' => {
        doc     => 'https://docs.opensearch.org/latest/observing-your-data/prometheusmetrics/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_query", "_datasources" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'query.datasources_update' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/observing-your-data/prometheusmetrics/',
        method  => 'PUT',
        parts   => {},
        paths   => [[ {}, "_plugins", "_query", "_datasources" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'remote_store.restore' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/opensearch/remote/#restoring-from-a-backup',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_remotestore", "_restore" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'wait_for_completion'      => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'replication.autofollow_stats' => {
        doc     => 'https://opensearch.org/docs/latest/tuning-your-cluster/replication-plugin/api/#get-auto-follow-stats',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_replication", "autofollow_stats" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'replication.create_replication_rule' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/tuning-your-cluster/replication-plugin/api/#create-replication-rule',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_replication", "_autofollow" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'replication.delete_replication_rule' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/tuning-your-cluster/replication-plugin/api/#delete-replication-rule',
        method  => 'DELETE',
        parts   => {},
        paths   => [[ {}, "_plugins", "_replication", "_autofollow" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'replication.follower_stats' => {
        doc     => 'https://opensearch.org/docs/latest/tuning-your-cluster/replication-plugin/api/#get-follower-cluster-stats',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_replication", "follower_stats" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'replication.leader_stats' => {
        doc     => 'https://opensearch.org/docs/latest/tuning-your-cluster/replication-plugin/api/#get-leader-cluster-stats',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_replication", "leader_stats" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'replication.pause' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/tuning-your-cluster/replication-plugin/api/#pause-replication',
        method  => 'POST',
        parts   => { index => {  required => 1 }},
        paths   => [[ { index => 2 }, "_plugins", "_replication", "{index}", "_pause" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'replication.resume' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/tuning-your-cluster/replication-plugin/api/#resume-replication',
        method  => 'POST',
        parts   => { index => {  required => 1 }},
        paths   => [[ { index => 2 }, "_plugins", "_replication", "{index}", "_resume" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'replication.start' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/tuning-your-cluster/replication-plugin/api/#start-replication',
        method  => 'PUT',
        parts   => { index => {  required => 1 }},
        paths   => [[ { index => 2 }, "_plugins", "_replication", "{index}", "_start" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'replication.status' => {
        doc     => 'https://opensearch.org/docs/latest/tuning-your-cluster/replication-plugin/api/#get-replication-status',
        method  => 'GET',
        parts   => { index => {  required => 1 }},
        paths   => [[ { index => 2 }, "_plugins", "_replication", "{index}", "_status" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'replication.stop' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/tuning-your-cluster/replication-plugin/api/#stop-replication',
        method  => 'POST',
        parts   => { index => {  required => 1 }},
        paths   => [[ { index => 2 }, "_plugins", "_replication", "{index}", "_stop" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'replication.update_settings' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/tuning-your-cluster/replication-plugin/api/#update-settings',
        method  => 'PUT',
        parts   => { index => {  required => 1 }},
        paths   => [[ { index => 2 }, "_plugins", "_replication", "{index}", "_update" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'rollups.delete' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/index-rollups/rollup-api/#delete-an-index-rollup-job',
        method  => 'DELETE',
        parts   => { id => {  required => 1 }},
        paths   => [[ { id => 3 }, "_plugins", "_rollup", "jobs", "{id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'rollups.explain' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/index-rollups/rollup-api/#explain-an-index-rollup-job',
        method  => 'GET',
        parts   => { id => {  required => 1 }},
        paths   => [[ { id => 3 }, "_plugins", "_rollup", "jobs", "{id}", "_explain" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'rollups.get' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/index-rollups/rollup-api/#get-an-index-rollup-job',
        method  => 'GET',
        parts   => { id => {  required => 1 }},
        paths   => [[ { id => 3 }, "_plugins", "_rollup", "jobs", "{id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'rollups.put' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/im-plugin/index-rollups/rollup-api/#create-or-update-an-index-rollup-job',
        method  => 'PUT',
        parts   => { id => {  required => 1 }},
        paths   => [[ { id => 3 }, "_plugins", "_rollup", "jobs", "{id}" ]],
        qs      => {
             # Endpoint specific query parameters
            'if_primary_term'  => 'number',
            'if_seq_no'        => 'number',
             # Common API query parameters
            'error_trace'      => 'boolean',
            'filter_path'      => 'list',
            'human'            => 'boolean',
            'pretty'           => 'boolean',
            'source'           => 'string',
        },
    },

    'rollups.start' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/index-rollups/rollup-api/#start-or-stop-an-index-rollup-job',
        method  => 'POST',
        parts   => { id => {  required => 1 }},
        paths   => [[ { id => 3 }, "_plugins", "_rollup", "jobs", "{id}", "_start" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'rollups.stop' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/index-rollups/rollup-api/#start-or-stop-an-index-rollup-job',
        method  => 'POST',
        parts   => { id => {  required => 1 }},
        paths   => [[ { id => 3 }, "_plugins", "_rollup", "jobs", "{id}", "_stop" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'search_pipeline.delete' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/search-pipelines/index/',
        method  => 'DELETE',
        parts   => { id => {  required => 1 }},
        paths   => [[ { id => 2 }, "_search", "pipeline", "{id}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'search_pipeline.get' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/search-pipelines/index/',
        method  => 'GET',
        parts   => { id => {}},
        paths   => [
            [ { id => 2 }, "_search", "pipeline", "{id}" ],
            [ {}, "_search", "pipeline" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'search_pipeline.put' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/search-plugins/search-pipelines/creating-search-pipeline/',
        method  => 'PUT',
        parts   => { id => {  required => 1 }},
        paths   => [[ { id => 2 }, "_search", "pipeline", "{id}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'search_relevance.delete_experiments' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/',
        method  => 'DELETE',
        parts   => { experiment_id => {  required => 1 }},
        paths   => [[ { experiment_id => 3 }, "_plugins", "_search_relevance", "experiments", "{experiment_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'search_relevance.delete_judgments' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/',
        method  => 'DELETE',
        parts   => { judgment_id => {  required => 1 }},
        paths   => [[ { judgment_id => 3 }, "_plugins", "_search_relevance", "judgments", "{judgment_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'search_relevance.delete_query_sets' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/',
        method  => 'DELETE',
        parts   => { query_set_id => {  required => 1 }},
        paths   => [[ { query_set_id => 3 }, "_plugins", "_search_relevance", "query_sets", "{query_set_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'search_relevance.delete_scheduled_experiments' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/',
        method  => 'DELETE',
        parts   => { experiment_id => {  required => 1 }},
        paths   => [[ { experiment_id => 4 }, "_plugins", "_search_relevance", "experiments", "schedule", "{experiment_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'search_relevance.delete_search_configurations' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/',
        method  => 'DELETE',
        parts   => { search_configuration_id => {  required => 1 }},
        paths   => [[ { search_configuration_id => 3 }, "_plugins", "_search_relevance", "search_configurations", "{search_configuration_id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'search_relevance.get_experiments' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/',
        method  => 'GET',
        parts   => { experiment_id => {}},
        paths   => [
            [ { experiment_id => 3 }, "_plugins", "_search_relevance", "experiments", "{experiment_id}" ],
            [ {}, "_plugins", "_search_relevance", "experiments" ]
        ],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'search_relevance.get_judgments' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/',
        method  => 'GET',
        parts   => { judgment_id => {}},
        paths   => [
            [ { judgment_id => 3 }, "_plugins", "_search_relevance", "judgments", "{judgment_id}" ],
            [ {}, "_plugins", "_search_relevance", "judgments" ]
        ],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'search_relevance.get_node_stats' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/',
        method  => 'GET',
        parts   => { node_id => {  required => 1 }, stat => {}},
        paths   => [
            [ { node_id => 2, stat => 4 }, "_plugins", "_search_relevance", "{node_id}", "stats", "{stat}" ],
            [ { node_id => 2 }, "_plugins", "_search_relevance", "{node_id}", "stats" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'flat_stat_paths'           => 'string',
            'include_all_nodes'         => 'string',
            'include_individual_nodes'  => 'string',
            'include_info'              => 'string',
            'include_metadata'          => 'string',
             # Common API query parameters
            'error_trace'               => 'boolean',
            'filter_path'               => 'list',
            'human'                     => 'boolean',
            'pretty'                    => 'boolean',
            'source'                    => 'string',
        },
    },

    'search_relevance.get_query_sets' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/',
        method  => 'GET',
        parts   => { query_set_id => {}},
        paths   => [
            [ { query_set_id => 3 }, "_plugins", "_search_relevance", "query_sets", "{query_set_id}" ],
            [ {}, "_plugins", "_search_relevance", "query_sets" ]
        ],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'search_relevance.get_scheduled_experiments' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/',
        method  => 'GET',
        parts   => { experiment_id => {}},
        paths   => [
            [ { experiment_id => 4 }, "_plugins", "_search_relevance", "experiments", "schedule", "{experiment_id}" ],
            [ {}, "_plugins", "_search_relevance", "experiments", "schedule" ]
        ],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'search_relevance.get_search_configurations' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/',
        method  => 'GET',
        parts   => { search_configuration_id => {}},
        paths   => [
            [ { search_configuration_id => 3 }, "_plugins", "_search_relevance", "search_configurations", "{search_configuration_id}" ],
            [ {}, "_plugins", "_search_relevance", "search_configurations" ]
        ],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'search_relevance.get_stats' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/',
        method  => 'GET',
        parts   => { stat => {}},
        paths   => [
            [ { stat => 3 }, "_plugins", "_search_relevance", "stats", "{stat}" ],
            [ {}, "_plugins", "_search_relevance", "stats" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'flat_stat_paths'           => 'string',
            'include_all_nodes'         => 'string',
            'include_individual_nodes'  => 'string',
            'include_info'              => 'string',
            'include_metadata'          => 'string',
             # Common API query parameters
            'error_trace'               => 'boolean',
            'filter_path'               => 'list',
            'human'                     => 'boolean',
            'pretty'                    => 'boolean',
            'source'                    => 'string',
        },
    },

    'search_relevance.post_query_sets' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_search_relevance", "query_sets" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'search_relevance.post_scheduled_experiments' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_search_relevance", "experiments", "schedule" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'search_relevance.put_experiments' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/',
        method  => 'PUT',
        parts   => {},
        paths   => [[ {}, "_plugins", "_search_relevance", "experiments" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'search_relevance.put_judgments' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/',
        method  => 'PUT',
        parts   => {},
        paths   => [[ {}, "_plugins", "_search_relevance", "judgments" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'search_relevance.put_query_sets' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/',
        method  => 'PUT',
        parts   => {},
        paths   => [[ {}, "_plugins", "_search_relevance", "query_sets" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'search_relevance.put_search_configurations' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/',
        method  => 'PUT',
        parts   => {},
        paths   => [[ {}, "_plugins", "_search_relevance", "search_configurations" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.authinfo' => {
        doc     => 'https://docs.opensearch.org/latest/security/access-control/api/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "authinfo" ]],
        qs      => {
             # Endpoint specific query parameters
            'auth_type'    => 'string',
            'verbose'      => 'boolean',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.authtoken' => {
        doc     => 'https://docs.opensearch.org/latest/security/access-control/api/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "authtoken" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.change_password' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#change-password',
        method  => 'PUT',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "account" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.config_upgrade_check' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#configuration-upgrade-check',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "_upgrade_check" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.config_upgrade_perform' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#configuration-upgrade',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "_upgrade_perform" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.create_action_group' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#create-action-group',
        method  => 'PUT',
        parts   => { action_group => {  required => 1 }},
        paths   => [[ { action_group => 4 }, "_plugins", "_security", "api", "actiongroups", "{action_group}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.create_allowlist' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#access-control-for-the-api',
        method  => 'PUT',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "allowlist" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.create_role' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#create-role',
        method  => 'PUT',
        parts   => { role => {  required => 1 }},
        paths   => [[ { role => 4 }, "_plugins", "_security", "api", "roles", "{role}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.create_role_mapping' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#create-role-mapping',
        method  => 'PUT',
        parts   => { role => {  required => 1 }},
        paths   => [[ { role => 4 }, "_plugins", "_security", "api", "rolesmapping", "{role}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.create_tenant' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#create-tenant',
        method  => 'PUT',
        parts   => { tenant => {  required => 1 }},
        paths   => [[ { tenant => 4 }, "_plugins", "_security", "api", "tenants", "{tenant}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.create_update_tenancy_config' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/multi-tenancy/dynamic-config/#configuring-multi-tenancy-with-the-rest-api',
        method  => 'PUT',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "tenancy", "config" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.create_user' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#create-user',
        method  => 'PUT',
        parts   => { username => {  required => 1 }},
        paths   => [[ { username => 4 }, "_plugins", "_security", "api", "internalusers", "{username}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.create_user_legacy' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/security/access-control/api/',
        method  => 'PUT',
        parts   => { username => {  required => 1 }},
        paths   => [[ { username => 4 }, "_plugins", "_security", "api", "user", "{username}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.delete_action_group' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#delete-action-group',
        method  => 'DELETE',
        parts   => { action_group => {  required => 1 }},
        paths   => [[ { action_group => 4 }, "_plugins", "_security", "api", "actiongroups", "{action_group}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.delete_distinguished_name' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#delete-distinguished-names',
        method  => 'DELETE',
        parts   => { cluster_name => {  required => 1 }},
        paths   => [[ { cluster_name => 4 }, "_plugins", "_security", "api", "nodesdn", "{cluster_name}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.delete_role' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#delete-role',
        method  => 'DELETE',
        parts   => { role => {  required => 1 }},
        paths   => [[ { role => 4 }, "_plugins", "_security", "api", "roles", "{role}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.delete_role_mapping' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#delete-role-mapping',
        method  => 'DELETE',
        parts   => { role => {  required => 1 }},
        paths   => [[ { role => 4 }, "_plugins", "_security", "api", "rolesmapping", "{role}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.delete_tenant' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#delete-action-group',
        method  => 'DELETE',
        parts   => { tenant => {  required => 1 }},
        paths   => [[ { tenant => 4 }, "_plugins", "_security", "api", "tenants", "{tenant}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.delete_user' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#delete-user',
        method  => 'DELETE',
        parts   => { username => {  required => 1 }},
        paths   => [[ { username => 4 }, "_plugins", "_security", "api", "internalusers", "{username}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.delete_user_legacy' => {
        doc     => 'https://docs.opensearch.org/latest/security/access-control/api/',
        method  => 'DELETE',
        parts   => { username => {  required => 1 }},
        paths   => [[ { username => 4 }, "_plugins", "_security", "api", "user", "{username}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.flush_cache' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#flush-cache',
        method  => 'DELETE',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "cache" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.generate_obo_token' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/authentication-tokens/#api-endpoint',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "generateonbehalfoftoken" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.generate_user_token' => {
        doc     => 'https://docs.opensearch.org/latest/security/access-control/api/',
        method  => 'POST',
        parts   => { username => {  required => 1 }},
        paths   => [[ { username => 4 }, "_plugins", "_security", "api", "internalusers", "{username}", "authtoken" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.generate_user_token_legacy' => {
        doc     => 'https://docs.opensearch.org/latest/security/access-control/api/',
        method  => 'POST',
        parts   => { username => {  required => 1 }},
        paths   => [[ { username => 4 }, "_plugins", "_security", "api", "user", "{username}", "authtoken" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_account_details' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#get-account-details',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "account" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_action_group' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#get-action-group',
        method  => 'GET',
        parts   => { action_group => {  required => 1 }},
        paths   => [[ { action_group => 4 }, "_plugins", "_security", "api", "actiongroups", "{action_group}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_action_groups' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#get-action-groups',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "actiongroups" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_all_certificates' => {
        doc     => 'https://docs.opensearch.org/latest/security/access-control/api/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "certificates" ]],
        qs      => {
             # Endpoint specific query parameters
            'cert_type'    => 'string',
            'timeout'      => 'string',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_allowlist' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#access-control-for-the-api',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "allowlist" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_audit_configuration' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#audit-logs',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "audit" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_certificates' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#get-certificates',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "ssl", "certs" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_configuration' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#get-configuration',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "securityconfig" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_dashboards_info' => {
        doc     => 'https://docs.opensearch.org/latest/security/access-control/api/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "dashboardsinfo" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_distinguished_name' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#get-distinguished-names',
        method  => 'GET',
        parts   => { cluster_name => {  required => 1 }},
        paths   => [[ { cluster_name => 4 }, "_plugins", "_security", "api", "nodesdn", "{cluster_name}" ]],
        qs      => {
             # Endpoint specific query parameters
            'show_all'     => 'boolean',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_distinguished_names' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#get-distinguished-names',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "nodesdn" ]],
        qs      => {
             # Endpoint specific query parameters
            'show_all'     => 'boolean',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_node_certificates' => {
        doc     => 'https://docs.opensearch.org/latest/security/access-control/api/',
        method  => 'GET',
        parts   => { node_id => {  required => 1 }},
        paths   => [[ { node_id => 4 }, "_plugins", "_security", "api", "certificates", "{node_id}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cert_type'    => 'string',
            'timeout'      => 'string',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_permissions_info' => {
        doc     => 'https://docs.opensearch.org/latest/security/access-control/api/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "permissionsinfo" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_role' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#get-role',
        method  => 'GET',
        parts   => { role => {  required => 1 }},
        paths   => [[ { role => 4 }, "_plugins", "_security", "api", "roles", "{role}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_role_mapping' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#get-role-mapping',
        method  => 'GET',
        parts   => { role => {  required => 1 }},
        paths   => [[ { role => 4 }, "_plugins", "_security", "api", "rolesmapping", "{role}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_role_mappings' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#get-role-mappings',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "rolesmapping" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_roles' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#get-roles',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "roles" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_sslinfo' => {
        doc     => 'https://docs.opensearch.org/latest/security/access-control/api/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_opendistro", "_security", "sslinfo" ]],
        qs      => {
             # Endpoint specific query parameters
            'show_dn'      => 'boolean',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_tenancy_config' => {
        doc     => 'https://opensearch.org/docs/latest/security/multi-tenancy/dynamic-config/#configuring-multi-tenancy-with-the-rest-api',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "tenancy", "config" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_tenant' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#get-tenant',
        method  => 'GET',
        parts   => { tenant => {  required => 1 }},
        paths   => [[ { tenant => 4 }, "_plugins", "_security", "api", "tenants", "{tenant}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_tenants' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#get-tenants',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "tenants" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_user' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#get-user',
        method  => 'GET',
        parts   => { username => {  required => 1 }},
        paths   => [[ { username => 4 }, "_plugins", "_security", "api", "internalusers", "{username}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_user_legacy' => {
        doc     => 'https://docs.opensearch.org/latest/security/access-control/api/',
        method  => 'GET',
        parts   => { username => {  required => 1 }},
        paths   => [[ { username => 4 }, "_plugins", "_security", "api", "user", "{username}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_users' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#get-users',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "internalusers" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.get_users_legacy' => {
        doc     => 'https://docs.opensearch.org/latest/security/access-control/api/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "user" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.health' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#health-check',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "health" ]],
        qs      => {
             # Endpoint specific query parameters
            'mode'         => 'string',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.migrate' => {
        doc     => 'https://docs.opensearch.org/latest/security/access-control/api/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "migrate" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.patch_action_group' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#patch-action-group',
        method  => 'PATCH',
        parts   => { action_group => {  required => 1 }},
        paths   => [[ { action_group => 4 }, "_plugins", "_security", "api", "actiongroups", "{action_group}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.patch_action_groups' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#patch-action-groups',
        method  => 'PATCH',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "actiongroups" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.patch_allowlist' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#access-control-for-the-api',
        method  => 'PATCH',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "allowlist" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.patch_audit_configuration' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#audit-logs',
        method  => 'PATCH',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "audit" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.patch_configuration' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#patch-configuration',
        method  => 'PATCH',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "securityconfig" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.patch_distinguished_name' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/security/access-control/api/',
        method  => 'PATCH',
        parts   => { cluster_name => {  required => 1 }},
        paths   => [[ { cluster_name => 4 }, "_plugins", "_security", "api", "nodesdn", "{cluster_name}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.patch_distinguished_names' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#update-all-distinguished-names',
        method  => 'PATCH',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "nodesdn" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.patch_role' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#patch-role',
        method  => 'PATCH',
        parts   => { role => {  required => 1 }},
        paths   => [[ { role => 4 }, "_plugins", "_security", "api", "roles", "{role}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.patch_role_mapping' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#patch-role-mapping',
        method  => 'PATCH',
        parts   => { role => {  required => 1 }},
        paths   => [[ { role => 4 }, "_plugins", "_security", "api", "rolesmapping", "{role}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.patch_role_mappings' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#patch-role-mappings',
        method  => 'PATCH',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "rolesmapping" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.patch_roles' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#patch-roles',
        method  => 'PATCH',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "roles" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.patch_tenant' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#patch-tenant',
        method  => 'PATCH',
        parts   => { tenant => {  required => 1 }},
        paths   => [[ { tenant => 4 }, "_plugins", "_security", "api", "tenants", "{tenant}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.patch_tenants' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#patch-tenants',
        method  => 'PATCH',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "tenants" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.patch_user' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#patch-user',
        method  => 'PATCH',
        parts   => { username => {  required => 1 }},
        paths   => [[ { username => 4 }, "_plugins", "_security", "api", "internalusers", "{username}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.patch_users' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#patch-users',
        method  => 'PATCH',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "internalusers" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.post_dashboards_info' => {
        doc     => 'https://docs.opensearch.org/latest/security/access-control/api/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "dashboardsinfo" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.reload_http_certificates' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#reload-http-certificates',
        method  => 'PUT',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "ssl", "http", "reloadcerts" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.reload_transport_certificates' => {
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#reload-transport-certificates',
        method  => 'PUT',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "ssl", "transport", "reloadcerts" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.tenant_info' => {
        doc     => 'https://docs.opensearch.org/latest/security/access-control/api/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "tenantinfo" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.update_audit_configuration' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#audit-logs',
        method  => 'PUT',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "audit", "config" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.update_configuration' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#update-configuration',
        method  => 'PUT',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "securityconfig", "config" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.update_distinguished_name' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/security/access-control/api/#update-distinguished-names',
        method  => 'PUT',
        parts   => { cluster_name => {  required => 1 }},
        paths   => [[ { cluster_name => 4 }, "_plugins", "_security", "api", "nodesdn", "{cluster_name}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.validate' => {
        doc     => 'https://docs.opensearch.org/latest/security/access-control/api/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "api", "validate" ]],
        qs      => {
             # Endpoint specific query parameters
            'accept_invalid'  => 'boolean',
             # Common API query parameters
            'error_trace'     => 'boolean',
            'filter_path'     => 'list',
            'human'           => 'boolean',
            'pretty'          => 'boolean',
            'source'          => 'string',
        },
    },

    'security.who_am_i' => {
        doc     => 'https://docs.opensearch.org/latest/security/access-control/api/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "whoami" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security.who_am_i_protected' => {
        doc     => 'https://docs.opensearch.org/latest/security/access-control/api/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security", "whoamiprotected" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'security_analytics.get_alerts' => {
        doc     => 'https://docs.opensearch.org/docs/latest/security-analytics/api-tools/alert-finding-api/#get-alerts',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security_analytics", "alerts" ]],
        qs      => {
             # Endpoint specific query parameters
            'alertState'     => 'string',
            'detectorType'   => 'string',
            'detector_id'    => 'string',
            'endTime'        => 'number',
            'missing'        => 'string',
            'searchString'   => 'string',
            'severityLevel'  => 'string',
            'size'           => 'number',
            'sortOrder'      => 'string',
            'sortString'     => 'string',
            'startIndex'     => 'number',
            'startTime'      => 'number',
             # Common API query parameters
            'error_trace'    => 'boolean',
            'filter_path'    => 'list',
            'human'          => 'boolean',
            'pretty'         => 'boolean',
            'source'         => 'string',
        },
    },

    'security_analytics.get_findings' => {
        doc     => 'https://docs.opensearch.org/docs/latest/security-analytics/api-tools/alert-finding-api/#get-findings',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security_analytics", "findings", "_search" ]],
        qs      => {
             # Endpoint specific query parameters
            'detectionType'  => 'string',
            'detectorType'   => 'string',
            'detector_id'    => 'string',
            'endTime'        => 'string',
            'findingIds'     => 'string',
            'missing'        => 'string',
            'searchString'   => 'string',
            'severity'       => 'string',
            'size'           => 'number',
            'sortOrder'      => 'string',
            'sortString'     => 'string',
            'startIndex'     => 'number',
            'startTime'      => 'number',
             # Common API query parameters
            'error_trace'    => 'boolean',
            'filter_path'    => 'list',
            'human'          => 'boolean',
            'pretty'         => 'boolean',
            'source'         => 'string',
        },
    },

    'security_analytics.search_finding_correlations' => {
        doc     => 'https://docs.opensearch.org/docs/latest/security-analytics/api-tools/correlation-eng/#list-correlations-for-a-finding-belonging-to-a-log-type',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_security_analytics", "findings", "correlate" ]],
        qs      => {
             # Endpoint specific query parameters
            'detector_type'    => 'string',
            'finding'          => 'string',
            'nearby_findings'  => 'number',
            'time_window'      => 'number',
             # Common API query parameters
            'error_trace'      => 'boolean',
            'filter_path'      => 'list',
            'human'            => 'boolean',
            'pretty'           => 'boolean',
            'source'           => 'string',
        },
    },

    'sm.create_policy' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/tuning-your-cluster/availability-and-recovery/snapshots/sm-api/',
        method  => 'POST',
        parts   => { policy_name => {  required => 1 }},
        paths   => [[ { policy_name => 3 }, "_plugins", "_sm", "policies", "{policy_name}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'sm.delete_policy' => {
        doc     => 'https://docs.opensearch.org/latest/tuning-your-cluster/availability-and-recovery/snapshots/sm-api/',
        method  => 'DELETE',
        parts   => { policy_name => {  required => 1 }},
        paths   => [[ { policy_name => 3 }, "_plugins", "_sm", "policies", "{policy_name}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'sm.explain_policy' => {
        doc     => 'https://docs.opensearch.org/latest/tuning-your-cluster/availability-and-recovery/snapshots/sm-api/',
        method  => 'GET',
        parts   => { policy_name => {  required => 1 }},
        paths   => [[ { policy_name => 3 }, "_plugins", "_sm", "policies", "{policy_name}", "_explain" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'sm.get_policies' => {
        doc     => 'https://docs.opensearch.org/latest/tuning-your-cluster/availability-and-recovery/snapshots/sm-api/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_sm", "policies" ]],
        qs      => {
             # Endpoint specific query parameters
            'from'         => 'number',
            'queryString'  => 'string',
            'size'         => 'number',
            'sortField'    => 'string',
            'sortOrder'    => 'string',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'sm.get_policy' => {
        doc     => 'https://docs.opensearch.org/latest/tuning-your-cluster/availability-and-recovery/snapshots/sm-api/',
        method  => 'GET',
        parts   => { policy_name => {  required => 1 }},
        paths   => [[ { policy_name => 3 }, "_plugins", "_sm", "policies", "{policy_name}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'sm.start_policy' => {
        doc     => 'https://docs.opensearch.org/latest/tuning-your-cluster/availability-and-recovery/snapshots/sm-api/',
        method  => 'POST',
        parts   => { policy_name => {  required => 1 }},
        paths   => [[ { policy_name => 3 }, "_plugins", "_sm", "policies", "{policy_name}", "_start" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'sm.stop_policy' => {
        doc     => 'https://docs.opensearch.org/latest/tuning-your-cluster/availability-and-recovery/snapshots/sm-api/',
        method  => 'POST',
        parts   => { policy_name => {  required => 1 }},
        paths   => [[ { policy_name => 3 }, "_plugins", "_sm", "policies", "{policy_name}", "_stop" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'sm.update_policy' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/tuning-your-cluster/availability-and-recovery/snapshots/sm-api/',
        method  => 'PUT',
        parts   => { policy_name => {  required => 1 }},
        paths   => [[ { policy_name => 3 }, "_plugins", "_sm", "policies", "{policy_name}" ]],
        qs      => {
             # Endpoint specific query parameters
            'if_primary_term'  => 'number',
            'if_seq_no'        => 'number',
             # Common API query parameters
            'error_trace'      => 'boolean',
            'filter_path'      => 'list',
            'human'            => 'boolean',
            'pretty'           => 'boolean',
            'source'           => 'string',
        },
    },

    'snapshot.cleanup_repository' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/snapshots/index/',
        method  => 'POST',
        parts   => { repository => {  required => 1 }},
        paths   => [[ { repository => 1 }, "_snapshot", "{repository}", "_cleanup" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'snapshot.clone' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/api-reference/snapshots/index/',
        method  => 'PUT',
        parts   => { repository => {  required => 1 }, snapshot => {  required => 1 }, target_snapshot => {  required => 1 }},
        paths   => [[ { repository => 1, snapshot => 2, target_snapshot => 4 }, "_snapshot", "{repository}", "{snapshot}", "_clone", "{target_snapshot}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'master_timeout'           => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'snapshot.create' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/snapshots/create-snapshot/',
        ## ENDPOINT HAS ALTERNATE METHOD
        method  => 'detect',
        detect  => { method => 'POST', alternate => 'PUT', check => { body => 1, paths => 0 } },
        parts   => { repository => {  required => 1 }, snapshot => {  required => 1 }},
        paths   => [[ { repository => 1, snapshot => 2 }, "_snapshot", "{repository}", "{snapshot}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'master_timeout'           => 'string',
            'wait_for_completion'      => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'snapshot.create_repository' => {
        body    => { required => 1 },
        doc     => 'https://opensearch.org/docs/latest/api-reference/snapshots/create-repository/',
        method  => 'PUT',
        parts   => { repository => {  required => 1 }},
        paths   => [[ { repository => 1 }, "_snapshot", "{repository}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
            'verify'                   => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'snapshot.delete' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/snapshots/delete-snapshot/',
        method  => 'DELETE',
        parts   => { repository => {  required => 1 }, snapshot => {  required => 1 }},
        paths   => [[ { repository => 1, snapshot => 2 }, "_snapshot", "{repository}", "{snapshot}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'master_timeout'           => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'snapshot.delete_repository' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/snapshots/delete-snapshot-repository/',
        method  => 'DELETE',
        parts   => { repository => {  multi => 1,  required => 1 }},
        paths   => [[ { repository => 1 }, "_snapshot", "{repository}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'snapshot.get' => {
        doc     => 'https://docs.opensearch.org/latest/api-reference/snapshots/index/',
        method  => 'GET',
        parts   => { repository => {  required => 1 }, snapshot => {  multi => 1,  required => 1 }},
        paths   => [[ { repository => 1, snapshot => 2 }, "_snapshot", "{repository}", "{snapshot}" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'ignore_unavailable'       => 'boolean',
            'master_timeout'           => 'string',
            'verbose'                  => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'snapshot.get_repository' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/snapshots/get-snapshot-repository/',
        method  => 'GET',
        parts   => { repository => {  multi => 1 }},
        paths   => [
            [ { repository => 1 }, "_snapshot", "{repository}" ],
            [ {}, "_snapshot" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'local'                    => 'boolean',
            'master_timeout'           => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'snapshot.restore' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/api-reference/snapshots/restore-snapshot/',
        method  => 'POST',
        parts   => { repository => {  required => 1 }, snapshot => {  required => 1 }},
        paths   => [[ { repository => 1, snapshot => 2 }, "_snapshot", "{repository}", "{snapshot}", "_restore" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'master_timeout'           => 'string',
            'wait_for_completion'      => 'boolean',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'snapshot.status' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/snapshots/get-snapshot-status/',
        method  => 'GET',
        parts   => { repository => {}, snapshot => {  multi => 1 }},
        paths   => [
            [ { repository => 1, snapshot => 2 }, "_snapshot", "{repository}", "{snapshot}", "_status" ],
            [ { repository => 1 }, "_snapshot", "{repository}", "_status" ],
            [ {}, "_snapshot", "_status" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'ignore_unavailable'       => 'boolean',
            'master_timeout'           => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'snapshot.verify_repository' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/snapshots/verify-snapshot-repository/',
        method  => 'POST',
        parts   => { repository => {  required => 1 }},
        paths   => [[ { repository => 1 }, "_snapshot", "{repository}", "_verify" ]],
        qs      => {
             # Endpoint specific query parameters
            'cluster_manager_timeout'  => 'string',
            'master_timeout'           => 'string',
            'timeout'                  => 'string',
             # Common API query parameters
            'error_trace'              => 'boolean',
            'filter_path'              => 'list',
            'human'                    => 'boolean',
            'pretty'                   => 'boolean',
            'source'                   => 'string',
        },
    },

    'sql.close' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/search-plugins/sql/sql-ppl-api/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_sql", "close" ]],
        qs      => {
             # Endpoint specific query parameters
            'format'       => 'string',
            'sanitize'     => 'boolean',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'sql.explain' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/search-plugins/sql/sql-ppl-api/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_sql", "_explain" ]],
        qs      => {
             # Endpoint specific query parameters
            'format'       => 'string',
            'sanitize'     => 'boolean',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'sql.get_stats' => {
        doc     => 'https://opensearch.org/docs/latest/search-plugins/sql/monitoring/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_sql", "stats" ]],
        qs      => {
             # Endpoint specific query parameters
            'format'       => 'string',
            'sanitize'     => 'boolean',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'sql.post_stats' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/search-plugins/sql/monitoring/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_sql", "stats" ]],
        qs      => {
             # Endpoint specific query parameters
            'format'       => 'string',
            'sanitize'     => 'boolean',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'sql.query' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/search-plugins/sql/sql-ppl-api/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_sql" ]],
        qs      => {
             # Endpoint specific query parameters
            'format'       => 'string',
            'sanitize'     => 'boolean',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'sql.settings' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/search-plugins/sql/settings/',
        method  => 'PUT',
        parts   => {},
        paths   => [[ {}, "_plugins", "_query", "settings" ]],
        qs      => {
             # Endpoint specific query parameters
            'format'       => 'string',
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'tasks.cancel' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/tasks/#task-canceling',
        method  => 'POST',
        parts   => { task_id => {}},
        paths   => [
            [ { task_id => 1 }, "_tasks", "{task_id}", "_cancel" ],
            [ {}, "_tasks", "_cancel" ]
        ],
        qs      => {
             # Endpoint specific query parameters
            'actions'              => 'list',
            'nodes'                => 'list',
            'parent_task_id'       => 'string',
            'wait_for_completion'  => 'boolean',
             # Common API query parameters
            'error_trace'          => 'boolean',
            'filter_path'          => 'list',
            'human'                => 'boolean',
            'pretty'               => 'boolean',
            'source'               => 'string',
        },
    },

    'tasks.get' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/tasks/',
        method  => 'GET',
        parts   => { task_id => {  required => 1 }},
        paths   => [[ { task_id => 1 }, "_tasks", "{task_id}" ]],
        qs      => {
             # Endpoint specific query parameters
            'timeout'              => 'string',
            'wait_for_completion'  => 'boolean',
             # Common API query parameters
            'error_trace'          => 'boolean',
            'filter_path'          => 'list',
            'human'                => 'boolean',
            'pretty'               => 'boolean',
            'source'               => 'string',
        },
    },

    'tasks.list' => {
        doc     => 'https://opensearch.org/docs/latest/api-reference/tasks/',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_tasks" ]],
        qs      => {
             # Endpoint specific query parameters
            'actions'              => 'list',
            'detailed'             => 'boolean',
            'group_by'             => 'string',
            'nodes'                => 'list',
            'parent_task_id'       => 'string',
            'timeout'              => 'string',
            'wait_for_completion'  => 'boolean',
             # Common API query parameters
            'error_trace'          => 'boolean',
            'filter_path'          => 'list',
            'human'                => 'boolean',
            'pretty'               => 'boolean',
            'source'               => 'string',
        },
    },

    'transforms.delete' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/index-transforms/transforms-apis/#delete-a-transform-job',
        method  => 'DELETE',
        parts   => { id => {  required => 1 }},
        paths   => [[ { id => 2 }, "_plugins", "_transform", "{id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'transforms.explain' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/index-transforms/transforms-apis/#get-the-status-of-a-transform-job',
        method  => 'GET',
        parts   => { id => {  required => 1 }},
        paths   => [[ { id => 2 }, "_plugins", "_transform", "{id}", "_explain" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'transforms.get' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/index-transforms/transforms-apis/#get-a-transform-jobs-details',
        method  => 'GET',
        parts   => { id => {  required => 1 }},
        paths   => [[ { id => 2 }, "_plugins", "_transform", "{id}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'transforms.preview' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/im-plugin/index-transforms/transforms-apis/#preview-a-transform-jobs-results',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "_transform", "_preview" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'transforms.put' => {
        body    => {},
        doc     => 'https://opensearch.org/docs/latest/im-plugin/index-transforms/transforms-apis/#create-a-transform-job',
        method  => 'PUT',
        parts   => { id => {  required => 1 }},
        paths   => [[ { id => 2 }, "_plugins", "_transform", "{id}" ]],
        qs      => {
             # Endpoint specific query parameters
            'if_primary_term'  => 'number',
            'if_seq_no'        => 'number',
             # Common API query parameters
            'error_trace'      => 'boolean',
            'filter_path'      => 'list',
            'human'            => 'boolean',
            'pretty'           => 'boolean',
            'source'           => 'string',
        },
    },

    'transforms.search' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/index-transforms/transforms-apis/#get-a-transform-jobs-details',
        method  => 'GET',
        parts   => {},
        paths   => [[ {}, "_plugins", "_transform" ]],
        qs      => {
             # Endpoint specific query parameters
            'from'           => 'number',
            'search'         => 'string',
            'size'           => 'number',
            'sortDirection'  => 'string',
            'sortField'      => 'string',
             # Common API query parameters
            'error_trace'    => 'boolean',
            'filter_path'    => 'list',
            'human'          => 'boolean',
            'pretty'         => 'boolean',
            'source'         => 'string',
        },
    },

    'transforms.start' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/index-transforms/transforms-apis/#start-a-transform-job',
        method  => 'POST',
        parts   => { id => {  required => 1 }},
        paths   => [[ { id => 2 }, "_plugins", "_transform", "{id}", "_start" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'transforms.stop' => {
        doc     => 'https://opensearch.org/docs/latest/im-plugin/index-transforms/transforms-apis/#stop-a-transform-job',
        method  => 'POST',
        parts   => { id => {  required => 1 }},
        paths   => [[ { id => 2 }, "_plugins", "_transform", "{id}", "_stop" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'ubi.initialize' => {
        doc     => 'https://docs.opensearch.org/latest/search-plugins/ubi/index/',
        method  => 'POST',
        parts   => {},
        paths   => [[ {}, "_plugins", "ubi", "initialize" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'wlm.create_query_group' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/tuning-your-cluster/availability-and-recovery/workload-management/wlm-feature-overview/',
        method  => 'PUT',
        parts   => {},
        paths   => [[ {}, "_wlm", "query_group" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'wlm.delete_query_group' => {
        doc     => 'https://docs.opensearch.org/latest/tuning-your-cluster/availability-and-recovery/workload-management/wlm-feature-overview/',
        method  => 'DELETE',
        parts   => { name => {  required => 1 }},
        paths   => [[ { name => 2 }, "_wlm", "query_group", "{name}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'wlm.get_query_group' => {
        doc     => 'https://docs.opensearch.org/latest/tuning-your-cluster/availability-and-recovery/workload-management/wlm-feature-overview/',
        method  => 'GET',
        parts   => { name => {}},
        paths   => [
            [ { name => 2 }, "_wlm", "query_group", "{name}" ],
            [ {}, "_wlm", "query_group" ]
        ],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

    'wlm.update_query_group' => {
        body    => {},
        doc     => 'https://docs.opensearch.org/latest/tuning-your-cluster/availability-and-recovery/workload-management/wlm-feature-overview/',
        method  => 'PUT',
        parts   => { name => {  required => 1 }},
        paths   => [[ { name => 2 }, "_wlm", "query_group", "{name}" ]],
        qs      => {
             # Common API query parameters
            'error_trace'  => 'boolean',
            'filter_path'  => 'list',
            'human'        => 'boolean',
            'pretty'       => 'boolean',
            'source'       => 'string',
        },
    },

);

__PACKAGE__->_qs_init( \%API );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSearch::Client::Core::3_0::Role::API

=head1 VERSION

version 3.007002

=head1 DESCRIPTION

Provides the API for all modules in the OpenSearch::Client::Core::3_0::Direct:: namspace.

=head1 MANUAL

Documentation index L<OpenSearch::Client::Manual>

=head1 HISTORY

This distribution is derived from L<Search::Elasticsearch> version 7.714.
All subsequent changes are unique to this distribution.

=head1 AUTHOR

Mark Dootson E<lt>mdootson@cpan.orgE<gt> ( current maintainer )

=head1 CREDITS

L<OpenSearch::Client> is based on L<Search::Elasticsearch> version 7.714
by Enrico Zimuel E<lt>enrico.zimuel@elastic.coE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Mark Dootson ( this distribution )

Copyright (C) 2021 by Elasticsearch BV ( original distribution ) 

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004


=cut

