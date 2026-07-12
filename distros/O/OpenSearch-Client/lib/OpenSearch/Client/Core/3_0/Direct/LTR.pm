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

package OpenSearch::Client::Core::3_0::Direct::LTR;
$OpenSearch::Client::Core::3_0::Direct::LTR::VERSION = '3.007007';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('ltr');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::LTR>

=head1 VERSION

version 3.007007

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->ltr-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Learning to Rank>


The Learning to Rank plugin for OpenSearch enables you to use machine learning (ML) and behavioral data to fine-tune the relevance of documents. It uses models from the XGBoost and RankLib libraries. These models rescore the search results, considering query-dependent features such as click-through data or field matches, which can further improve relevance.

L<See OpenSearch documentation for ltr.|https://docs.opensearch.org/latest/search-plugins/ltr/index/>

=head1 METHODS
    
=head2 add_features_to_set

Add features to an existing feature set in the default feature store.

I<Paths served by this method:>

=over

=item
C<POST /_ltr/_featureset/{name}/_addfeatures>

=item
C<POST /_ltr/{store}/_featureset/{name}/_addfeatures>

=back

    $resp = $client->ltr->add_features_to_set(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'name'         =>  $name,      # required
        'store'        =>  $store,     # optional
        
         # Endpoint specific query string parameters
        
        'merge'        =>  $qval1,     # boolean
        'routing'      =>  $qval2,     # string
        'version'      =>  $qval3,     # number
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval4,     # boolean
        'filter_path'  =>  $qval5,     # list
        'human'        =>  $qval6,     # boolean
        'pretty'       =>  $qval7,     # boolean
        'source'       =>  $qval8,     # string
    );

L<OpenSearch documentation for ltr-E<gt>add_features_to_set|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 add_features_to_set_by_query

Add features to an existing feature set in the default feature store.

I<Paths served by this method:>

=over

=item
C<POST /_ltr/_featureset/{name}/_addfeatures/{query}>

=item
C<POST /_ltr/{store}/_featureset/{name}/_addfeatures/{query}>

=back

    $resp = $client->ltr->add_features_to_set_by_query(
        
         # path parameters
        
        'name'         =>  $name,      # required
        'query'        =>  $query,     # required
        'store'        =>  $store,     # optional
        
         # Endpoint specific query string parameters
        
        'merge'        =>  $qval1,     # boolean
        'routing'      =>  $qval2,     # string
        'version'      =>  $qval3,     # number
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval4,     # boolean
        'filter_path'  =>  $qval5,     # list
        'human'        =>  $qval6,     # boolean
        'pretty'       =>  $qval7,     # boolean
        'source'       =>  $qval8,     # string
    );

L<OpenSearch documentation for ltr-E<gt>add_features_to_set_by_query|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 cache_stats

Retrieves cache statistics for all feature stores.

I<Paths served by this method:>

=over

=item
C<GET /_ltr/_cachestats>

=back

    $resp = $client->ltr->cache_stats(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ltr-E<gt>cache_stats|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 clear_cache

Clears the store caches.

I<Paths served by this method:>

=over

=item
C<POST /_ltr/_clearcache>

=item
C<POST /_ltr/{store}/_clearcache>

=back

    $resp = $client->ltr->clear_cache(
        
         # path parameters
        
        'store'        =>  $store,     # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ltr-E<gt>clear_cache|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 create_default_store

Creates the default feature store.

I<Paths served by this method:>

=over

=item
C<PUT /_ltr>

=back

    $resp = $client->ltr->create_default_store(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ltr-E<gt>create_default_store|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 create_feature

Create or update a feature in the default feature store.

I<Paths served by this method:>

=over

=item
C<PUT /_ltr/_feature/{id}>

=item
C<PUT /_ltr/{store}/_feature/{id}>

=back

    $resp = $client->ltr->create_feature(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'id'           =>  $id,        # required
        'store'        =>  $store,     # optional
        
         # Endpoint specific query string parameters
        
        'routing'      =>  $qval1,     # string
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval2,     # boolean
        'filter_path'  =>  $qval3,     # list
        'human'        =>  $qval4,     # boolean
        'pretty'       =>  $qval5,     # boolean
        'source'       =>  $qval6,     # string
    );

L<OpenSearch documentation for ltr-E<gt>create_feature|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 create_featureset

Create or update a feature set in the default feature store.

I<Paths served by this method:>

=over

=item
C<PUT /_ltr/_featureset/{id}>

=item
C<PUT /_ltr/{store}/_featureset/{id}>

=back

    $resp = $client->ltr->create_featureset(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'id'           =>  $id,        # required
        'store'        =>  $store,     # optional
        
         # Endpoint specific query string parameters
        
        'routing'      =>  $qval1,     # string
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval2,     # boolean
        'filter_path'  =>  $qval3,     # list
        'human'        =>  $qval4,     # boolean
        'pretty'       =>  $qval5,     # boolean
        'source'       =>  $qval6,     # string
    );

L<OpenSearch documentation for ltr-E<gt>create_featureset|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 create_model

Create or update a model in the default feature store.

I<Paths served by this method:>

=over

=item
C<PUT /_ltr/_model/{id}>

=item
C<PUT /_ltr/{store}/_model/{id}>

=back

    $resp = $client->ltr->create_model(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'id'           =>  $id,        # required
        'store'        =>  $store,     # optional
        
         # Endpoint specific query string parameters
        
        'routing'      =>  $qval1,     # string
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval2,     # boolean
        'filter_path'  =>  $qval3,     # list
        'human'        =>  $qval4,     # boolean
        'pretty'       =>  $qval5,     # boolean
        'source'       =>  $qval6,     # string
    );

L<OpenSearch documentation for ltr-E<gt>create_model|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 create_model_from_set

Create a model from an existing feature set in the default feature store.

I<Paths served by this method:>

=over

=item
C<POST /_ltr/_featureset/{name}/_createmodel>

=item
C<POST /_ltr/{store}/_featureset/{name}/_createmodel>

=back

    $resp = $client->ltr->create_model_from_set(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'name'         =>  $name,      # required
        'store'        =>  $store,     # optional
        
         # Endpoint specific query string parameters
        
        'routing'      =>  $qval1,     # string
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval2,     # boolean
        'filter_path'  =>  $qval3,     # list
        'human'        =>  $qval4,     # boolean
        'pretty'       =>  $qval5,     # boolean
        'source'       =>  $qval6,     # string
    );

L<OpenSearch documentation for ltr-E<gt>create_model_from_set|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 create_store

Creates a new feature store with the specified name.

I<Paths served by this method:>

=over

=item
C<PUT /_ltr/{store}>

=back

    $resp = $client->ltr->create_store(
        
         # path parameters
        
        'store'        =>  $store,     # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ltr-E<gt>create_store|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 delete_default_store

Deletes the default feature store.

I<Paths served by this method:>

=over

=item
C<DELETE /_ltr>

=back

    $resp = $client->ltr->delete_default_store(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ltr-E<gt>delete_default_store|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 delete_feature

Delete a feature from the default feature store.

I<Paths served by this method:>

=over

=item
C<DELETE /_ltr/_feature/{id}>

=item
C<DELETE /_ltr/{store}/_feature/{id}>

=back

    $resp = $client->ltr->delete_feature(
        
         # path parameters
        
        'id'           =>  $id,        # required
        'store'        =>  $store,     # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ltr-E<gt>delete_feature|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 delete_featureset

Delete a feature set from the default feature store.

I<Paths served by this method:>

=over

=item
C<DELETE /_ltr/_featureset/{id}>

=item
C<DELETE /_ltr/{store}/_featureset/{id}>

=back

    $resp = $client->ltr->delete_featureset(
        
         # path parameters
        
        'id'           =>  $id,        # required
        'store'        =>  $store,     # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ltr-E<gt>delete_featureset|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 delete_model

Delete a model from the default feature store.

I<Paths served by this method:>

=over

=item
C<DELETE /_ltr/_model/{id}>

=item
C<DELETE /_ltr/{store}/_model/{id}>

=back

    $resp = $client->ltr->delete_model(
        
         # path parameters
        
        'id'           =>  $id,        # required
        'store'        =>  $store,     # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ltr-E<gt>delete_model|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 delete_store

Deletes a feature store with the specified name.

I<Paths served by this method:>

=over

=item
C<DELETE /_ltr/{store}>

=back

    $resp = $client->ltr->delete_store(
        
         # path parameters
        
        'store'        =>  $store,     # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ltr-E<gt>delete_store|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 get_feature

Get a feature from the default feature store.

I<Paths served by this method:>

=over

=item
C<GET /_ltr/_feature/{id}>

=item
C<GET /_ltr/{store}/_feature/{id}>

=back

    $resp = $client->ltr->get_feature(
        
         # path parameters
        
        'id'           =>  $id,        # required
        'store'        =>  $store,     # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ltr-E<gt>get_feature|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 get_featureset

Get a feature set from the default feature store.

I<Paths served by this method:>

=over

=item
C<GET /_ltr/_featureset/{id}>

=item
C<GET /_ltr/{store}/_featureset/{id}>

=back

    $resp = $client->ltr->get_featureset(
        
         # path parameters
        
        'id'           =>  $id,        # required
        'store'        =>  $store,     # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ltr-E<gt>get_featureset|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 get_model

Get a model from the default feature store.

I<Paths served by this method:>

=over

=item
C<GET /_ltr/_model/{id}>

=item
C<GET /_ltr/{store}/_model/{id}>

=back

    $resp = $client->ltr->get_model(
        
         # path parameters
        
        'id'           =>  $id,        # required
        'store'        =>  $store,     # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ltr-E<gt>get_model|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 get_store

Checks if a store exists.

I<Paths served by this method:>

=over

=item
C<GET /_ltr/{store}>

=back

    $resp = $client->ltr->get_store(
        
         # path parameters
        
        'store'        =>  $store,     # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ltr-E<gt>get_store|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 list_stores

Lists all available feature stores.

I<Paths served by this method:>

=over

=item
C<GET /_ltr>

=back

    $resp = $client->ltr->list_stores(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ltr-E<gt>list_stores|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 search_features

Search for features in a feature store.

I<Paths served by this method:>

=over

=item
C<GET /_ltr/_feature>

=item
C<GET /_ltr/{store}/_feature>

=back

    $resp = $client->ltr->search_features(
        
         # path parameters
        
        'store'        =>  $store,     # optional
        
         # Endpoint specific query string parameters
        
        'from'         =>  $qval1,     # number
        'prefix'       =>  $qval2,     # string
        'size'         =>  $qval3,     # number
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval4,     # boolean
        'filter_path'  =>  $qval5,     # list
        'human'        =>  $qval6,     # boolean
        'pretty'       =>  $qval7,     # boolean
        'source'       =>  $qval8,     # string
    );

L<OpenSearch documentation for ltr-E<gt>search_features|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 search_featuresets

Search for feature sets in a feature store.

I<Paths served by this method:>

=over

=item
C<GET /_ltr/_featureset>

=item
C<GET /_ltr/{store}/_featureset>

=back

    $resp = $client->ltr->search_featuresets(
        
         # path parameters
        
        'store'        =>  $store,     # optional
        
         # Endpoint specific query string parameters
        
        'from'         =>  $qval1,     # number
        'prefix'       =>  $qval2,     # string
        'size'         =>  $qval3,     # number
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval4,     # boolean
        'filter_path'  =>  $qval5,     # list
        'human'        =>  $qval6,     # boolean
        'pretty'       =>  $qval7,     # boolean
        'source'       =>  $qval8,     # string
    );

L<OpenSearch documentation for ltr-E<gt>search_featuresets|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 search_models

Search for models in a feature store.

I<Paths served by this method:>

=over

=item
C<GET /_ltr/_model>

=item
C<GET /_ltr/{store}/_model>

=back

    $resp = $client->ltr->search_models(
        
         # path parameters
        
        'store'        =>  $store,     # optional
        
         # Endpoint specific query string parameters
        
        'from'         =>  $qval1,     # number
        'prefix'       =>  $qval2,     # string
        'size'         =>  $qval3,     # number
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval4,     # boolean
        'filter_path'  =>  $qval5,     # list
        'human'        =>  $qval6,     # boolean
        'pretty'       =>  $qval7,     # boolean
        'source'       =>  $qval8,     # string
    );

L<OpenSearch documentation for ltr-E<gt>search_models|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 stats

Provides information about the current status of the LTR plugin.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ltr/stats>

=item
C<GET /_plugins/_ltr/stats/{stat}>

=item
C<GET /_plugins/_ltr/{node_id}/stats>

=item
C<GET /_plugins/_ltr/{node_id}/stats/{stat}>

=back

    $resp = $client->ltr->stats(
        
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

L<OpenSearch documentation for ltr-E<gt>stats|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 update_feature

Update a feature in the default feature store.

I<Paths served by this method:>

=over

=item
C<POST /_ltr/_feature/{id}>

=item
C<POST /_ltr/{store}/_feature/{id}>

=back

    $resp = $client->ltr->update_feature(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'id'           =>  $id,        # required
        'store'        =>  $store,     # optional
        
         # Endpoint specific query string parameters
        
        'routing'      =>  $qval1,     # string
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval2,     # boolean
        'filter_path'  =>  $qval3,     # list
        'human'        =>  $qval4,     # boolean
        'pretty'       =>  $qval5,     # boolean
        'source'       =>  $qval6,     # string
    );

L<OpenSearch documentation for ltr-E<gt>update_feature|https://docs.opensearch.org/latest/search-plugins/ltr/index/>
    
=head2 update_featureset

Update a feature set in the default feature store.

I<Paths served by this method:>

=over

=item
C<POST /_ltr/_featureset/{id}>

=item
C<POST /_ltr/{store}/_featureset/{id}>

=back

    $resp = $client->ltr->update_featureset(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'id'           =>  $id,        # required
        'store'        =>  $store,     # optional
        
         # Endpoint specific query string parameters
        
        'routing'      =>  $qval1,     # string
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval2,     # boolean
        'filter_path'  =>  $qval3,     # list
        'human'        =>  $qval4,     # boolean
        'pretty'       =>  $qval5,     # boolean
        'source'       =>  $qval6,     # string
    );

L<OpenSearch documentation for ltr-E<gt>update_featureset|https://docs.opensearch.org/latest/search-plugins/ltr/index/>

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

