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

package OpenSearch::Client::Core::3_0::Direct;
$OpenSearch::Client::Core::3_0::Direct::VERSION = '3.007008';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';

use OpenSearch::Client::Util qw(parse_params is_compat);
use namespace::clean;

sub _namespace {__PACKAGE__}


has 'asynchronous_search'        => ( is => 'lazy', init_arg => undef );
has 'cat'                        => ( is => 'lazy', init_arg => undef );
has 'cluster'                    => ( is => 'lazy', init_arg => undef );
has 'dangling_indices'           => ( is => 'lazy', init_arg => undef );
has 'flow_framework'             => ( is => 'lazy', init_arg => undef );
has 'geospatial'                 => ( is => 'lazy', init_arg => undef );
has 'indices'                    => ( is => 'lazy', init_arg => undef );
has 'ingest'                     => ( is => 'lazy', init_arg => undef );
has 'ingestion'                  => ( is => 'lazy', init_arg => undef );
has 'insights'                   => ( is => 'lazy', init_arg => undef );
has 'ism'                        => ( is => 'lazy', init_arg => undef );
has 'knn'                        => ( is => 'lazy', init_arg => undef );
has 'list'                       => ( is => 'lazy', init_arg => undef );
has 'ltr'                        => ( is => 'lazy', init_arg => undef );
has 'ml'                         => ( is => 'lazy', init_arg => undef );
has 'neural'                     => ( is => 'lazy', init_arg => undef );
has 'nodes'                      => ( is => 'lazy', init_arg => undef );
has 'notifications'              => ( is => 'lazy', init_arg => undef );
has 'observability'              => ( is => 'lazy', init_arg => undef );
has 'ppl'                        => ( is => 'lazy', init_arg => undef );
has 'query'                      => ( is => 'lazy', init_arg => undef );
has 'remote_store'               => ( is => 'lazy', init_arg => undef );
has 'replication'                => ( is => 'lazy', init_arg => undef );
has 'rollups'                    => ( is => 'lazy', init_arg => undef );
has 'search_pipeline'            => ( is => 'lazy', init_arg => undef );
has 'search_relevance'           => ( is => 'lazy', init_arg => undef );
has 'security'                   => ( is => 'lazy', init_arg => undef );
has 'security_analytics'         => ( is => 'lazy', init_arg => undef );
has 'sm'                         => ( is => 'lazy', init_arg => undef );
has 'snapshot'                   => ( is => 'lazy', init_arg => undef );
has 'sql'                        => ( is => 'lazy', init_arg => undef );
has 'tasks'                      => ( is => 'lazy', init_arg => undef );
has 'transforms'                 => ( is => 'lazy', init_arg => undef );
has 'ubi'                        => ( is => 'lazy', init_arg => undef );
has 'wlm'                        => ( is => 'lazy', init_arg => undef );
has 'bulk_helper_class'    => ( is => 'rw' );
has 'scroll_helper_class'  => ( is => 'rw' );
has '_bulk_class'          => ( is => 'lazy' );
has '_scroll_class'        => ( is => 'lazy' );
has 'opensearch_version'   => ( is => 'lazy' );

#---------------------------------------
sub global_method_supported_in_version {
#---------------------------------------
    my( $self, @args ) = @_;
    my %params = ( ref($args[0]) ) ? %{ $args[0] } : @args;
    
    my $version = $params{version} || $self->opensearch_version;
    my $module  = $params{module} || '_core';
    my $method  = $params{method} || 'not_a_real_method_name';
    
    if( $module eq '_core' ) {
        if( $self->can($method) ) {
            my $result = $self->method_supported_in_version( method => $method, version => $version);
            return $result;
        }
    } else {
       if( $self->can($module) ) {
            my $cli = $self->$module;
            if( $cli->can($method) ) {
                my $result = $cli->method_supported_in_version( method => $method, version => $version);
                return $result;
            }
        }
    }
    
    return 0;
}


#===================================
sub _build__bulk_class {
#===================================
    my $self       = shift;
    my $bulk_class = $self->bulk_helper_class
        || 'Core::' . $self->api_version . '::Helper::Bulk';
    $self->_build_helper( 'bulk', $bulk_class );
}

#===================================
sub _build__scroll_class {
#===================================
    my $self         = shift;
    my $scroll_class = $self->scroll_helper_class
        || 'Core::' . $self->api_version . '::Helper::Scroll';
    $self->_build_helper( 'scroll', $scroll_class );
}

#===================================
sub _build_opensearch_version {
#===================================
    my $self  = shift;
    my $resp  = $self->info();
    my $os_version = $resp->{version}->{number};    
    return $os_version;
}

#===================================
sub bulk_helper {
#===================================
    my ( $self, $params ) = parse_params(@_);
    $params->{os} ||= $self;
    $self->_bulk_class->new($params);
}

#===================================
sub scroll_helper {
#===================================
    my ( $self, $params ) = parse_params(@_);
    $params->{os} ||= $self;
    $self->_scroll_class->new($params);
}


sub _build_asynchronous_search   { shift->_build_namespace('AsyncSearch') }
sub _build_cat                   { shift->_build_namespace('Cat') }
sub _build_cluster               { shift->_build_namespace('Cluster') }
sub _build_dangling_indices      { shift->_build_namespace('DanglingIndices') }
sub _build_flow_framework        { shift->_build_namespace('FlowFramework') }
sub _build_geospatial            { shift->_build_namespace('GeoSpatial') }
sub _build_indices               { shift->_build_namespace('Indices') }
sub _build_ingest                { shift->_build_namespace('Ingest') }
sub _build_ingestion             { shift->_build_namespace('Ingestion') }
sub _build_insights              { shift->_build_namespace('Insights') }
sub _build_ism                   { shift->_build_namespace('ISM') }
sub _build_knn                   { shift->_build_namespace('KNN') }
sub _build_list                  { shift->_build_namespace('List') }
sub _build_ltr                   { shift->_build_namespace('LTR') }
sub _build_ml                    { shift->_build_namespace('ML') }
sub _build_neural                { shift->_build_namespace('Neural') }
sub _build_nodes                 { shift->_build_namespace('Nodes') }
sub _build_notifications         { shift->_build_namespace('Notifications') }
sub _build_observability         { shift->_build_namespace('Observability') }
sub _build_ppl                   { shift->_build_namespace('PPL') }
sub _build_query                 { shift->_build_namespace('Query') }
sub _build_remote_store          { shift->_build_namespace('RemoteStore') }
sub _build_replication           { shift->_build_namespace('Replication') }
sub _build_rollups               { shift->_build_namespace('Rollups') }
sub _build_search_pipeline       { shift->_build_namespace('SearchPipeline') }
sub _build_search_relevance      { shift->_build_namespace('SearchRelevance') }
sub _build_security              { shift->_build_namespace('Security') }
sub _build_security_analytics    { shift->_build_namespace('SecurityAnalytics') }
sub _build_sm                    { shift->_build_namespace('SnapshotManagement') }
sub _build_snapshot              { shift->_build_namespace('Snapshot') }
sub _build_sql                   { shift->_build_namespace('SQL') }
sub _build_tasks                 { shift->_build_namespace('Tasks') }
sub _build_transforms            { shift->_build_namespace('Transforms') }
sub _build_ubi                   { shift->_build_namespace('UBI') }
sub _build_wlm                   { shift->_build_namespace('WLM') }

__PACKAGE__->_install_api('_core');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct>

=head1 VERSION

version 3.007008

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->search(
     index => 'my_index',
     body  => $body_hash_ref
  );

=head1 DESCRIPTION

Provides the top level methods for OpenSearch::Client, such as

=over

=item *

C<$client-E<gt>search( 'index' =E<gt> 'my_index', 'body' =E<gt> $searchdef )>

=item *

C<$client-E<gt>create( 'index' =E<gt> 'an_index', 'body' =E<gt> $indexdef )>

=back

L<See OpenSearch documentation for $client|https://docs.opensearch.org/latest/api-reference/>

=head1 METHODS
    
=head2 bulk

Allows to perform multiple index/update/delete operations in a single request.


I<Paths served by this method:>

=over

=item
C<POST /_bulk>

=item
C<POST /{index}/_bulk>

=item
C<PUT /_bulk>

=item
C<PUT /{index}/_bulk>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->bulk(
        
        'body'                    =>  $body,      # required
        
         # path parameters
        
        'index'                   =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        '_source'                 =>  $qval1,     # list
        '_source_excludes'        =>  $qval2,     # list
        '_source_includes'        =>  $qval3,     # list
        'index'                   =>  $qval4,     # string
        'pipeline'                =>  $qval5,     # string
        'refresh'                 =>  $qval6,     # boolean|string
        'require_alias'           =>  $qval7,     # boolean
        'routing'                 =>  $qval8,     # string
        'timeout'                 =>  $qval9,     # string
        'type'                    =>  $qval10,    # string
        'wait_for_active_shards'  =>  $qval11,    # string
        
         # Common API query string parameters
        
        'error_trace'             =>  $qval12,    # boolean
        'filter_path'             =>  $qval13,    # list
        'human'                   =>  $qval14,    # boolean
        'pretty'                  =>  $qval15,    # boolean
        'source'                  =>  $qval16,    # string
    );

L<OpenSearch documentation for bulk|https://opensearch.org/docs/latest/api-reference/document-apis/bulk/>
    
=head2 bulk_stream

Allows to perform multiple index/update/delete operations using request response streaming.


I<Paths served by this method:>

=over

=item
C<POST /_bulk/stream>

=item
C<POST /{index}/_bulk/stream>

=item
C<PUT /_bulk/stream>

=item
C<PUT /{index}/_bulk/stream>

=back

I<Method added in OpenSearch version 2.17>


    $resp = $client->bulk_stream(
        
        'body'                    =>  $body,      # required
        
         # path parameters
        
        'index'                   =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        '_source'                 =>  $qval1,     # list
        '_source_excludes'        =>  $qval2,     # list
        '_source_includes'        =>  $qval3,     # list
        'batch_interval'          =>  $qval4,     # string
        'batch_size'              =>  $qval5,     # number
        'pipeline'                =>  $qval6,     # string
        'refresh'                 =>  $qval7,     # boolean|string
        'require_alias'           =>  $qval8,     # boolean
        'routing'                 =>  $qval9,     # list
        'timeout'                 =>  $qval10,    # string
        'type'                    =>  $qval11,    # string
        'wait_for_active_shards'  =>  $qval12,    # string
        
         # Common API query string parameters
        
        'error_trace'             =>  $qval13,    # boolean
        'filter_path'             =>  $qval14,    # list
        'human'                   =>  $qval15,    # boolean
        'pretty'                  =>  $qval16,    # boolean
        'source'                  =>  $qval17,    # string
    );

L<OpenSearch documentation for bulk_stream|https://opensearch.org/docs/latest/api-reference/document-apis/bulk-streaming/>
    
=head2 clear_scroll

Explicitly clears the search context for a scroll.


I<Paths served by this method:>

=over

=item
C<DELETE /_search/scroll>

=item
C<DELETE /_search/scroll/{scroll_id}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->clear_scroll(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'scroll_id'    =>  $scroll_id,  # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for clear_scroll|https://opensearch.org/docs/latest/api-reference/scroll/>
    
=head2 count

Returns number of documents matching a query.


I<Paths served by this method:>

=over

=item
C<GET /_count>

=item
C<GET /{index}/_count>

=item
C<POST /_count>

=item
C<POST /{index}/_count>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->count(
        
        'body'                =>  $body,      # optional
        
         # path parameters
        
        'index'               =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'    =>  $qval1,     # boolean
        'analyze_wildcard'    =>  $qval2,     # boolean
        'analyzer'            =>  $qval3,     # string
        'default_operator'    =>  $qval4,     # string
        'df'                  =>  $qval5,     # string
        'expand_wildcards'    =>  $qval6,     # list
        'ignore_throttled'    =>  $qval7,     # boolean
        'ignore_unavailable'  =>  $qval8,     # boolean
        'lenient'             =>  $qval9,     # boolean
        'min_score'           =>  $qval10,    # number
        'preference'          =>  $qval11,    # string
        'q'                   =>  $qval12,    # string
        'routing'             =>  $qval13,    # list
        'terminate_after'     =>  $qval14,    # number
        
         # Common API query string parameters
        
        'error_trace'         =>  $qval15,    # boolean
        'filter_path'         =>  $qval16,    # list
        'human'               =>  $qval17,    # boolean
        'pretty'              =>  $qval18,    # boolean
        'source'              =>  $qval19,    # string
    );

L<OpenSearch documentation for count|https://opensearch.org/docs/latest/api-reference/count/>
    
=head2 create

Creates a new document in the index.

Returns a 409 response when a document with a same ID already exists in the index.


I<Paths served by this method:>

=over

=item
C<POST /{index}/_create/{id}>

=item
C<PUT /{index}/_create/{id}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->create(
        
        'body'                    =>  $body,      # required
        
         # path parameters
        
        'id'                      =>  $id,        # required
        'index'                   =>  $index,     # required
        
         # Endpoint specific query string parameters
        
        'pipeline'                =>  $qval1,     # string
        'refresh'                 =>  $qval2,     # boolean|string
        'routing'                 =>  $qval3,     # list
        'timeout'                 =>  $qval4,     # string
        'version'                 =>  $qval5,     # number
        'version_type'            =>  $qval6,     # string
        'wait_for_active_shards'  =>  $qval7,     # string
        
         # Common API query string parameters
        
        'error_trace'             =>  $qval8,     # boolean
        'filter_path'             =>  $qval9,     # list
        'human'                   =>  $qval10,    # boolean
        'pretty'                  =>  $qval11,    # boolean
        'source'                  =>  $qval12,    # string
    );

L<OpenSearch documentation for create|https://opensearch.org/docs/latest/api-reference/document-apis/index-document/>
    
=head2 create_pit

Creates point in time context.


I<Paths served by this method:>

=over

=item
C<POST /{index}/_search/point_in_time>

=back

I<Method added in OpenSearch version 2.4>


    $resp = $client->create_pit(
        
         # path parameters
        
        'index'                       =>  $index,     # required
        
         # Endpoint specific query string parameters
        
        'allow_partial_pit_creation'  =>  $qval1,     # boolean
        'expand_wildcards'            =>  $qval2,     # list
        'keep_alive'                  =>  $qval3,     # string
        'preference'                  =>  $qval4,     # string
        'routing'                     =>  $qval5,     # list
        
         # Common API query string parameters
        
        'error_trace'                 =>  $qval6,     # boolean
        'filter_path'                 =>  $qval7,     # list
        'human'                       =>  $qval8,     # boolean
        'pretty'                      =>  $qval9,     # boolean
        'source'                      =>  $qval10,    # string
    );

L<OpenSearch documentation for create_pit|https://opensearch.org/docs/latest/search-plugins/point-in-time-api/#create-a-pit>
    
=head2 delete

Removes a document from the index.


I<Paths served by this method:>

=over

=item
C<DELETE /{index}/_doc/{id}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->delete(
        
         # path parameters
        
        'id'                      =>  $id,        # required
        'index'                   =>  $index,     # required
        
         # Endpoint specific query string parameters
        
        'if_primary_term'         =>  $qval1,     # number
        'if_seq_no'               =>  $qval2,     # number
        'refresh'                 =>  $qval3,     # boolean|string
        'routing'                 =>  $qval4,     # list
        'timeout'                 =>  $qval5,     # string
        'version'                 =>  $qval6,     # number
        'version_type'            =>  $qval7,     # string
        'wait_for_active_shards'  =>  $qval8,     # string
        
         # Common API query string parameters
        
        'error_trace'             =>  $qval9,     # boolean
        'filter_path'             =>  $qval10,    # list
        'human'                   =>  $qval11,    # boolean
        'pretty'                  =>  $qval12,    # boolean
        'source'                  =>  $qval13,    # string
    );

L<OpenSearch documentation for delete|https://opensearch.org/docs/latest/api-reference/document-apis/delete-document/>
    
=head2 delete_all_pits

Deletes all active point in time searches.


I<Paths served by this method:>

=over

=item
C<DELETE /_search/point_in_time/_all>

=back

I<Method added in OpenSearch version 2.4>


    $resp = $client->delete_all_pits(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for delete_all_pits|https://opensearch.org/docs/latest/search-plugins/point-in-time-api/#delete-pits>
    
=head2 delete_by_query

Deletes documents matching the provided query.


I<Paths served by this method:>

=over

=item
C<POST /{index}/_delete_by_query>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->delete_by_query(
        
        'body'                    =>  $body,      # optional
        
         # path parameters
        
        'index'                   =>  $index,     # required
        
         # Endpoint specific query string parameters
        
        '_source'                 =>  $qval1,     # list
        '_source_excludes'        =>  $qval2,     # list
        '_source_includes'        =>  $qval3,     # list
        'allow_no_indices'        =>  $qval4,     # boolean
        'analyze_wildcard'        =>  $qval5,     # boolean
        'analyzer'                =>  $qval6,     # string
        'conflicts'               =>  $qval7,     # string
        'default_operator'        =>  $qval8,     # string
        'df'                      =>  $qval9,     # string
        'expand_wildcards'        =>  $qval10,    # list
        'from'                    =>  $qval11,    # number
        'ignore_unavailable'      =>  $qval12,    # boolean
        'lenient'                 =>  $qval13,    # boolean
        'max_docs'                =>  $qval14,    # number
        'preference'              =>  $qval15,    # string
        'q'                       =>  $qval16,    # string
        'refresh'                 =>  $qval17,    # boolean|string
        'request_cache'           =>  $qval18,    # boolean
        'requests_per_second'     =>  $qval19,    # number
        'routing'                 =>  $qval20,    # list
        'scroll'                  =>  $qval21,    # string
        'scroll_size'             =>  $qval22,    # number
        'search_timeout'          =>  $qval23,    # string
        'search_type'             =>  $qval24,    # string
        'size'                    =>  $qval25,    # number
        'slices'                  =>  $qval26,    # number|string
        'sort'                    =>  $qval27,    # list
        'stats'                   =>  $qval28,    # list
        'terminate_after'         =>  $qval29,    # number
        'timeout'                 =>  $qval30,    # string
        'version'                 =>  $qval31,    # boolean
        'wait_for_active_shards'  =>  $qval32,    # string
        'wait_for_completion'     =>  $qval33,    # boolean
        
         # Common API query string parameters
        
        'error_trace'             =>  $qval34,    # boolean
        'filter_path'             =>  $qval35,    # list
        'human'                   =>  $qval36,    # boolean
        'pretty'                  =>  $qval37,    # boolean
        'source'                  =>  $qval38,    # string
    );

L<OpenSearch documentation for delete_by_query|https://opensearch.org/docs/latest/api-reference/document-apis/delete-by-query/>
    
=head2 delete_by_query_rethrottle

Changes the number of requests per second for a particular Delete By Query operation.


I<Paths served by this method:>

=over

=item
C<POST /_delete_by_query/{task_id}/_rethrottle>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->delete_by_query_rethrottle(
        
         # path parameters
        
        'task_id'              =>  $task_id,   # required
        
         # Endpoint specific query string parameters
        
        'requests_per_second'  =>  $qval1,     # number
        
         # Common API query string parameters
        
        'error_trace'          =>  $qval2,     # boolean
        'filter_path'          =>  $qval3,     # list
        'human'                =>  $qval4,     # boolean
        'pretty'               =>  $qval5,     # boolean
        'source'               =>  $qval6,     # string
    );

L<OpenSearch documentation for delete_by_query_rethrottle|https://docs.opensearch.org/latest/api-reference/>
    
=head2 delete_pit

Deletes one or more point in time searches based on the IDs passed.


I<Paths served by this method:>

=over

=item
C<DELETE /_search/point_in_time>

=back

I<Method added in OpenSearch version 2.4>


    $resp = $client->delete_pit(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for delete_pit|https://opensearch.org/docs/latest/search-plugins/point-in-time-api/#delete-pits>
    
=head2 delete_script

Deletes a script.


I<Paths served by this method:>

=over

=item
C<DELETE /_scripts/{id}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->delete_script(
        
         # path parameters
        
        'id'                       =>  $id,        # required
        
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

L<OpenSearch documentation for delete_script|https://opensearch.org/docs/latest/api-reference/script-apis/delete-script/>
    
=head2 exists

Returns information about whether a document exists in an index.


I<Paths served by this method:>

=over

=item
C<HEAD /{index}/_doc/{id}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->exists(
        
         # path parameters
        
        'id'                =>  $id,        # required
        'index'             =>  $index,     # required
        
         # Endpoint specific query string parameters
        
        '_source'           =>  $qval1,     # list
        '_source_excludes'  =>  $qval2,     # list
        '_source_includes'  =>  $qval3,     # list
        'preference'        =>  $qval4,     # string
        'realtime'          =>  $qval5,     # boolean
        'refresh'           =>  $qval6,     # boolean|string
        'routing'           =>  $qval7,     # list
        'stored_fields'     =>  $qval8,     # list
        'version'           =>  $qval9,     # number
        'version_type'      =>  $qval10,    # string
        
         # Common API query string parameters
        
        'error_trace'       =>  $qval11,    # boolean
        'filter_path'       =>  $qval12,    # list
        'human'             =>  $qval13,    # boolean
        'pretty'            =>  $qval14,    # boolean
        'source'            =>  $qval15,    # string
    );

L<OpenSearch documentation for exists|https://opensearch.org/docs/latest/api-reference/document-apis/get-documents/>
    
=head2 exists_source

Returns information about whether a document source exists in an index.


I<Paths served by this method:>

=over

=item
C<HEAD /{index}/_source/{id}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->exists_source(
        
         # path parameters
        
        'id'                =>  $id,        # required
        'index'             =>  $index,     # required
        
         # Endpoint specific query string parameters
        
        '_source'           =>  $qval1,     # list
        '_source_excludes'  =>  $qval2,     # list
        '_source_includes'  =>  $qval3,     # list
        'preference'        =>  $qval4,     # string
        'realtime'          =>  $qval5,     # boolean
        'refresh'           =>  $qval6,     # boolean|string
        'routing'           =>  $qval7,     # list
        'version'           =>  $qval8,     # number
        'version_type'      =>  $qval9,     # string
        
         # Common API query string parameters
        
        'error_trace'       =>  $qval10,    # boolean
        'filter_path'       =>  $qval11,    # list
        'human'             =>  $qval12,    # boolean
        'pretty'            =>  $qval13,    # boolean
        'source'            =>  $qval14,    # string
    );

L<OpenSearch documentation for exists_source|https://opensearch.org/docs/latest/api-reference/document-apis/get-documents/>
    
=head2 explain

Returns information about why a specific document matches (or doesn't match) a query.


I<Paths served by this method:>

=over

=item
C<GET /{index}/_explain/{id}>

=item
C<POST /{index}/_explain/{id}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->explain(
        
        'body'              =>  $body,      # optional
        
         # path parameters
        
        'id'                =>  $id,        # required
        'index'             =>  $index,     # required
        
         # Endpoint specific query string parameters
        
        '_source'           =>  $qval1,     # list
        '_source_excludes'  =>  $qval2,     # list
        '_source_includes'  =>  $qval3,     # list
        'analyze_wildcard'  =>  $qval4,     # boolean
        'analyzer'          =>  $qval5,     # string
        'default_operator'  =>  $qval6,     # string
        'df'                =>  $qval7,     # string
        'lenient'           =>  $qval8,     # boolean
        'preference'        =>  $qval9,     # string
        'q'                 =>  $qval10,    # string
        'routing'           =>  $qval11,    # list
        'stored_fields'     =>  $qval12,    # list
        
         # Common API query string parameters
        
        'error_trace'       =>  $qval13,    # boolean
        'filter_path'       =>  $qval14,    # list
        'human'             =>  $qval15,    # boolean
        'pretty'            =>  $qval16,    # boolean
        'source'            =>  $qval17,    # string
    );

L<OpenSearch documentation for explain|https://opensearch.org/docs/latest/api-reference/explain/>
    
=head2 field_caps

Returns the information about the capabilities of fields among multiple indexes.


I<Paths served by this method:>

=over

=item
C<GET /_field_caps>

=item
C<GET /{index}/_field_caps>

=item
C<POST /_field_caps>

=item
C<POST /{index}/_field_caps>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->field_caps(
        
        'body'                =>  $body,      # optional
        
         # path parameters
        
        'index'               =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'    =>  $qval1,     # boolean
        'expand_wildcards'    =>  $qval2,     # list
        'fields'              =>  $qval3,     # list
        'ignore_unavailable'  =>  $qval4,     # boolean
        'include_unmapped'    =>  $qval5,     # boolean
        
         # Common API query string parameters
        
        'error_trace'         =>  $qval6,     # boolean
        'filter_path'         =>  $qval7,     # list
        'human'               =>  $qval8,     # boolean
        'pretty'              =>  $qval9,     # boolean
        'source'              =>  $qval10,    # string
    );

L<OpenSearch documentation for field_caps|https://opensearch.org/docs/latest/field-types/supported-field-types/alias/#using-aliases-in-field-capabilities-api-operations>
    
=head2 get

Returns a document.


I<Paths served by this method:>

=over

=item
C<GET /{index}/_doc/{id}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->get(
        
         # path parameters
        
        'id'                =>  $id,        # required
        'index'             =>  $index,     # required
        
         # Endpoint specific query string parameters
        
        '_source'           =>  $qval1,     # list
        '_source_excludes'  =>  $qval2,     # list
        '_source_includes'  =>  $qval3,     # list
        'preference'        =>  $qval4,     # string
        'realtime'          =>  $qval5,     # boolean
        'refresh'           =>  $qval6,     # boolean|string
        'routing'           =>  $qval7,     # list
        'stored_fields'     =>  $qval8,     # list
        'version'           =>  $qval9,     # number
        'version_type'      =>  $qval10,    # string
        
         # Common API query string parameters
        
        'error_trace'       =>  $qval11,    # boolean
        'filter_path'       =>  $qval12,    # list
        'human'             =>  $qval13,    # boolean
        'pretty'            =>  $qval14,    # boolean
        'source'            =>  $qval15,    # string
    );

L<OpenSearch documentation for get|https://opensearch.org/docs/latest/api-reference/document-apis/get-documents/>
    
=head2 get_all_pits

Lists all active point in time searches.


I<Paths served by this method:>

=over

=item
C<GET /_search/point_in_time/_all>

=back

I<Method added in OpenSearch version 2.4>


    $resp = $client->get_all_pits(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for get_all_pits|https://opensearch.org/docs/latest/search-plugins/point-in-time-api/#list-all-pits>
    
=head2 get_script

Returns a script.


I<Paths served by this method:>

=over

=item
C<GET /_scripts/{id}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->get_script(
        
         # path parameters
        
        'id'                       =>  $id,        # required
        
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

L<OpenSearch documentation for get_script|https://opensearch.org/docs/latest/api-reference/script-apis/get-stored-script/>
    
=head2 get_script_context

Returns all script contexts.


I<Paths served by this method:>

=over

=item
C<GET /_script_context>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->get_script_context(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for get_script_context|https://opensearch.org/docs/latest/api-reference/script-apis/get-script-contexts/>
    
=head2 get_script_languages

Returns available script types, languages and contexts.


I<Paths served by this method:>

=over

=item
C<GET /_script_language>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->get_script_languages(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for get_script_languages|https://opensearch.org/docs/latest/api-reference/script-apis/get-script-language/>
    
=head2 get_source

Returns the source of a document.


I<Paths served by this method:>

=over

=item
C<GET /{index}/_source/{id}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->get_source(
        
         # path parameters
        
        'id'                =>  $id,        # required
        'index'             =>  $index,     # required
        
         # Endpoint specific query string parameters
        
        '_source'           =>  $qval1,     # list
        '_source_excludes'  =>  $qval2,     # list
        '_source_includes'  =>  $qval3,     # list
        'preference'        =>  $qval4,     # string
        'realtime'          =>  $qval5,     # boolean
        'refresh'           =>  $qval6,     # boolean|string
        'routing'           =>  $qval7,     # list
        'version'           =>  $qval8,     # number
        'version_type'      =>  $qval9,     # string
        
         # Common API query string parameters
        
        'error_trace'       =>  $qval10,    # boolean
        'filter_path'       =>  $qval11,    # list
        'human'             =>  $qval12,    # boolean
        'pretty'            =>  $qval13,    # boolean
        'source'            =>  $qval14,    # string
    );

L<OpenSearch documentation for get_source|https://opensearch.org/docs/latest/api-reference/document-apis/get-documents/>
    
=head2 index

Creates or updates a document in an index.


I<Paths served by this method:>

=over

=item
C<POST /{index}/_doc>

=item
C<POST /{index}/_doc/{id}>

=item
C<PUT /{index}/_doc/{id}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->index(
        
        'body'                    =>  $body,      # optional
        
         # path parameters
        
        'id'                      =>  $id,        # optional
        'index'                   =>  $index,     # required
        
         # Endpoint specific query string parameters
        
        'if_primary_term'         =>  $qval1,     # number
        'if_seq_no'               =>  $qval2,     # number
        'op_type'                 =>  $qval3,     # string
        'pipeline'                =>  $qval4,     # string
        'refresh'                 =>  $qval5,     # boolean|string
        'require_alias'           =>  $qval6,     # boolean
        'routing'                 =>  $qval7,     # list
        'timeout'                 =>  $qval8,     # string
        'version'                 =>  $qval9,     # number
        'version_type'            =>  $qval10,    # string
        'wait_for_active_shards'  =>  $qval11,    # string
        
         # Common API query string parameters
        
        'error_trace'             =>  $qval12,    # boolean
        'filter_path'             =>  $qval13,    # list
        'human'                   =>  $qval14,    # boolean
        'pretty'                  =>  $qval15,    # boolean
        'source'                  =>  $qval16,    # string
    );

L<OpenSearch documentation for index|https://opensearch.org/docs/latest/api-reference/document-apis/index-document/>
    
=head2 info

Returns basic information about the cluster.


I<Paths served by this method:>

=over

=item
C<GET />

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->info();

L<OpenSearch documentation for info|https://docs.opensearch.org/latest/api-reference/>
    
=head2 mget

Allows to get multiple documents in one request.


I<Paths served by this method:>

=over

=item
C<GET /_mget>

=item
C<GET /{index}/_mget>

=item
C<POST /_mget>

=item
C<POST /{index}/_mget>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->mget(
        
        'body'              =>  $body,      # required
        
         # path parameters
        
        'index'             =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        '_source'           =>  $qval1,     # list
        '_source_excludes'  =>  $qval2,     # list
        '_source_includes'  =>  $qval3,     # list
        'preference'        =>  $qval4,     # string
        'realtime'          =>  $qval5,     # boolean
        'refresh'           =>  $qval6,     # boolean|string
        'routing'           =>  $qval7,     # list
        'stored_fields'     =>  $qval8,     # list
        
         # Common API query string parameters
        
        'error_trace'       =>  $qval9,     # boolean
        'filter_path'       =>  $qval10,    # list
        'human'             =>  $qval11,    # boolean
        'pretty'            =>  $qval12,    # boolean
        'source'            =>  $qval13,    # string
    );

L<OpenSearch documentation for mget|https://opensearch.org/docs/latest/api-reference/document-apis/multi-get/>
    
=head2 msearch

Allows to execute several search operations in one request.


I<Paths served by this method:>

=over

=item
C<GET /_msearch>

=item
C<GET /{index}/_msearch>

=item
C<POST /_msearch>

=item
C<POST /{index}/_msearch>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->msearch(
        
        'body'                           =>  $body,      # required
        
         # path parameters
        
        'index'                          =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'allow_partial_results'          =>  $qval1,     # boolean
        'ccs_minimize_roundtrips'        =>  $qval2,     # boolean
        'max_concurrent_searches'        =>  $qval3,     # number
        'max_concurrent_shard_requests'  =>  $qval4,     # number
        'pre_filter_shard_size'          =>  $qval5,     # number
        'rest_total_hits_as_int'         =>  $qval6,     # boolean
        'search_type'                    =>  $qval7,     # string
        'typed_keys'                     =>  $qval8,     # boolean
        
         # Common API query string parameters
        
        'error_trace'                    =>  $qval9,     # boolean
        'filter_path'                    =>  $qval10,    # list
        'human'                          =>  $qval11,    # boolean
        'pretty'                         =>  $qval12,    # boolean
        'source'                         =>  $qval13,    # string
    );

L<OpenSearch documentation for msearch|https://opensearch.org/docs/latest/api-reference/multi-search/>
    
=head2 msearch_template

Allows to execute several search template operations in one request.


I<Paths served by this method:>

=over

=item
C<GET /_msearch/template>

=item
C<GET /{index}/_msearch/template>

=item
C<POST /_msearch/template>

=item
C<POST /{index}/_msearch/template>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->msearch_template(
        
        'body'                     =>  $body,      # required
        
         # path parameters
        
        'index'                    =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'ccs_minimize_roundtrips'  =>  $qval1,     # boolean
        'max_concurrent_searches'  =>  $qval2,     # number
        'rest_total_hits_as_int'   =>  $qval3,     # boolean
        'search_type'              =>  $qval4,     # string
        'typed_keys'               =>  $qval5,     # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval6,     # boolean
        'filter_path'              =>  $qval7,     # list
        'human'                    =>  $qval8,     # boolean
        'pretty'                   =>  $qval9,     # boolean
        'source'                   =>  $qval10,    # string
    );

L<OpenSearch documentation for msearch_template|https://opensearch.org/docs/latest/search-plugins/search-template/>
    
=head2 mtermvectors

Returns multiple termvectors in one request.


I<Paths served by this method:>

=over

=item
C<GET /_mtermvectors>

=item
C<GET /{index}/_mtermvectors>

=item
C<POST /_mtermvectors>

=item
C<POST /{index}/_mtermvectors>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->mtermvectors(
        
        'body'              =>  $body,      # optional
        
         # path parameters
        
        'index'             =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'field_statistics'  =>  $qval1,     # boolean
        'fields'            =>  $qval2,     # list
        'ids'               =>  $qval3,     # list
        'offsets'           =>  $qval4,     # boolean
        'payloads'          =>  $qval5,     # boolean
        'positions'         =>  $qval6,     # boolean
        'preference'        =>  $qval7,     # string
        'realtime'          =>  $qval8,     # boolean
        'routing'           =>  $qval9,     # list
        'term_statistics'   =>  $qval10,    # boolean
        'version'           =>  $qval11,    # number
        'version_type'      =>  $qval12,    # string
        
         # Common API query string parameters
        
        'error_trace'       =>  $qval13,    # boolean
        'filter_path'       =>  $qval14,    # list
        'human'             =>  $qval15,    # boolean
        'pretty'            =>  $qval16,    # boolean
        'source'            =>  $qval17,    # string
    );

L<OpenSearch documentation for mtermvectors|https://docs.opensearch.org/latest/api-reference/>
    
=head2 ping

Returns whether the cluster is running.


I<Paths served by this method:>

=over

=item
C<HEAD />

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->ping(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ping|https://docs.opensearch.org/latest/api-reference/>
    
=head2 put_script

Creates or updates a script.


I<Paths served by this method:>

=over

=item
C<POST /_scripts/{id}>

=item
C<POST /_scripts/{id}/{context}>

=item
C<PUT /_scripts/{id}>

=item
C<PUT /_scripts/{id}/{context}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->put_script(
        
        'body'                     =>  $body,      # required
        
         # path parameters
        
        'context'                  =>  $context,   # optional
        'id'                       =>  $id,        # required
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'context'                  =>  $qval2,     # string
        'master_timeout'           =>  $qval3,     # string
        'timeout'                  =>  $qval4,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval5,     # boolean
        'filter_path'              =>  $qval6,     # list
        'human'                    =>  $qval7,     # boolean
        'pretty'                   =>  $qval8,     # boolean
        'source'                   =>  $qval9,     # string
    );

L<OpenSearch documentation for put_script|https://opensearch.org/docs/latest/api-reference/script-apis/create-stored-script/>
    
=head2 rank_eval

Allows to evaluate the quality of ranked search results over a set of typical search queries.


I<Paths served by this method:>

=over

=item
C<GET /_rank_eval>

=item
C<GET /{index}/_rank_eval>

=item
C<POST /_rank_eval>

=item
C<POST /{index}/_rank_eval>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->rank_eval(
        
        'body'                =>  $body,      # required
        
         # path parameters
        
        'index'               =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'    =>  $qval1,     # boolean
        'expand_wildcards'    =>  $qval2,     # list
        'ignore_unavailable'  =>  $qval3,     # boolean
        'search_type'         =>  $qval4,     # string
        
         # Common API query string parameters
        
        'error_trace'         =>  $qval5,     # boolean
        'filter_path'         =>  $qval6,     # list
        'human'               =>  $qval7,     # boolean
        'pretty'              =>  $qval8,     # boolean
        'source'              =>  $qval9,     # string
    );

L<OpenSearch documentation for rank_eval|https://opensearch.org/docs/latest/api-reference/rank-eval/>
    
=head2 reindex

Allows to copy documents from one index to another, optionally filtering the source
documents by a query, changing the destination index settings, or fetching the
documents from a remote cluster.


I<Paths served by this method:>

=over

=item
C<POST /_reindex>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->reindex(
        
        'body'                    =>  $body,      # optional
        
         # Endpoint specific query string parameters
        
        'max_docs'                =>  $qval1,     # number
        'refresh'                 =>  $qval2,     # boolean|string
        'requests_per_second'     =>  $qval3,     # number
        'require_alias'           =>  $qval4,     # boolean
        'scroll'                  =>  $qval5,     # string
        'slices'                  =>  $qval6,     # number|string
        'timeout'                 =>  $qval7,     # string
        'wait_for_active_shards'  =>  $qval8,     # string
        'wait_for_completion'     =>  $qval9,     # boolean
        
         # Common API query string parameters
        
        'error_trace'             =>  $qval10,    # boolean
        'filter_path'             =>  $qval11,    # list
        'human'                   =>  $qval12,    # boolean
        'pretty'                  =>  $qval13,    # boolean
        'source'                  =>  $qval14,    # string
    );

L<OpenSearch documentation for reindex|https://opensearch.org/docs/latest/im-plugin/reindex-data/>
    
=head2 reindex_rethrottle

Changes the number of requests per second for a particular reindex operation.


I<Paths served by this method:>

=over

=item
C<POST /_reindex/{task_id}/_rethrottle>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->reindex_rethrottle(
        
         # path parameters
        
        'task_id'              =>  $task_id,   # required
        
         # Endpoint specific query string parameters
        
        'requests_per_second'  =>  $qval1,     # number
        
         # Common API query string parameters
        
        'error_trace'          =>  $qval2,     # boolean
        'filter_path'          =>  $qval3,     # list
        'human'                =>  $qval4,     # boolean
        'pretty'               =>  $qval5,     # boolean
        'source'               =>  $qval6,     # string
    );

L<OpenSearch documentation for reindex_rethrottle|https://docs.opensearch.org/latest/api-reference/>
    
=head2 render_search_template

Allows to use the Mustache language to pre-render a search definition.


I<Paths served by this method:>

=over

=item
C<GET /_render/template>

=item
C<GET /_render/template/{id}>

=item
C<POST /_render/template>

=item
C<POST /_render/template/{id}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->render_search_template(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'id'           =>  $id,        # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for render_search_template|https://opensearch.org/docs/latest/search-plugins/search-template/>
    
=head2 scripts_painless_execute

Allows an arbitrary script to be executed and a result to be returned.


I<Paths served by this method:>

=over

=item
C<GET /_scripts/painless/_execute>

=item
C<POST /_scripts/painless/_execute>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->scripts_painless_execute(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for scripts_painless_execute|https://opensearch.org/docs/latest/api-reference/script-apis/exec-script/>
    
=head2 scroll

Allows to retrieve a large numbers of results from a single search request.


I<Paths served by this method:>

=over

=item
C<GET /_search/scroll>

=item
C<GET /_search/scroll/{scroll_id}>

=item
C<POST /_search/scroll>

=item
C<POST /_search/scroll/{scroll_id}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->scroll(
        
        'body'                    =>  $body,      # optional
        
         # path parameters
        
        'scroll_id'               =>  $scroll_id,  # optional
        
         # Endpoint specific query string parameters
        
        'rest_total_hits_as_int'  =>  $qval1,     # boolean
        'scroll'                  =>  $qval2,     # string
        'scroll_id'               =>  $qval3,     # string
        
         # Common API query string parameters
        
        'error_trace'             =>  $qval4,     # boolean
        'filter_path'             =>  $qval5,     # list
        'human'                   =>  $qval6,     # boolean
        'pretty'                  =>  $qval7,     # boolean
        'source'                  =>  $qval8,     # string
    );

L<OpenSearch documentation for scroll|https://opensearch.org/docs/latest/api-reference/scroll/#path-and-http-methods>
    
=head2 search

Returns results matching a query.


I<Paths served by this method:>

=over

=item
C<GET /_search>

=item
C<GET /{index}/_search>

=item
C<POST /_search>

=item
C<POST /{index}/_search>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->search(
        
        'body'                           =>  $body,      # optional
        
         # path parameters
        
        'index'                          =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        '_source'                        =>  $qval1,     # list
        '_source_excludes'               =>  $qval2,     # list
        '_source_includes'               =>  $qval3,     # list
        'allow_no_indices'               =>  $qval4,     # boolean
        'allow_partial_search_results'   =>  $qval5,     # boolean
        'analyze_wildcard'               =>  $qval6,     # boolean
        'analyzer'                       =>  $qval7,     # string
        'batched_reduce_size'            =>  $qval8,     # number
        'cancel_after_time_interval'     =>  $qval9,     # string
        'ccs_minimize_roundtrips'        =>  $qval10,    # boolean
        'default_operator'               =>  $qval11,    # string
        'df'                             =>  $qval12,    # string
        'docvalue_fields'                =>  $qval13,    # list
        'expand_wildcards'               =>  $qval14,    # list
        'explain'                        =>  $qval15,    # boolean
        'from'                           =>  $qval16,    # number
        'ignore_throttled'               =>  $qval17,    # boolean
        'ignore_unavailable'             =>  $qval18,    # boolean
        'include_named_queries_score'    =>  $qval19,    # boolean
        'index'                          =>  $qval20,    # list
        'lenient'                        =>  $qval21,    # boolean
        'max_concurrent_shard_requests'  =>  $qval22,    # number
        'phase_took'                     =>  $qval23,    # boolean
        'pre_filter_shard_size'          =>  $qval24,    # number
        'preference'                     =>  $qval25,    # string
        'q'                              =>  $qval26,    # string
        'request_cache'                  =>  $qval27,    # boolean
        'rest_total_hits_as_int'         =>  $qval28,    # boolean
        'routing'                        =>  $qval29,    # list
        'scroll'                         =>  $qval30,    # string
        'search_pipeline'                =>  $qval31,    # string
        'search_type'                    =>  $qval32,    # string
        'seq_no_primary_term'            =>  $qval33,    # boolean
        'size'                           =>  $qval34,    # number
        'sort'                           =>  $qval35,    # list
        'stats'                          =>  $qval36,    # list
        'stored_fields'                  =>  $qval37,    # list
        'suggest_field'                  =>  $qval38,    # string
        'suggest_mode'                   =>  $qval39,    # string
        'suggest_size'                   =>  $qval40,    # number
        'suggest_text'                   =>  $qval41,    # string
        'terminate_after'                =>  $qval42,    # number
        'timeout'                        =>  $qval43,    # string
        'track_scores'                   =>  $qval44,    # boolean
        'track_total_hits'               =>  $qval45,    # boolean|number
        'typed_keys'                     =>  $qval46,    # boolean
        'verbose_pipeline'               =>  $qval47,    # boolean
        'version'                        =>  $qval48,    # boolean
        
         # Common API query string parameters
        
        'error_trace'                    =>  $qval49,    # boolean
        'filter_path'                    =>  $qval50,    # list
        'human'                          =>  $qval51,    # boolean
        'pretty'                         =>  $qval52,    # boolean
        'source'                         =>  $qval53,    # string
    );

L<OpenSearch documentation for search|https://opensearch.org/docs/latest/api-reference/search/>
    
=head2 search_shards

Returns information about the indexes and shards that a search request would be executed against.


I<Paths served by this method:>

=over

=item
C<GET /_search_shards>

=item
C<GET /{index}/_search_shards>

=item
C<POST /_search_shards>

=item
C<POST /{index}/_search_shards>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->search_shards(
        
        'body'                =>  $body,      # optional
        
         # path parameters
        
        'index'               =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'    =>  $qval1,     # boolean
        'expand_wildcards'    =>  $qval2,     # list
        'ignore_unavailable'  =>  $qval3,     # boolean
        'local'               =>  $qval4,     # boolean
        'preference'          =>  $qval5,     # string
        'routing'             =>  $qval6,     # list
        
         # Common API query string parameters
        
        'error_trace'         =>  $qval7,     # boolean
        'filter_path'         =>  $qval8,     # list
        'human'               =>  $qval9,     # boolean
        'pretty'              =>  $qval10,    # boolean
        'source'              =>  $qval11,    # string
    );

L<OpenSearch documentation for search_shards|https://docs.opensearch.org/latest/api-reference/>
    
=head2 search_template

Allows to use the Mustache language to pre-render a search definition.


I<Paths served by this method:>

=over

=item
C<GET /_search/template>

=item
C<GET /{index}/_search/template>

=item
C<POST /_search/template>

=item
C<POST /{index}/_search/template>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->search_template(
        
        'body'                     =>  $body,      # required
        
         # path parameters
        
        'index'                    =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'         =>  $qval1,     # boolean
        'ccs_minimize_roundtrips'  =>  $qval2,     # boolean
        'expand_wildcards'         =>  $qval3,     # list
        'explain'                  =>  $qval4,     # boolean
        'ignore_throttled'         =>  $qval5,     # boolean
        'ignore_unavailable'       =>  $qval6,     # boolean
        'phase_took'               =>  $qval7,     # boolean
        'preference'               =>  $qval8,     # string
        'profile'                  =>  $qval9,     # boolean
        'rest_total_hits_as_int'   =>  $qval10,    # boolean
        'routing'                  =>  $qval11,    # list
        'scroll'                   =>  $qval12,    # string
        'search_pipeline'          =>  $qval13,    # string
        'search_type'              =>  $qval14,    # string
        'typed_keys'               =>  $qval15,    # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval16,    # boolean
        'filter_path'              =>  $qval17,    # list
        'human'                    =>  $qval18,    # boolean
        'pretty'                   =>  $qval19,    # boolean
        'source'                   =>  $qval20,    # string
    );

L<OpenSearch documentation for search_template|https://opensearch.org/docs/latest/search-plugins/search-template/>
    
=head2 termvectors

Returns information and statistics about terms in the fields of a particular document.


I<Paths served by this method:>

=over

=item
C<GET /{index}/_termvectors>

=item
C<GET /{index}/_termvectors/{id}>

=item
C<POST /{index}/_termvectors>

=item
C<POST /{index}/_termvectors/{id}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->termvectors(
        
        'body'              =>  $body,      # optional
        
         # path parameters
        
        'id'                =>  $id,        # optional
        'index'             =>  $index,     # required
        
         # Endpoint specific query string parameters
        
        'field_statistics'  =>  $qval1,     # boolean
        'fields'            =>  $qval2,     # list
        'offsets'           =>  $qval3,     # boolean
        'payloads'          =>  $qval4,     # boolean
        'positions'         =>  $qval5,     # boolean
        'preference'        =>  $qval6,     # string
        'realtime'          =>  $qval7,     # boolean
        'routing'           =>  $qval8,     # list
        'term_statistics'   =>  $qval9,     # boolean
        'version'           =>  $qval10,    # number
        'version_type'      =>  $qval11,    # string
        
         # Common API query string parameters
        
        'error_trace'       =>  $qval12,    # boolean
        'filter_path'       =>  $qval13,    # list
        'human'             =>  $qval14,    # boolean
        'pretty'            =>  $qval15,    # boolean
        'source'            =>  $qval16,    # string
    );

L<OpenSearch documentation for termvectors|https://docs.opensearch.org/latest/api-reference/>
    
=head2 update

Updates a document with a script or partial document.


I<Paths served by this method:>

=over

=item
C<POST /{index}/_update/{id}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->update(
        
        'body'                    =>  $body,      # optional
        
         # path parameters
        
        'id'                      =>  $id,        # required
        'index'                   =>  $index,     # required
        
         # Endpoint specific query string parameters
        
        '_source'                 =>  $qval1,     # list
        '_source_excludes'        =>  $qval2,     # list
        '_source_includes'        =>  $qval3,     # list
        'if_primary_term'         =>  $qval4,     # number
        'if_seq_no'               =>  $qval5,     # number
        'lang'                    =>  $qval6,     # string
        'refresh'                 =>  $qval7,     # boolean|string
        'require_alias'           =>  $qval8,     # boolean
        'retry_on_conflict'       =>  $qval9,     # number
        'routing'                 =>  $qval10,    # list
        'timeout'                 =>  $qval11,    # string
        'wait_for_active_shards'  =>  $qval12,    # string
        
         # Common API query string parameters
        
        'error_trace'             =>  $qval13,    # boolean
        'filter_path'             =>  $qval14,    # list
        'human'                   =>  $qval15,    # boolean
        'pretty'                  =>  $qval16,    # boolean
        'source'                  =>  $qval17,    # string
    );

L<OpenSearch documentation for update|https://opensearch.org/docs/latest/api-reference/document-apis/update-document/>
    
=head2 update_by_query

Performs an update on every document in the index without changing the source,
for example to pick up a mapping change.


I<Paths served by this method:>

=over

=item
C<POST /{index}/_update_by_query>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->update_by_query(
        
        'body'                    =>  $body,      # optional
        
         # path parameters
        
        'index'                   =>  $index,     # required
        
         # Endpoint specific query string parameters
        
        '_source'                 =>  $qval1,     # list
        '_source_excludes'        =>  $qval2,     # list
        '_source_includes'        =>  $qval3,     # list
        'allow_no_indices'        =>  $qval4,     # boolean
        'analyze_wildcard'        =>  $qval5,     # boolean
        'analyzer'                =>  $qval6,     # string
        'conflicts'               =>  $qval7,     # string
        'default_operator'        =>  $qval8,     # string
        'df'                      =>  $qval9,     # string
        'expand_wildcards'        =>  $qval10,    # list
        'from'                    =>  $qval11,    # number
        'ignore_unavailable'      =>  $qval12,    # boolean
        'lenient'                 =>  $qval13,    # boolean
        'max_docs'                =>  $qval14,    # number
        'pipeline'                =>  $qval15,    # string
        'preference'              =>  $qval16,    # string
        'q'                       =>  $qval17,    # string
        'refresh'                 =>  $qval18,    # boolean|string
        'request_cache'           =>  $qval19,    # boolean
        'requests_per_second'     =>  $qval20,    # number
        'routing'                 =>  $qval21,    # list
        'scroll'                  =>  $qval22,    # string
        'scroll_size'             =>  $qval23,    # number
        'search_timeout'          =>  $qval24,    # string
        'search_type'             =>  $qval25,    # string
        'size'                    =>  $qval26,    # number
        'slices'                  =>  $qval27,    # number|string
        'sort'                    =>  $qval28,    # list
        'stats'                   =>  $qval29,    # list
        'terminate_after'         =>  $qval30,    # number
        'timeout'                 =>  $qval31,    # string
        'version'                 =>  $qval32,    # boolean
        'wait_for_active_shards'  =>  $qval33,    # string
        'wait_for_completion'     =>  $qval34,    # boolean
        
         # Common API query string parameters
        
        'error_trace'             =>  $qval35,    # boolean
        'filter_path'             =>  $qval36,    # list
        'human'                   =>  $qval37,    # boolean
        'pretty'                  =>  $qval38,    # boolean
        'source'                  =>  $qval39,    # string
    );

L<OpenSearch documentation for update_by_query|https://opensearch.org/docs/latest/api-reference/document-apis/update-by-query/>
    
=head2 update_by_query_rethrottle

Changes the number of requests per second for a particular Update By Query operation.


I<Paths served by this method:>

=over

=item
C<POST /_update_by_query/{task_id}/_rethrottle>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->update_by_query_rethrottle(
        
         # path parameters
        
        'task_id'              =>  $task_id,   # required
        
         # Endpoint specific query string parameters
        
        'requests_per_second'  =>  $qval1,     # number
        
         # Common API query string parameters
        
        'error_trace'          =>  $qval2,     # boolean
        'filter_path'          =>  $qval3,     # list
        'human'                =>  $qval4,     # boolean
        'pretty'               =>  $qval5,     # boolean
        'source'               =>  $qval6,     # string
    );

L<OpenSearch documentation for update_by_query_rethrottle|https://docs.opensearch.org/latest/api-reference/>

=head2 opensearch_version

A lazy populated property with the version of the current OpenSearch cluster.

It is populated by:

    my $version = $os->info->{version}->{number};

=head2 global_method_supported_in_version

Return whether a method is supported for an OpenSearch server version;

    my $boolean = $os->global_method_supported_in_version(
        method  => $methodname,        # required
        module  => $module_namespace,  # optional
        version => $version            # optional
    );
    
=over

=item module
 
Provide a module name if the method is not in the top level name space.
 
For example, to check if the method C<$os-E<gt>neural-E<gt>stats()> is supported by the api in OpenSearch version 2.19
 
    my $boolean = $os->global_method_supported_in_version(
        module  => 'neural',
        method  => 'stats',
        version => '2.19'
    );
    
For methods in the top level namespace do not provide a module.

For example, to check if the method C<$os-E<gt>get_all_pits()> is supported by the api in OpenSearch version 2.19

    my $boolean = $os->global_method_supported_in_version(
        method  => 'get_all_pits',
        version => '2.19'
    );

=item version

Provide a version if you want to check against a particular version of OpenSearch.
If you do not provide a version, the version to check against will be taken from C<$os-E<gt>opensearch_version()>

For example, to check if the method C<$os-E<gt>get_all_pits()> is supported by the api in the OpenSearch instance you are connected to

    my $boolean = $os->global_method_supported_in_version(
        method  => 'get_all_pits',
    );

=back

=head2 method_supported_in_version

Return whether a method in the top level namespace is supported for an OpenSearch server version

    my $boolean = $os->method_supported_in_version(
        method  => 'get_all_pits',
        version => '2.4.0'
    );

Both C<method> and C<version> are required.

See also L<global_method_supported_in_version|OpenSearch::Client::Core::3_0::Direct#global_method_supported_in_version>

=head2 bulk_helper

Returns a new instance of the bulk_helper_class which makes it easier to run multiple create, index, update or delete
actions in a single request.

   my $helper = $client->bulk_helper( @args );

L<Bulk Helper documentation|OpenSearch::Client::Core::3_0::Helper::Bulk>

=head2 scroll_helper

Returns a new instance of the scroll_helper_class - a helper module for scrolled searches

   my $helper = $client->scroll_helper( @args );

L<Scroll Helper documentation|OpenSearch::Client::Core::3_0::Helper::Scroll>

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
