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

package OpenSearch::Client::Core::3_0::Direct::KNN;
$OpenSearch::Client::Core::3_0::Direct::KNN::VERSION = '3.007008';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('knn');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::KNN>

=head1 VERSION

version 3.007008

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->knn-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Vector search API>


In OpenSearch, vector search functionality is provided by the k-NN plugin and Neural Search plugin. The k-NN plugin provides basic k-NN functionality, while the Neural Search plugin provides automatic embedding generation at indexing and search time.

L<See OpenSearch documentation for knn.|https://docs.opensearch.org/latest/vector-search/api/index/>

=head1 METHODS
    
=head2 delete_model

Used to delete a particular model in the cluster.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_knn/models/{model_id}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->knn->delete_model(
        
         # path parameters
        
        'model_id'     =>  $model_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for knn-E<gt>delete_model|https://docs.opensearch.org/latest/vector-search/api/knn/#delete-a-model>
    
=head2 get_model

Used to retrieve information about models present in the cluster.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_knn/models/{model_id}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->knn->get_model(
        
         # path parameters
        
        'model_id'     =>  $model_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for knn-E<gt>get_model|https://docs.opensearch.org/latest/vector-search/api/knn/#get-a-model>
    
=head2 search_models

Use an OpenSearch query to search for models in the index.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_knn/models/_search>

=item
C<POST /_plugins/_knn/models/_search>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->knn->search_models(
        
        'body'                           =>  $body,      # optional
        
         # Endpoint specific query string parameters
        
        '_source'                        =>  $qval1,     # list
        '_source_excludes'               =>  $qval2,     # list
        '_source_includes'               =>  $qval3,     # list
        'allow_no_indices'               =>  $qval4,     # boolean
        'allow_partial_search_results'   =>  $qval5,     # boolean
        'analyze_wildcard'               =>  $qval6,     # boolean
        'analyzer'                       =>  $qval7,     # string
        'batched_reduce_size'            =>  $qval8,     # number
        'ccs_minimize_roundtrips'        =>  $qval9,     # boolean
        'default_operator'               =>  $qval10,    # string
        'df'                             =>  $qval11,    # string
        'docvalue_fields'                =>  $qval12,    # list
        'expand_wildcards'               =>  $qval13,    # list
        'explain'                        =>  $qval14,    # boolean
        'from'                           =>  $qval15,    # number
        'ignore_throttled'               =>  $qval16,    # boolean
        'ignore_unavailable'             =>  $qval17,    # boolean
        'lenient'                        =>  $qval18,    # boolean
        'max_concurrent_shard_requests'  =>  $qval19,    # number
        'pre_filter_shard_size'          =>  $qval20,    # number
        'preference'                     =>  $qval21,    # string
        'q'                              =>  $qval22,    # string
        'request_cache'                  =>  $qval23,    # boolean
        'rest_total_hits_as_int'         =>  $qval24,    # boolean
        'routing'                        =>  $qval25,    # list
        'scroll'                         =>  $qval26,    # string
        'search_type'                    =>  $qval27,    # string
        'seq_no_primary_term'            =>  $qval28,    # boolean
        'size'                           =>  $qval29,    # number
        'sort'                           =>  $qval30,    # list
        'stats'                          =>  $qval31,    # list
        'stored_fields'                  =>  $qval32,    # list
        'suggest_field'                  =>  $qval33,    # string
        'suggest_mode'                   =>  $qval34,    # string
        'suggest_size'                   =>  $qval35,    # number
        'suggest_text'                   =>  $qval36,    # string
        'terminate_after'                =>  $qval37,    # number
        'timeout'                        =>  $qval38,    # string
        'track_scores'                   =>  $qval39,    # boolean
        'track_total_hits'               =>  $qval40,    # boolean
        'typed_keys'                     =>  $qval41,    # boolean
        'version'                        =>  $qval42,    # boolean
        
         # Common API query string parameters
        
        'error_trace'                    =>  $qval43,    # boolean
        'filter_path'                    =>  $qval44,    # list
        'human'                          =>  $qval45,    # boolean
        'pretty'                         =>  $qval46,    # boolean
        'source'                         =>  $qval47,    # string
    );

L<OpenSearch documentation for knn-E<gt>search_models|https://docs.opensearch.org/latest/vector-search/api/knn/#search-for-a-model>
    
=head2 stats

Provides information about the current status of the k-NN plugin.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_knn/stats>

=item
C<GET /_plugins/_knn/stats/{stat}>

=item
C<GET /_plugins/_knn/{node_id}/stats>

=item
C<GET /_plugins/_knn/{node_id}/stats/{stat}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->knn->stats(
        
         # path parameters
        
        'node_id'      =>  $node_id,   # optional
        'stat'         =>  $stat,      # optional
        
         # Endpoint specific query string parameters
        
        'timeout'      =>  $qval1,     # string
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval2,     # boolean
        'filter_path'  =>  $qval3,     # list
        'human'        =>  $qval4,     # boolean
        'pretty'       =>  $qval5,     # boolean
        'source'       =>  $qval6,     # string
    );

L<OpenSearch documentation for knn-E<gt>stats|https://docs.opensearch.org/latest/vector-search/api/knn/#stats>
    
=head2 train_model

Create and train a model that can be used for initializing k-NN native library indexes during indexing.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_knn/models/_train>

=item
C<POST /_plugins/_knn/models/{model_id}/_train>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->knn->train_model(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'model_id'     =>  $model_id,  # optional
        
         # Endpoint specific query string parameters
        
        'preference'   =>  $qval1,     # string
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval2,     # boolean
        'filter_path'  =>  $qval3,     # list
        'human'        =>  $qval4,     # boolean
        'pretty'       =>  $qval5,     # boolean
        'source'       =>  $qval6,     # string
    );

L<OpenSearch documentation for knn-E<gt>train_model|https://docs.opensearch.org/latest/vector-search/api/knn/#train-a-model>
    
=head2 warmup

Preloads native library files into memory, reducing initial search latency for specified indexes.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_knn/warmup/{index}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->knn->warmup(
        
         # path parameters
        
        'index'        =>  $index,     # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for knn-E<gt>warmup|https://docs.opensearch.org/latest/vector-search/api/knn/#warmup-operation>

=head2 method_supported_in_version

Return whether a method in this module namespace is supported for an OpenSearch server version

    my $boolean = $os->knn->method_supported_in_version(
        method  => 'delete_model',
        version => '2.4.0'
    );

Both C<method> and C<version> are required.

See also L<global_method_supported_in_version|OpenSearch::Client::Core::3_0::Direct#global_method_supported_in_version>

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

