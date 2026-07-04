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

package OpenSearch::Client::Core::3_0::Direct::Indices;
$OpenSearch::Client::Core::3_0::Direct::Indices::VERSION = '3.007002';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('indices');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::Indices>

=head1 VERSION

version 3.007002

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->indices-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Index APIs>


The index API operations let you interact with indexes in your cluster. Using these operations, you can create, delete, close, and complete other index-related operations.

L<See OpenSearch documentation for indices.|https://docs.opensearch.org/latest/api-reference/index-apis/index/>

=head1 METHODS
    
=head2 indices->add_block

Adds a block to an index.

I<Paths served by this method:>

=over

=item
C<PUT /{index}/_block/{block}>

=back

    $resp = $client->indices->add_block(
        
         # path parameters
        
        'block'                    =>  $block,     # required
        'index'                    =>  $index,     # required
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'         =>  $qval1,     # boolean
        'cluster_manager_timeout'  =>  $qval2,     # string
        'expand_wildcards'         =>  $qval3,     # list
        'ignore_unavailable'       =>  $qval4,     # boolean
        'master_timeout'           =>  $qval5,     # string
        'timeout'                  =>  $qval6,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval7,     # boolean
        'filter_path'              =>  $qval8,     # list
        'human'                    =>  $qval9,     # boolean
        'pretty'                   =>  $qval10,    # boolean
        'source'                   =>  $qval11,    # string
    );

L<OpenSearch documentation for indices.add_block|https://docs.opensearch.org/latest/api-reference/index-apis/index/>
    
=head2 indices->analyze

Performs the analysis process on a text and return the tokens breakdown of the text.

I<Paths served by this method:>

=over

=item
C<GET /_analyze>

=item
C<GET /{index}/_analyze>

=item
C<POST /_analyze>

=item
C<POST /{index}/_analyze>

=back

    $resp = $client->indices->analyze(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'index'        =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'index'        =>  $qval1,     # string
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval2,     # boolean
        'filter_path'  =>  $qval3,     # list
        'human'        =>  $qval4,     # boolean
        'pretty'       =>  $qval5,     # boolean
        'source'       =>  $qval6,     # string
    );

L<OpenSearch documentation for indices.analyze|https://opensearch.org/docs/latest/api-reference/analyze-apis/perform-text-analysis/>
    
=head2 indices->clear_cache

Clears all or specific caches for one or more indexes.

I<Paths served by this method:>

=over

=item
C<POST /_cache/clear>

=item
C<POST /{index}/_cache/clear>

=back

    $resp = $client->indices->clear_cache(
        
         # path parameters
        
        'index'               =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'    =>  $qval1,     # boolean
        'expand_wildcards'    =>  $qval2,     # list
        'fielddata'           =>  $qval3,     # boolean
        'fields'              =>  $qval4,     # list
        'file'                =>  $qval5,     # boolean
        'ignore_unavailable'  =>  $qval6,     # boolean
        'index'               =>  $qval7,     # list
        'query'               =>  $qval8,     # boolean
        'request'             =>  $qval9,     # boolean
        
         # Common API query string parameters
        
        'error_trace'         =>  $qval10,    # boolean
        'filter_path'         =>  $qval11,    # list
        'human'               =>  $qval12,    # boolean
        'pretty'              =>  $qval13,    # boolean
        'source'              =>  $qval14,    # string
    );

L<OpenSearch documentation for indices.clear_cache|https://opensearch.org/docs/latest/api-reference/index-apis/clear-index-cache/>
    
=head2 indices->clone

Clones an index.

I<Paths served by this method:>

=over

=item
C<POST /{index}/_clone/{target}>

=item
C<PUT /{index}/_clone/{target}>

=back

    $resp = $client->indices->clone(
        
        'body'                     =>  $body,      # optional
        
         # path parameters
        
        'index'                    =>  $index,     # required
        'target'                   =>  $target,    # required
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'master_timeout'           =>  $qval2,     # string
        'task_execution_timeout'   =>  $qval3,     # string
        'timeout'                  =>  $qval4,     # string
        'wait_for_active_shards'   =>  $qval5,     # string
        'wait_for_completion'      =>  $qval6,     # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval7,     # boolean
        'filter_path'              =>  $qval8,     # list
        'human'                    =>  $qval9,     # boolean
        'pretty'                   =>  $qval10,    # boolean
        'source'                   =>  $qval11,    # string
    );

L<OpenSearch documentation for indices.clone|https://opensearch.org/docs/latest/api-reference/index-apis/clone/>
    
=head2 indices->close

Closes an index.

I<Paths served by this method:>

=over

=item
C<POST /{index}/_close>

=back

    $resp = $client->indices->close(
        
         # path parameters
        
        'index'                    =>  $index,     # required
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'         =>  $qval1,     # boolean
        'cluster_manager_timeout'  =>  $qval2,     # string
        'expand_wildcards'         =>  $qval3,     # list
        'ignore_unavailable'       =>  $qval4,     # boolean
        'master_timeout'           =>  $qval5,     # string
        'timeout'                  =>  $qval6,     # string
        'wait_for_active_shards'   =>  $qval7,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval8,     # boolean
        'filter_path'              =>  $qval9,     # list
        'human'                    =>  $qval10,    # boolean
        'pretty'                   =>  $qval11,    # boolean
        'source'                   =>  $qval12,    # string
    );

L<OpenSearch documentation for indices.close|https://opensearch.org/docs/latest/api-reference/index-apis/close-index/>
    
=head2 indices->create

Creates an index with optional settings and mappings.

I<Paths served by this method:>

=over

=item
C<PUT /{index}>

=back

    $resp = $client->indices->create(
        
        'body'                     =>  $body,      # optional
        
         # path parameters
        
        'index'                    =>  $index,     # required
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'master_timeout'           =>  $qval2,     # string
        'timeout'                  =>  $qval3,     # string
        'wait_for_active_shards'   =>  $qval4,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval5,     # boolean
        'filter_path'              =>  $qval6,     # list
        'human'                    =>  $qval7,     # boolean
        'pretty'                   =>  $qval8,     # boolean
        'source'                   =>  $qval9,     # string
    );

L<OpenSearch documentation for indices.create|https://opensearch.org/docs/latest/api-reference/index-apis/create-index/>
    
=head2 indices->create_data_stream

Creates or updates a data stream.

I<Paths served by this method:>

=over

=item
C<PUT /_data_stream/{name}>

=back

    $resp = $client->indices->create_data_stream(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'name'         =>  $name,      # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for indices.create_data_stream|https://opensearch.org/docs/latest/im-plugin/data-streams/>
    
=head2 indices->data_streams_stats

Provides statistics on operations happening in a data stream.

I<Paths served by this method:>

=over

=item
C<GET /_data_stream/_stats>

=item
C<GET /_data_stream/{name}/_stats>

=back

    $resp = $client->indices->data_streams_stats(
        
         # path parameters
        
        'name'         =>  $name,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for indices.data_streams_stats|https://opensearch.org/docs/latest/im-plugin/data-streams/>
    
=head2 indices->delete

Deletes an index.

I<Paths served by this method:>

=over

=item
C<DELETE /{index}>

=back

    $resp = $client->indices->delete(
        
         # path parameters
        
        'index'                    =>  $index,     # required
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'         =>  $qval1,     # boolean
        'cluster_manager_timeout'  =>  $qval2,     # string
        'expand_wildcards'         =>  $qval3,     # list
        'ignore_unavailable'       =>  $qval4,     # boolean
        'master_timeout'           =>  $qval5,     # string
        'timeout'                  =>  $qval6,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval7,     # boolean
        'filter_path'              =>  $qval8,     # list
        'human'                    =>  $qval9,     # boolean
        'pretty'                   =>  $qval10,    # boolean
        'source'                   =>  $qval11,    # string
    );

L<OpenSearch documentation for indices.delete|https://opensearch.org/docs/latest/api-reference/index-apis/delete-index/>
    
=head2 indices->delete_alias

Deletes an alias.

I<Paths served by this method:>

=over

=item
C<DELETE /{index}/_alias/{name}>

=item
C<DELETE /{index}/_aliases/{name}>

=back

    $resp = $client->indices->delete_alias(
        
         # path parameters
        
        'index'                    =>  $index,     # required
        'name'                     =>  $name,      # required
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'master_timeout'           =>  $qval2,     # string
        'timeout'                  =>  $qval3,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval4,     # boolean
        'filter_path'              =>  $qval5,     # list
        'human'                    =>  $qval6,     # boolean
        'pretty'                   =>  $qval7,     # boolean
        'source'                   =>  $qval8,     # string
    );

L<OpenSearch documentation for indices.delete_alias|https://opensearch.org/docs/latest/im-plugin/index-alias/#delete-aliases>
    
=head2 indices->delete_data_stream

Deletes a data stream.

I<Paths served by this method:>

=over

=item
C<DELETE /_data_stream/{name}>

=back

    $resp = $client->indices->delete_data_stream(
        
         # path parameters
        
        'name'         =>  $name,      # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for indices.delete_data_stream|https://opensearch.org/docs/latest/im-plugin/data-streams/>
    
=head2 indices->delete_index_template

Deletes an index template.

I<Paths served by this method:>

=over

=item
C<DELETE /_index_template/{name}>

=back

    $resp = $client->indices->delete_index_template(
        
         # path parameters
        
        'name'                     =>  $name,      # required
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'master_timeout'           =>  $qval2,     # string
        'timeout'                  =>  $qval3,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval4,     # boolean
        'filter_path'              =>  $qval5,     # list
        'human'                    =>  $qval6,     # boolean
        'pretty'                   =>  $qval7,     # boolean
        'source'                   =>  $qval8,     # string
    );

L<OpenSearch documentation for indices.delete_index_template|https://opensearch.org/docs/latest/im-plugin/index-templates/#delete-a-template>
    
=head2 indices->delete_template

Deletes an index template.

I<Paths served by this method:>

=over

=item
C<DELETE /_template/{name}>

=back

    $resp = $client->indices->delete_template(
        
         # path parameters
        
        'name'                     =>  $name,      # required
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'master_timeout'           =>  $qval2,     # string
        'timeout'                  =>  $qval3,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval4,     # boolean
        'filter_path'              =>  $qval5,     # list
        'human'                    =>  $qval6,     # boolean
        'pretty'                   =>  $qval7,     # boolean
        'source'                   =>  $qval8,     # string
    );

L<OpenSearch documentation for indices.delete_template|https://docs.opensearch.org/latest/api-reference/index-apis/index/>
    
=head2 indices->exists

Returns information about whether a particular index exists.

I<Paths served by this method:>

=over

=item
C<HEAD /{index}>

=back

    $resp = $client->indices->exists(
        
         # path parameters
        
        'index'                    =>  $index,     # required
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'         =>  $qval1,     # boolean
        'cluster_manager_timeout'  =>  $qval2,     # string
        'expand_wildcards'         =>  $qval3,     # list
        'flat_settings'            =>  $qval4,     # boolean
        'ignore_unavailable'       =>  $qval5,     # boolean
        'include_defaults'         =>  $qval6,     # boolean
        'local'                    =>  $qval7,     # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval8,     # boolean
        'filter_path'              =>  $qval9,     # list
        'human'                    =>  $qval10,    # boolean
        'pretty'                   =>  $qval11,    # boolean
        'source'                   =>  $qval12,    # string
    );

L<OpenSearch documentation for indices.exists|https://opensearch.org/docs/latest/api-reference/index-apis/exists/>
    
=head2 indices->exists_alias

Returns information about whether a particular alias exists.

I<Paths served by this method:>

=over

=item
C<HEAD /_alias/{name}>

=item
C<HEAD /{index}/_alias/{name}>

=back

    $resp = $client->indices->exists_alias(
        
         # path parameters
        
        'index'               =>  $index,     # optional
        'name'                =>  $name,      # required
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'    =>  $qval1,     # boolean
        'expand_wildcards'    =>  $qval2,     # list
        'ignore_unavailable'  =>  $qval3,     # boolean
        'local'               =>  $qval4,     # boolean
        
         # Common API query string parameters
        
        'error_trace'         =>  $qval5,     # boolean
        'filter_path'         =>  $qval6,     # list
        'human'               =>  $qval7,     # boolean
        'pretty'              =>  $qval8,     # boolean
        'source'              =>  $qval9,     # string
    );

L<OpenSearch documentation for indices.exists_alias|https://docs.opensearch.org/latest/api-reference/index-apis/index/>
    
=head2 indices->exists_index_template

Returns information about whether a particular index template exists.

I<Paths served by this method:>

=over

=item
C<HEAD /_index_template/{name}>

=back

    $resp = $client->indices->exists_index_template(
        
         # path parameters
        
        'name'                     =>  $name,      # required
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'flat_settings'            =>  $qval2,     # boolean
        'local'                    =>  $qval3,     # boolean
        'master_timeout'           =>  $qval4,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval5,     # boolean
        'filter_path'              =>  $qval6,     # list
        'human'                    =>  $qval7,     # boolean
        'pretty'                   =>  $qval8,     # boolean
        'source'                   =>  $qval9,     # string
    );

L<OpenSearch documentation for indices.exists_index_template|https://opensearch.org/docs/latest/im-plugin/index-templates/>
    
=head2 indices->exists_template

Returns information about whether a particular index template exists.

I<Paths served by this method:>

=over

=item
C<HEAD /_template/{name}>

=back

    $resp = $client->indices->exists_template(
        
         # path parameters
        
        'name'                     =>  $name,      # required
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'flat_settings'            =>  $qval2,     # boolean
        'local'                    =>  $qval3,     # boolean
        'master_timeout'           =>  $qval4,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval5,     # boolean
        'filter_path'              =>  $qval6,     # list
        'human'                    =>  $qval7,     # boolean
        'pretty'                   =>  $qval8,     # boolean
        'source'                   =>  $qval9,     # string
    );

L<OpenSearch documentation for indices.exists_template|https://docs.opensearch.org/latest/api-reference/index-apis/index/>
    
=head2 indices->flush

Performs the flush operation on one or more indexes.

I<Paths served by this method:>

=over

=item
C<GET /_flush>

=item
C<GET /{index}/_flush>

=item
C<POST /_flush>

=item
C<POST /{index}/_flush>

=back

    $resp = $client->indices->flush(
        
         # path parameters
        
        'index'               =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'    =>  $qval1,     # boolean
        'expand_wildcards'    =>  $qval2,     # list
        'force'               =>  $qval3,     # boolean
        'ignore_unavailable'  =>  $qval4,     # boolean
        'wait_if_ongoing'     =>  $qval5,     # boolean
        
         # Common API query string parameters
        
        'error_trace'         =>  $qval6,     # boolean
        'filter_path'         =>  $qval7,     # list
        'human'               =>  $qval8,     # boolean
        'pretty'              =>  $qval9,     # boolean
        'source'              =>  $qval10,    # string
    );

L<OpenSearch documentation for indices.flush|https://docs.opensearch.org/latest/api-reference/index-apis/index/>
    
=head2 indices->forcemerge

Performs the force merge operation on one or more indexes.

I<Paths served by this method:>

=over

=item
C<POST /_forcemerge>

=item
C<POST /{index}/_forcemerge>

=back

    $resp = $client->indices->forcemerge(
        
         # path parameters
        
        'index'                 =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'      =>  $qval1,     # boolean
        'expand_wildcards'      =>  $qval2,     # list
        'flush'                 =>  $qval3,     # boolean
        'ignore_unavailable'    =>  $qval4,     # boolean
        'max_num_segments'      =>  $qval5,     # number
        'only_expunge_deletes'  =>  $qval6,     # boolean
        'primary_only'          =>  $qval7,     # boolean
        'wait_for_completion'   =>  $qval8,     # boolean
        
         # Common API query string parameters
        
        'error_trace'           =>  $qval9,     # boolean
        'filter_path'           =>  $qval10,    # list
        'human'                 =>  $qval11,    # boolean
        'pretty'                =>  $qval12,    # boolean
        'source'                =>  $qval13,    # string
    );

L<OpenSearch documentation for indices.forcemerge|https://docs.opensearch.org/latest/api-reference/index-apis/index/>
    
=head2 indices->get

Returns information about one or more indexes.

I<Paths served by this method:>

=over

=item
C<GET /{index}>

=back

    $resp = $client->indices->get(
        
         # path parameters
        
        'index'                    =>  $index,     # required
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'         =>  $qval1,     # boolean
        'cluster_manager_timeout'  =>  $qval2,     # string
        'expand_wildcards'         =>  $qval3,     # list
        'flat_settings'            =>  $qval4,     # boolean
        'ignore_unavailable'       =>  $qval5,     # boolean
        'include_defaults'         =>  $qval6,     # boolean
        'local'                    =>  $qval7,     # boolean
        'master_timeout'           =>  $qval8,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval9,     # boolean
        'filter_path'              =>  $qval10,    # list
        'human'                    =>  $qval11,    # boolean
        'pretty'                   =>  $qval12,    # boolean
        'source'                   =>  $qval13,    # string
    );

L<OpenSearch documentation for indices.get|https://opensearch.org/docs/latest/api-reference/index-apis/get-index/>
    
=head2 indices->get_alias

Returns an alias.

I<Paths served by this method:>

=over

=item
C<GET /_alias>

=item
C<GET /_alias/{name}>

=item
C<GET /{index}/_alias>

=item
C<GET /{index}/_alias/{name}>

=back

    $resp = $client->indices->get_alias(
        
         # path parameters
        
        'index'               =>  $index,     # optional
        'name'                =>  $name,      # optional
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'    =>  $qval1,     # boolean
        'expand_wildcards'    =>  $qval2,     # list
        'ignore_unavailable'  =>  $qval3,     # boolean
        'local'               =>  $qval4,     # boolean
        
         # Common API query string parameters
        
        'error_trace'         =>  $qval5,     # boolean
        'filter_path'         =>  $qval6,     # list
        'human'               =>  $qval7,     # boolean
        'pretty'              =>  $qval8,     # boolean
        'source'              =>  $qval9,     # string
    );

L<OpenSearch documentation for indices.get_alias|https://opensearch.org/docs/latest/im-plugin/index-alias/>
    
=head2 indices->get_data_stream

Returns data streams.

I<Paths served by this method:>

=over

=item
C<GET /_data_stream>

=item
C<GET /_data_stream/{name}>

=back

    $resp = $client->indices->get_data_stream(
        
         # path parameters
        
        'name'         =>  $name,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for indices.get_data_stream|https://opensearch.org/docs/latest/im-plugin/data-streams/>
    
=head2 indices->get_field_mapping

Returns mapping for one or more fields.

I<Paths served by this method:>

=over

=item
C<GET /_mapping/field/{fields}>

=item
C<GET /{index}/_mapping/field/{fields}>

=back

    $resp = $client->indices->get_field_mapping(
        
         # path parameters
        
        'fields'              =>  $fields,    # required
        'index'               =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'    =>  $qval1,     # boolean
        'expand_wildcards'    =>  $qval2,     # list
        'ignore_unavailable'  =>  $qval3,     # boolean
        'include_defaults'    =>  $qval4,     # boolean
        'local'               =>  $qval5,     # boolean
        
         # Common API query string parameters
        
        'error_trace'         =>  $qval6,     # boolean
        'filter_path'         =>  $qval7,     # list
        'human'               =>  $qval8,     # boolean
        'pretty'              =>  $qval9,     # boolean
        'source'              =>  $qval10,    # string
    );

L<OpenSearch documentation for indices.get_field_mapping|https://opensearch.org/docs/latest/field-types/index/>
    
=head2 indices->get_index_template

Returns an index template.

I<Paths served by this method:>

=over

=item
C<GET /_index_template>

=item
C<GET /_index_template/{name}>

=back

    $resp = $client->indices->get_index_template(
        
         # path parameters
        
        'name'                     =>  $name,      # optional
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'flat_settings'            =>  $qval2,     # boolean
        'local'                    =>  $qval3,     # boolean
        'master_timeout'           =>  $qval4,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval5,     # boolean
        'filter_path'              =>  $qval6,     # list
        'human'                    =>  $qval7,     # boolean
        'pretty'                   =>  $qval8,     # boolean
        'source'                   =>  $qval9,     # string
    );

L<OpenSearch documentation for indices.get_index_template|https://opensearch.org/docs/latest/im-plugin/index-templates/>
    
=head2 indices->get_mapping

Returns mappings for one or more indexes.

I<Paths served by this method:>

=over

=item
C<GET /_mapping>

=item
C<GET /{index}/_mapping>

=back

    $resp = $client->indices->get_mapping(
        
         # path parameters
        
        'index'                    =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'         =>  $qval1,     # boolean
        'cluster_manager_timeout'  =>  $qval2,     # string
        'expand_wildcards'         =>  $qval3,     # list
        'ignore_unavailable'       =>  $qval4,     # boolean
        'index'                    =>  $qval5,     # list
        'local'                    =>  $qval6,     # boolean
        'master_timeout'           =>  $qval7,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval8,     # boolean
        'filter_path'              =>  $qval9,     # list
        'human'                    =>  $qval10,    # boolean
        'pretty'                   =>  $qval11,    # boolean
        'source'                   =>  $qval12,    # string
    );

L<OpenSearch documentation for indices.get_mapping|https://opensearch.org/docs/latest/field-types/index/#get-a-mapping>
    
=head2 indices->get_settings

Returns settings for one or more indexes.

I<Paths served by this method:>

=over

=item
C<GET /_settings>

=item
C<GET /_settings/{name}>

=item
C<GET /{index}/_settings>

=item
C<GET /{index}/_settings/{name}>

=back

    $resp = $client->indices->get_settings(
        
         # path parameters
        
        'index'                    =>  $index,     # optional
        'name'                     =>  $name,      # optional
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'         =>  $qval1,     # boolean
        'cluster_manager_timeout'  =>  $qval2,     # string
        'expand_wildcards'         =>  $qval3,     # list
        'flat_settings'            =>  $qval4,     # boolean
        'ignore_unavailable'       =>  $qval5,     # boolean
        'include_defaults'         =>  $qval6,     # boolean
        'local'                    =>  $qval7,     # boolean
        'master_timeout'           =>  $qval8,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval9,     # boolean
        'filter_path'              =>  $qval10,    # list
        'human'                    =>  $qval11,    # boolean
        'pretty'                   =>  $qval12,    # boolean
        'source'                   =>  $qval13,    # string
    );

L<OpenSearch documentation for indices.get_settings|https://opensearch.org/docs/latest/api-reference/index-apis/get-settings/>
    
=head2 indices->get_template

Returns an index template.

I<Paths served by this method:>

=over

=item
C<GET /_template>

=item
C<GET /_template/{name}>

=back

    $resp = $client->indices->get_template(
        
         # path parameters
        
        'name'                     =>  $name,      # optional
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'flat_settings'            =>  $qval2,     # boolean
        'local'                    =>  $qval3,     # boolean
        'master_timeout'           =>  $qval4,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval5,     # boolean
        'filter_path'              =>  $qval6,     # list
        'human'                    =>  $qval7,     # boolean
        'pretty'                   =>  $qval8,     # boolean
        'source'                   =>  $qval9,     # string
    );

L<OpenSearch documentation for indices.get_template|https://docs.opensearch.org/latest/api-reference/index-apis/index/>
    
=head2 indices->get_upgrade

The `_upgrade` API is no longer useful and will be removed.

I<Paths served by this method:>

=over

=item
C<GET /_upgrade>

=item
C<GET /{index}/_upgrade>

=back

    $resp = $client->indices->get_upgrade(
        
         # path parameters
        
        'index'               =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'    =>  $qval1,     # boolean
        'expand_wildcards'    =>  $qval2,     # list
        'ignore_unavailable'  =>  $qval3,     # boolean
        
         # Common API query string parameters
        
        'error_trace'         =>  $qval4,     # boolean
        'filter_path'         =>  $qval5,     # list
        'human'               =>  $qval6,     # boolean
        'pretty'              =>  $qval7,     # boolean
        'source'              =>  $qval8,     # string
    );

L<OpenSearch documentation for indices.get_upgrade|https://docs.opensearch.org/latest/api-reference/index-apis/index/>
    
=head2 indices->open

Opens an index.

I<Paths served by this method:>

=over

=item
C<POST /{index}/_open>

=back

    $resp = $client->indices->open(
        
         # path parameters
        
        'index'                    =>  $index,     # required
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'         =>  $qval1,     # boolean
        'cluster_manager_timeout'  =>  $qval2,     # string
        'expand_wildcards'         =>  $qval3,     # list
        'ignore_unavailable'       =>  $qval4,     # boolean
        'master_timeout'           =>  $qval5,     # string
        'task_execution_timeout'   =>  $qval6,     # string
        'timeout'                  =>  $qval7,     # string
        'wait_for_active_shards'   =>  $qval8,     # string
        'wait_for_completion'      =>  $qval9,     # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval10,    # boolean
        'filter_path'              =>  $qval11,    # list
        'human'                    =>  $qval12,    # boolean
        'pretty'                   =>  $qval13,    # boolean
        'source'                   =>  $qval14,    # string
    );

L<OpenSearch documentation for indices.open|https://opensearch.org/docs/latest/api-reference/index-apis/open-index/>
    
=head2 indices->put_alias

Creates or updates an alias.

I<Paths served by this method:>

=over

=item
C<POST /_alias/{name}>

=item
C<POST /_aliases/{name}>

=item
C<POST /{index}/_alias/{name}>

=item
C<POST /{index}/_aliases/{name}>

=item
C<PUT /_alias>

=item
C<PUT /_alias/{name}>

=item
C<PUT /_aliases/{name}>

=item
C<PUT /{index}/_alias>

=item
C<PUT /{index}/_alias/{name}>

=item
C<PUT /{index}/_aliases>

=item
C<PUT /{index}/_aliases/{name}>

=back

    $resp = $client->indices->put_alias(
        
        'body'                     =>  $body,      # optional
        
         # path parameters
        
        'index'                    =>  $index,     # optional
        'name'                     =>  $name,      # optional
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'master_timeout'           =>  $qval2,     # string
        'timeout'                  =>  $qval3,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval4,     # boolean
        'filter_path'              =>  $qval5,     # list
        'human'                    =>  $qval6,     # boolean
        'pretty'                   =>  $qval7,     # boolean
        'source'                   =>  $qval8,     # string
    );

L<OpenSearch documentation for indices.put_alias|https://opensearch.org/docs/latest/api-reference/index-apis/update-alias/>
    
=head2 indices->put_index_template

Creates or updates an index template.

I<Paths served by this method:>

=over

=item
C<POST /_index_template/{name}>

=item
C<PUT /_index_template/{name}>

=back

    $resp = $client->indices->put_index_template(
        
        'body'                     =>  $body,      # required
        
         # path parameters
        
        'name'                     =>  $name,      # required
        
         # Endpoint specific query string parameters
        
        'cause'                    =>  $qval1,     # string
        'cluster_manager_timeout'  =>  $qval2,     # string
        'create'                   =>  $qval3,     # boolean
        'master_timeout'           =>  $qval4,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval5,     # boolean
        'filter_path'              =>  $qval6,     # list
        'human'                    =>  $qval7,     # boolean
        'pretty'                   =>  $qval8,     # boolean
        'source'                   =>  $qval9,     # string
    );

L<OpenSearch documentation for indices.put_index_template|https://opensearch.org/docs/latest/im-plugin/index-templates/>
    
=head2 indices->put_mapping

Updates the index mappings.

I<Paths served by this method:>

=over

=item
C<POST /{index}/_mapping>

=item
C<PUT /{index}/_mapping>

=back

    $resp = $client->indices->put_mapping(
        
        'body'                     =>  $body,      # required
        
         # path parameters
        
        'index'                    =>  $index,     # required
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'         =>  $qval1,     # boolean
        'cluster_manager_timeout'  =>  $qval2,     # string
        'expand_wildcards'         =>  $qval3,     # list
        'ignore_unavailable'       =>  $qval4,     # boolean
        'master_timeout'           =>  $qval5,     # string
        'timeout'                  =>  $qval6,     # string
        'write_index_only'         =>  $qval7,     # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval8,     # boolean
        'filter_path'              =>  $qval9,     # list
        'human'                    =>  $qval10,    # boolean
        'pretty'                   =>  $qval11,    # boolean
        'source'                   =>  $qval12,    # string
    );

L<OpenSearch documentation for indices.put_mapping|https://opensearch.org/docs/latest/api-reference/index-apis/put-mapping/>
    
=head2 indices->put_settings

Updates the index settings.

I<Paths served by this method:>

=over

=item
C<PUT /_settings>

=item
C<PUT /{index}/_settings>

=back

    $resp = $client->indices->put_settings(
        
        'body'                     =>  $body,      # optional
        
         # path parameters
        
        'index'                    =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'         =>  $qval1,     # boolean
        'cluster_manager_timeout'  =>  $qval2,     # string
        'expand_wildcards'         =>  $qval3,     # list
        'flat_settings'            =>  $qval4,     # boolean
        'ignore_unavailable'       =>  $qval5,     # boolean
        'master_timeout'           =>  $qval6,     # string
        'preserve_existing'        =>  $qval7,     # boolean
        'timeout'                  =>  $qval8,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval9,     # boolean
        'filter_path'              =>  $qval10,    # list
        'human'                    =>  $qval11,    # boolean
        'pretty'                   =>  $qval12,    # boolean
        'source'                   =>  $qval13,    # string
    );

L<OpenSearch documentation for indices.put_settings|https://opensearch.org/docs/latest/api-reference/index-apis/update-settings/>
    
=head2 indices->put_template

Creates or updates an index template.

I<Paths served by this method:>

=over

=item
C<POST /_template/{name}>

=item
C<PUT /_template/{name}>

=back

    $resp = $client->indices->put_template(
        
        'body'                     =>  $body,      # required
        
         # path parameters
        
        'name'                     =>  $name,      # required
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'create'                   =>  $qval2,     # boolean
        'master_timeout'           =>  $qval3,     # string
        'order'                    =>  $qval4,     # number
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval5,     # boolean
        'filter_path'              =>  $qval6,     # list
        'human'                    =>  $qval7,     # boolean
        'pretty'                   =>  $qval8,     # boolean
        'source'                   =>  $qval9,     # string
    );

L<OpenSearch documentation for indices.put_template|https://opensearch.org/docs/latest/im-plugin/index-templates/>
    
=head2 indices->recovery

Returns information about ongoing index shard recoveries.

I<Paths served by this method:>

=over

=item
C<GET /_recovery>

=item
C<GET /{index}/_recovery>

=back

    $resp = $client->indices->recovery(
        
         # path parameters
        
        'index'        =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'active_only'  =>  $qval1,     # boolean
        'detailed'     =>  $qval2,     # boolean
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval3,     # boolean
        'filter_path'  =>  $qval4,     # list
        'human'        =>  $qval5,     # boolean
        'pretty'       =>  $qval6,     # boolean
        'source'       =>  $qval7,     # string
    );

L<OpenSearch documentation for indices.recovery|https://docs.opensearch.org/latest/api-reference/index-apis/index/>
    
=head2 indices->refresh

Performs the refresh operation in one or more indexes.

I<Paths served by this method:>

=over

=item
C<GET /_refresh>

=item
C<GET /{index}/_refresh>

=item
C<POST /_refresh>

=item
C<POST /{index}/_refresh>

=back

    $resp = $client->indices->refresh(
        
         # path parameters
        
        'index'               =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'    =>  $qval1,     # boolean
        'expand_wildcards'    =>  $qval2,     # list
        'ignore_unavailable'  =>  $qval3,     # boolean
        
         # Common API query string parameters
        
        'error_trace'         =>  $qval4,     # boolean
        'filter_path'         =>  $qval5,     # list
        'human'               =>  $qval6,     # boolean
        'pretty'              =>  $qval7,     # boolean
        'source'              =>  $qval8,     # string
    );

L<OpenSearch documentation for indices.refresh|https://opensearch.org/docs/latest/tuning-your-cluster/availability-and-recovery/remote-store/index/#refresh-level-and-request-level-durability>
    
=head2 indices->resolve_index

Returns information about any matching indexes, aliases, and data streams.

I<Paths served by this method:>

=over

=item
C<GET /_resolve/index/{name}>

=back

    $resp = $client->indices->resolve_index(
        
         # path parameters
        
        'name'              =>  $name,      # required
        
         # Endpoint specific query string parameters
        
        'expand_wildcards'  =>  $qval1,     # list
        
         # Common API query string parameters
        
        'error_trace'       =>  $qval2,     # boolean
        'filter_path'       =>  $qval3,     # list
        'human'             =>  $qval4,     # boolean
        'pretty'            =>  $qval5,     # boolean
        'source'            =>  $qval6,     # string
    );

L<OpenSearch documentation for indices.resolve_index|https://docs.opensearch.org/latest/api-reference/index-apis/index/>
    
=head2 indices->rollover

Updates an alias to point to a new index when the existing index
is considered to be too large or too old.

I<Paths served by this method:>

=over

=item
C<POST /{alias}/_rollover>

=item
C<POST /{alias}/_rollover/{new_index}>

=back

    $resp = $client->indices->rollover(
        
        'body'                     =>  $body,      # optional
        
         # path parameters
        
        'alias'                    =>  $alias,     # required
        'new_index'                =>  $new_index,  # optional
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'dry_run'                  =>  $qval2,     # boolean
        'master_timeout'           =>  $qval3,     # string
        'timeout'                  =>  $qval4,     # string
        'wait_for_active_shards'   =>  $qval5,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval6,     # boolean
        'filter_path'              =>  $qval7,     # list
        'human'                    =>  $qval8,     # boolean
        'pretty'                   =>  $qval9,     # boolean
        'source'                   =>  $qval10,    # string
    );

L<OpenSearch documentation for indices.rollover|https://opensearch.org/docs/latest/dashboards/im-dashboards/rollover/>
    
=head2 indices->segments

Provides low-level information about segments in a Lucene index.

I<Paths served by this method:>

=over

=item
C<GET /_segments>

=item
C<GET /{index}/_segments>

=back

    $resp = $client->indices->segments(
        
         # path parameters
        
        'index'               =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'    =>  $qval1,     # boolean
        'expand_wildcards'    =>  $qval2,     # list
        'ignore_unavailable'  =>  $qval3,     # boolean
        'verbose'             =>  $qval4,     # boolean
        
         # Common API query string parameters
        
        'error_trace'         =>  $qval5,     # boolean
        'filter_path'         =>  $qval6,     # list
        'human'               =>  $qval7,     # boolean
        'pretty'              =>  $qval8,     # boolean
        'source'              =>  $qval9,     # string
    );

L<OpenSearch documentation for indices.segments|https://docs.opensearch.org/latest/api-reference/index-apis/index/>
    
=head2 indices->shard_stores

Provides store information for shard copies of indexes.

I<Paths served by this method:>

=over

=item
C<GET /_shard_stores>

=item
C<GET /{index}/_shard_stores>

=back

    $resp = $client->indices->shard_stores(
        
         # path parameters
        
        'index'               =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'    =>  $qval1,     # boolean
        'expand_wildcards'    =>  $qval2,     # list
        'ignore_unavailable'  =>  $qval3,     # boolean
        'status'              =>  $qval4,     # list
        
         # Common API query string parameters
        
        'error_trace'         =>  $qval5,     # boolean
        'filter_path'         =>  $qval6,     # list
        'human'               =>  $qval7,     # boolean
        'pretty'              =>  $qval8,     # boolean
        'source'              =>  $qval9,     # string
    );

L<OpenSearch documentation for indices.shard_stores|https://docs.opensearch.org/latest/api-reference/index-apis/index/>
    
=head2 indices->shrink

Allow to shrink an existing index into a new index with fewer primary shards.

I<Paths served by this method:>

=over

=item
C<POST /{index}/_shrink/{target}>

=item
C<PUT /{index}/_shrink/{target}>

=back

    $resp = $client->indices->shrink(
        
        'body'                     =>  $body,      # optional
        
         # path parameters
        
        'index'                    =>  $index,     # required
        'target'                   =>  $target,    # required
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'copy_settings'            =>  $qval2,     # boolean
        'master_timeout'           =>  $qval3,     # string
        'task_execution_timeout'   =>  $qval4,     # string
        'timeout'                  =>  $qval5,     # string
        'wait_for_active_shards'   =>  $qval6,     # string
        'wait_for_completion'      =>  $qval7,     # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval8,     # boolean
        'filter_path'              =>  $qval9,     # list
        'human'                    =>  $qval10,    # boolean
        'pretty'                   =>  $qval11,    # boolean
        'source'                   =>  $qval12,    # string
    );

L<OpenSearch documentation for indices.shrink|https://opensearch.org/docs/latest/api-reference/index-apis/shrink-index/>
    
=head2 indices->simulate_index_template

Simulate matching the given index name against the index templates in the system.

I<Paths served by this method:>

=over

=item
C<POST /_index_template/_simulate_index/{name}>

=back

    $resp = $client->indices->simulate_index_template(
        
        'body'                     =>  $body,      # optional
        
         # path parameters
        
        'name'                     =>  $name,      # required
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'master_timeout'           =>  $qval2,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval3,     # boolean
        'filter_path'              =>  $qval4,     # list
        'human'                    =>  $qval5,     # boolean
        'pretty'                   =>  $qval6,     # boolean
        'source'                   =>  $qval7,     # string
    );

L<OpenSearch documentation for indices.simulate_index_template|https://docs.opensearch.org/latest/api-reference/index-apis/index/>
    
=head2 indices->simulate_template

Simulate resolving the given template name or body.

I<Paths served by this method:>

=over

=item
C<POST /_index_template/_simulate>

=item
C<POST /_index_template/_simulate/{name}>

=back

    $resp = $client->indices->simulate_template(
        
        'body'                     =>  $body,      # optional
        
         # path parameters
        
        'name'                     =>  $name,      # optional
        
         # Endpoint specific query string parameters
        
        'cause'                    =>  $qval1,     # string
        'cluster_manager_timeout'  =>  $qval2,     # string
        'create'                   =>  $qval3,     # boolean
        'master_timeout'           =>  $qval4,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval5,     # boolean
        'filter_path'              =>  $qval6,     # list
        'human'                    =>  $qval7,     # boolean
        'pretty'                   =>  $qval8,     # boolean
        'source'                   =>  $qval9,     # string
    );

L<OpenSearch documentation for indices.simulate_template|https://docs.opensearch.org/latest/api-reference/index-apis/index/>
    
=head2 indices->split

Allows you to split an existing index into a new index with more primary shards.

I<Paths served by this method:>

=over

=item
C<POST /{index}/_split/{target}>

=item
C<PUT /{index}/_split/{target}>

=back

    $resp = $client->indices->split(
        
        'body'                     =>  $body,      # optional
        
         # path parameters
        
        'index'                    =>  $index,     # required
        'target'                   =>  $target,    # required
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'copy_settings'            =>  $qval2,     # boolean
        'master_timeout'           =>  $qval3,     # string
        'task_execution_timeout'   =>  $qval4,     # string
        'timeout'                  =>  $qval5,     # string
        'wait_for_active_shards'   =>  $qval6,     # string
        'wait_for_completion'      =>  $qval7,     # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval8,     # boolean
        'filter_path'              =>  $qval9,     # list
        'human'                    =>  $qval10,    # boolean
        'pretty'                   =>  $qval11,    # boolean
        'source'                   =>  $qval12,    # string
    );

L<OpenSearch documentation for indices.split|https://opensearch.org/docs/latest/api-reference/index-apis/split/>
    
=head2 indices->stats

Provides statistics on operations happening in an index.

I<Paths served by this method:>

=over

=item
C<GET /_stats>

=item
C<GET /_stats/{metric}>

=item
C<GET /{index}/_stats>

=item
C<GET /{index}/_stats/{metric}>

=back

    $resp = $client->indices->stats(
        
         # path parameters
        
        'index'                       =>  $index,     # optional
        'metric'                      =>  $metric,    # optional
        
         # Endpoint specific query string parameters
        
        'completion_fields'           =>  $qval1,     # list
        'expand_wildcards'            =>  $qval2,     # list
        'fielddata_fields'            =>  $qval3,     # list
        'fields'                      =>  $qval4,     # list
        'forbid_closed_indices'       =>  $qval5,     # boolean
        'groups'                      =>  $qval6,     # list
        'include_segment_file_sizes'  =>  $qval7,     # boolean
        'include_unloaded_segments'   =>  $qval8,     # boolean
        'level'                       =>  $qval9,     # string
        
         # Common API query string parameters
        
        'error_trace'                 =>  $qval10,    # boolean
        'filter_path'                 =>  $qval11,    # list
        'human'                       =>  $qval12,    # boolean
        'pretty'                      =>  $qval13,    # boolean
        'source'                      =>  $qval14,    # string
    );

L<OpenSearch documentation for indices.stats|https://docs.opensearch.org/latest/api-reference/index-apis/index/>
    
=head2 indices->update_aliases

Updates index aliases.

I<Paths served by this method:>

=over

=item
C<POST /_aliases>

=back

    $resp = $client->indices->update_aliases(
        
        'body'                     =>  $body,      # optional
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'master_timeout'           =>  $qval2,     # string
        'timeout'                  =>  $qval3,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval4,     # boolean
        'filter_path'              =>  $qval5,     # list
        'human'                    =>  $qval6,     # boolean
        'pretty'                   =>  $qval7,     # boolean
        'source'                   =>  $qval8,     # string
    );

L<OpenSearch documentation for indices.update_aliases|https://opensearch.org/docs/latest/api-reference/index-apis/alias/>
    
=head2 indices->upgrade

The `_upgrade` API is no longer useful and will be removed.

I<Paths served by this method:>

=over

=item
C<POST /_upgrade>

=item
C<POST /{index}/_upgrade>

=back

    $resp = $client->indices->upgrade(
        
         # path parameters
        
        'index'                  =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'       =>  $qval1,     # boolean
        'expand_wildcards'       =>  $qval2,     # list
        'ignore_unavailable'     =>  $qval3,     # boolean
        'only_ancient_segments'  =>  $qval4,     # boolean
        'wait_for_completion'    =>  $qval5,     # boolean
        
         # Common API query string parameters
        
        'error_trace'            =>  $qval6,     # boolean
        'filter_path'            =>  $qval7,     # list
        'human'                  =>  $qval8,     # boolean
        'pretty'                 =>  $qval9,     # boolean
        'source'                 =>  $qval10,    # string
    );

L<OpenSearch documentation for indices.upgrade|https://docs.opensearch.org/latest/api-reference/index-apis/index/>
    
=head2 indices->validate_query

Allows a user to validate a potentially expensive query without executing it.

I<Paths served by this method:>

=over

=item
C<GET /_validate/query>

=item
C<GET /{index}/_validate/query>

=item
C<POST /_validate/query>

=item
C<POST /{index}/_validate/query>

=back

    $resp = $client->indices->validate_query(
        
        'body'                =>  $body,      # optional
        
         # path parameters
        
        'index'               =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'all_shards'          =>  $qval1,     # boolean
        'allow_no_indices'    =>  $qval2,     # boolean
        'analyze_wildcard'    =>  $qval3,     # boolean
        'analyzer'            =>  $qval4,     # string
        'default_operator'    =>  $qval5,     # string
        'df'                  =>  $qval6,     # string
        'expand_wildcards'    =>  $qval7,     # list
        'explain'             =>  $qval8,     # boolean
        'ignore_unavailable'  =>  $qval9,     # boolean
        'lenient'             =>  $qval10,    # boolean
        'q'                   =>  $qval11,    # string
        'rewrite'             =>  $qval12,    # boolean
        
         # Common API query string parameters
        
        'error_trace'         =>  $qval13,    # boolean
        'filter_path'         =>  $qval14,    # list
        'human'               =>  $qval15,    # boolean
        'pretty'              =>  $qval16,    # boolean
        'source'              =>  $qval17,    # string
    );

L<OpenSearch documentation for indices.validate_query|https://docs.opensearch.org/latest/api-reference/index-apis/index/>

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

