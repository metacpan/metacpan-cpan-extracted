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

package OpenSearch::Client::Core::3_0::Direct::Cat;
$OpenSearch::Client::Core::3_0::Direct::Cat::VERSION = '3.007007';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('cat');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::Cat>

=head1 VERSION

version 3.007007

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->cat-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<CAT APIs>


You can get essential statistics about your cluster in an easy-to-understand, tabular format using the compact and aligned text (CAT) API. The CAT API is a human-readable interface that returns plain text instead of traditional JSON. Using the CAT API, you can answer questions like which node is the elected cluster manager, what state the cluster is in, how many documents are in each index, and so on.

L<See OpenSearch documentation for cat.|https://docs.opensearch.org/latest/api-reference/cat/index/>

=head1 METHODS
    
=head2 aliases

Shows information about aliases currently configured to indexes, including filter and routing information.

I<Paths served by this method:>

=over

=item
C<GET /_cat/aliases>

=item
C<GET /_cat/aliases/{name}>

=back

    $resp = $client->cat->aliases(
        
         # path parameters
        
        'name'              =>  $name,      # optional
        
         # Endpoint specific query string parameters
        
        'expand_wildcards'  =>  $qval1,     # list
        'format'            =>  $qval2,     # string
        'h'                 =>  $qval3,     # list
        'help'              =>  $qval4,     # boolean
        'local'             =>  $qval5,     # boolean
        's'                 =>  $qval6,     # list
        'v'                 =>  $qval7,     # boolean
        
         # Common API query string parameters
        
        'error_trace'       =>  $qval8,     # boolean
        'filter_path'       =>  $qval9,     # list
        'human'             =>  $qval10,    # boolean
        'pretty'            =>  $qval11,    # boolean
        'source'            =>  $qval12,    # string
    );

L<OpenSearch documentation for cat-E<gt>aliases|https://opensearch.org/docs/latest/api-reference/cat/cat-aliases/>
    
=head2 all_pit_segments

Lists all active CAT point-in-time segments.

I<Paths served by this method:>

=over

=item
C<GET /_cat/pit_segments/_all>

=back

    $resp = $client->cat->all_pit_segments(
        
         # Endpoint specific query string parameters
        
        'bytes'        =>  $qval1,     # string
        'format'       =>  $qval2,     # string
        'h'            =>  $qval3,     # list
        'help'         =>  $qval4,     # boolean
        's'            =>  $qval5,     # list
        'v'            =>  $qval6,     # boolean
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval7,     # boolean
        'filter_path'  =>  $qval8,     # list
        'human'        =>  $qval9,     # boolean
        'pretty'       =>  $qval10,    # boolean
        'source'       =>  $qval11,    # string
    );

L<OpenSearch documentation for cat-E<gt>all_pit_segments|https://opensearch.org/docs/latest/search-plugins/point-in-time-api/>
    
=head2 allocation

Provides a snapshot of how many shards are allocated to each data node and how much disk space they are using.

I<Paths served by this method:>

=over

=item
C<GET /_cat/allocation>

=item
C<GET /_cat/allocation/{node_id}>

=back

    $resp = $client->cat->allocation(
        
         # path parameters
        
        'node_id'                  =>  $node_id,   # optional
        
         # Endpoint specific query string parameters
        
        'bytes'                    =>  $qval1,     # string
        'cluster_manager_timeout'  =>  $qval2,     # string
        'format'                   =>  $qval3,     # string
        'h'                        =>  $qval4,     # list
        'help'                     =>  $qval5,     # boolean
        'local'                    =>  $qval6,     # boolean
        'master_timeout'           =>  $qval7,     # string
        's'                        =>  $qval8,     # list
        'v'                        =>  $qval9,     # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval10,    # boolean
        'filter_path'              =>  $qval11,    # list
        'human'                    =>  $qval12,    # boolean
        'pretty'                   =>  $qval13,    # boolean
        'source'                   =>  $qval14,    # string
    );

L<OpenSearch documentation for cat-E<gt>allocation|https://opensearch.org/docs/latest/api-reference/cat/cat-allocation/>
    
=head2 cluster_manager

Returns information about the cluster-manager node.

I<Paths served by this method:>

=over

=item
C<GET /_cat/cluster_manager>

=back

    $resp = $client->cat->cluster_manager(
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'format'                   =>  $qval2,     # string
        'h'                        =>  $qval3,     # list
        'help'                     =>  $qval4,     # boolean
        'local'                    =>  $qval5,     # boolean
        'master_timeout'           =>  $qval6,     # string
        's'                        =>  $qval7,     # list
        'v'                        =>  $qval8,     # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval9,     # boolean
        'filter_path'              =>  $qval10,    # list
        'human'                    =>  $qval11,    # boolean
        'pretty'                   =>  $qval12,    # boolean
        'source'                   =>  $qval13,    # string
    );

L<OpenSearch documentation for cat-E<gt>cluster_manager|https://opensearch.org/docs/latest/api-reference/cat/cat-cluster_manager/>
    
=head2 count

Provides quick access to the document count of the entire cluster or of an individual index.

I<Paths served by this method:>

=over

=item
C<GET /_cat/count>

=item
C<GET /_cat/count/{index}>

=back

    $resp = $client->cat->count(
        
         # path parameters
        
        'index'        =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'format'       =>  $qval1,     # string
        'h'            =>  $qval2,     # list
        'help'         =>  $qval3,     # boolean
        's'            =>  $qval4,     # list
        'v'            =>  $qval5,     # boolean
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval6,     # boolean
        'filter_path'  =>  $qval7,     # list
        'human'        =>  $qval8,     # boolean
        'pretty'       =>  $qval9,     # boolean
        'source'       =>  $qval10,    # string
    );

L<OpenSearch documentation for cat-E<gt>count|https://opensearch.org/docs/latest/api-reference/cat/cat-count/>
    
=head2 fielddata

Shows how much heap memory is currently being used by field data on every data node in the cluster.

I<Paths served by this method:>

=over

=item
C<GET /_cat/fielddata>

=item
C<GET /_cat/fielddata/{fields}>

=back

    $resp = $client->cat->fielddata(
        
         # path parameters
        
        'fields'       =>  $fields,    # optional
        
         # Endpoint specific query string parameters
        
        'bytes'        =>  $qval1,     # string
        'fields'       =>  $qval2,     # list
        'format'       =>  $qval3,     # string
        'h'            =>  $qval4,     # list
        'help'         =>  $qval5,     # boolean
        's'            =>  $qval6,     # list
        'v'            =>  $qval7,     # boolean
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval8,     # boolean
        'filter_path'  =>  $qval9,     # list
        'human'        =>  $qval10,    # boolean
        'pretty'       =>  $qval11,    # boolean
        'source'       =>  $qval12,    # string
    );

L<OpenSearch documentation for cat-E<gt>fielddata|https://opensearch.org/docs/latest/api-reference/cat/cat-field-data/>
    
=head2 health

Returns a concise representation of the cluster health.

I<Paths served by this method:>

=over

=item
C<GET /_cat/health>

=back

    $resp = $client->cat->health(
        
         # Endpoint specific query string parameters
        
        'format'       =>  $qval1,     # string
        'h'            =>  $qval2,     # list
        'help'         =>  $qval3,     # boolean
        's'            =>  $qval4,     # list
        'time'         =>  $qval5,     # string
        'ts'           =>  $qval6,     # boolean
        'v'            =>  $qval7,     # boolean
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval8,     # boolean
        'filter_path'  =>  $qval9,     # list
        'human'        =>  $qval10,    # boolean
        'pretty'       =>  $qval11,    # boolean
        'source'       =>  $qval12,    # string
    );

L<OpenSearch documentation for cat-E<gt>health|https://opensearch.org/docs/latest/api-reference/cat/cat-health/>
    
=head2 help

Returns help for the Cat APIs.

I<Paths served by this method:>

=over

=item
C<GET /_cat>

=back

    $resp = $client->cat->help(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for cat-E<gt>help|https://opensearch.org/docs/latest/api-reference/cat/index/>
    
=head2 indices

Lists information related to indexes, that is, how much disk space they are using, how many shards they have, their health status, and so on.

I<Paths served by this method:>

=over

=item
C<GET /_cat/indices>

=item
C<GET /_cat/indices/{index}>

=back

    $resp = $client->cat->indices(
        
         # path parameters
        
        'index'                      =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'bytes'                      =>  $qval1,     # string
        'cluster_manager_timeout'    =>  $qval2,     # string
        'expand_wildcards'           =>  $qval3,     # list
        'format'                     =>  $qval4,     # string
        'h'                          =>  $qval5,     # list
        'health'                     =>  $qval6,     # string
        'help'                       =>  $qval7,     # boolean
        'include_unloaded_segments'  =>  $qval8,     # boolean
        'local'                      =>  $qval9,     # boolean
        'master_timeout'             =>  $qval10,    # string
        'pri'                        =>  $qval11,    # boolean
        's'                          =>  $qval12,    # list
        'time'                       =>  $qval13,    # string
        'v'                          =>  $qval14,    # boolean
        
         # Common API query string parameters
        
        'error_trace'                =>  $qval15,    # boolean
        'filter_path'                =>  $qval16,    # list
        'human'                      =>  $qval17,    # boolean
        'pretty'                     =>  $qval18,    # boolean
        'source'                     =>  $qval19,    # string
    );

L<OpenSearch documentation for cat-E<gt>indices|https://opensearch.org/docs/latest/api-reference/cat/cat-indices/>
    
=head2 master

Returns information about the cluster-manager node.

I<Paths served by this method:>

=over

=item
C<GET /_cat/master>

=back

    $resp = $client->cat->master(
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'format'                   =>  $qval2,     # string
        'h'                        =>  $qval3,     # list
        'help'                     =>  $qval4,     # boolean
        'local'                    =>  $qval5,     # boolean
        'master_timeout'           =>  $qval6,     # string
        's'                        =>  $qval7,     # list
        'v'                        =>  $qval8,     # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval9,     # boolean
        'filter_path'              =>  $qval10,    # list
        'human'                    =>  $qval11,    # boolean
        'pretty'                   =>  $qval12,    # boolean
        'source'                   =>  $qval13,    # string
    );

L<OpenSearch documentation for cat-E<gt>master|https://opensearch.org/docs/latest/api-reference/cat/cat-cluster_manager/>
    
=head2 nodeattrs

Returns information about custom node attributes.

I<Paths served by this method:>

=over

=item
C<GET /_cat/nodeattrs>

=back

    $resp = $client->cat->nodeattrs(
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'format'                   =>  $qval2,     # string
        'h'                        =>  $qval3,     # list
        'help'                     =>  $qval4,     # boolean
        'local'                    =>  $qval5,     # boolean
        'master_timeout'           =>  $qval6,     # string
        's'                        =>  $qval7,     # list
        'v'                        =>  $qval8,     # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval9,     # boolean
        'filter_path'              =>  $qval10,    # list
        'human'                    =>  $qval11,    # boolean
        'pretty'                   =>  $qval12,    # boolean
        'source'                   =>  $qval13,    # string
    );

L<OpenSearch documentation for cat-E<gt>nodeattrs|https://opensearch.org/docs/latest/api-reference/cat/cat-nodeattrs/>
    
=head2 nodes

Returns basic statistics about the performance of cluster nodes.

I<Paths served by this method:>

=over

=item
C<GET /_cat/nodes>

=back

    $resp = $client->cat->nodes(
        
         # Endpoint specific query string parameters
        
        'bytes'                    =>  $qval1,     # string
        'cluster_manager_timeout'  =>  $qval2,     # string
        'format'                   =>  $qval3,     # string
        'full_id'                  =>  $qval4,     # boolean
        'h'                        =>  $qval5,     # list
        'help'                     =>  $qval6,     # boolean
        'local'                    =>  $qval7,     # boolean
        'master_timeout'           =>  $qval8,     # string
        's'                        =>  $qval9,     # list
        'time'                     =>  $qval10,    # string
        'v'                        =>  $qval11,    # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval12,    # boolean
        'filter_path'              =>  $qval13,    # list
        'human'                    =>  $qval14,    # boolean
        'pretty'                   =>  $qval15,    # boolean
        'source'                   =>  $qval16,    # string
    );

L<OpenSearch documentation for cat-E<gt>nodes|https://opensearch.org/docs/latest/api-reference/cat/cat-nodes/>
    
=head2 pending_tasks

Returns a concise representation of the cluster's pending tasks.

I<Paths served by this method:>

=over

=item
C<GET /_cat/pending_tasks>

=back

    $resp = $client->cat->pending_tasks(
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'format'                   =>  $qval2,     # string
        'h'                        =>  $qval3,     # list
        'help'                     =>  $qval4,     # boolean
        'local'                    =>  $qval5,     # boolean
        'master_timeout'           =>  $qval6,     # string
        's'                        =>  $qval7,     # list
        'time'                     =>  $qval8,     # string
        'v'                        =>  $qval9,     # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval10,    # boolean
        'filter_path'              =>  $qval11,    # list
        'human'                    =>  $qval12,    # boolean
        'pretty'                   =>  $qval13,    # boolean
        'source'                   =>  $qval14,    # string
    );

L<OpenSearch documentation for cat-E<gt>pending_tasks|https://opensearch.org/docs/latest/api-reference/cat/cat-pending-tasks/>
    
=head2 pit_segments

Lists one or several CAT point-in-time segments.

I<Paths served by this method:>

=over

=item
C<GET /_cat/pit_segments>

=back

    $resp = $client->cat->pit_segments(
        
        'body'         =>  $body,      # optional
        
         # Endpoint specific query string parameters
        
        'bytes'        =>  $qval1,     # string
        'format'       =>  $qval2,     # string
        'h'            =>  $qval3,     # list
        'help'         =>  $qval4,     # boolean
        's'            =>  $qval5,     # list
        'v'            =>  $qval6,     # boolean
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval7,     # boolean
        'filter_path'  =>  $qval8,     # list
        'human'        =>  $qval9,     # boolean
        'pretty'       =>  $qval10,    # boolean
        'source'       =>  $qval11,    # string
    );

L<OpenSearch documentation for cat-E<gt>pit_segments|https://opensearch.org/docs/latest/search-plugins/point-in-time-api/>
    
=head2 plugins

Returns information about the names, components, and versions of the installed plugins.

I<Paths served by this method:>

=over

=item
C<GET /_cat/plugins>

=back

    $resp = $client->cat->plugins(
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'format'                   =>  $qval2,     # string
        'h'                        =>  $qval3,     # list
        'help'                     =>  $qval4,     # boolean
        'local'                    =>  $qval5,     # boolean
        'master_timeout'           =>  $qval6,     # string
        's'                        =>  $qval7,     # list
        'v'                        =>  $qval8,     # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval9,     # boolean
        'filter_path'              =>  $qval10,    # list
        'human'                    =>  $qval11,    # boolean
        'pretty'                   =>  $qval12,    # boolean
        'source'                   =>  $qval13,    # string
    );

L<OpenSearch documentation for cat-E<gt>plugins|https://opensearch.org/docs/latest/api-reference/cat/cat-plugins/>
    
=head2 recovery

Returns all completed and ongoing index and shard recoveries.

I<Paths served by this method:>

=over

=item
C<GET /_cat/recovery>

=item
C<GET /_cat/recovery/{index}>

=back

    $resp = $client->cat->recovery(
        
         # path parameters
        
        'index'        =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'active_only'  =>  $qval1,     # boolean
        'bytes'        =>  $qval2,     # string
        'detailed'     =>  $qval3,     # boolean
        'format'       =>  $qval4,     # string
        'h'            =>  $qval5,     # list
        'help'         =>  $qval6,     # boolean
        'index'        =>  $qval7,     # list
        's'            =>  $qval8,     # list
        'time'         =>  $qval9,     # string
        'v'            =>  $qval10,    # boolean
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval11,    # boolean
        'filter_path'  =>  $qval12,    # list
        'human'        =>  $qval13,    # boolean
        'pretty'       =>  $qval14,    # boolean
        'source'       =>  $qval15,    # string
    );

L<OpenSearch documentation for cat-E<gt>recovery|https://opensearch.org/docs/latest/api-reference/cat/cat-plugins/>
    
=head2 repositories

Returns information about all snapshot repositories for a cluster.

I<Paths served by this method:>

=over

=item
C<GET /_cat/repositories>

=back

    $resp = $client->cat->repositories(
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'format'                   =>  $qval2,     # string
        'h'                        =>  $qval3,     # list
        'help'                     =>  $qval4,     # boolean
        'local'                    =>  $qval5,     # boolean
        'master_timeout'           =>  $qval6,     # string
        's'                        =>  $qval7,     # list
        'v'                        =>  $qval8,     # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval9,     # boolean
        'filter_path'              =>  $qval10,    # list
        'human'                    =>  $qval11,    # boolean
        'pretty'                   =>  $qval12,    # boolean
        'source'                   =>  $qval13,    # string
    );

L<OpenSearch documentation for cat-E<gt>repositories|https://opensearch.org/docs/latest/api-reference/cat/cat-repositories/>
    
=head2 segment_replication

Returns information about active and last-completed segment replication events on each replica shard, including related shard-level metrics. 
These metrics provide information about how far behind the primary shard the replicas are lagging.

I<Paths served by this method:>

=over

=item
C<GET /_cat/segment_replication>

=item
C<GET /_cat/segment_replication/{index}>

=back

    $resp = $client->cat->segment_replication(
        
         # path parameters
        
        'index'               =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'active_only'         =>  $qval1,     # boolean
        'allow_no_indices'    =>  $qval2,     # boolean
        'bytes'               =>  $qval3,     # string
        'completed_only'      =>  $qval4,     # boolean
        'detailed'            =>  $qval5,     # boolean
        'expand_wildcards'    =>  $qval6,     # list
        'format'              =>  $qval7,     # string
        'h'                   =>  $qval8,     # list
        'help'                =>  $qval9,     # boolean
        'ignore_throttled'    =>  $qval10,    # boolean
        'ignore_unavailable'  =>  $qval11,    # boolean
        'index'               =>  $qval12,    # list
        's'                   =>  $qval13,    # list
        'shards'              =>  $qval14,    # list
        'time'                =>  $qval15,    # string
        'timeout'             =>  $qval16,    # string
        'v'                   =>  $qval17,    # boolean
        
         # Common API query string parameters
        
        'error_trace'         =>  $qval18,    # boolean
        'filter_path'         =>  $qval19,    # list
        'human'               =>  $qval20,    # boolean
        'pretty'              =>  $qval21,    # boolean
        'source'              =>  $qval22,    # string
    );

L<OpenSearch documentation for cat-E<gt>segment_replication|https://opensearch.org/docs/latest/api-reference/cat/cat-segment-replication/>
    
=head2 segments

Provides low-level information about the segments in the shards of an index.

I<Paths served by this method:>

=over

=item
C<GET /_cat/segments>

=item
C<GET /_cat/segments/{index}>

=back

    $resp = $client->cat->segments(
        
         # path parameters
        
        'index'                    =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'bytes'                    =>  $qval1,     # string
        'cluster_manager_timeout'  =>  $qval2,     # string
        'format'                   =>  $qval3,     # string
        'h'                        =>  $qval4,     # list
        'help'                     =>  $qval5,     # boolean
        'master_timeout'           =>  $qval6,     # string
        's'                        =>  $qval7,     # list
        'v'                        =>  $qval8,     # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval9,     # boolean
        'filter_path'              =>  $qval10,    # list
        'human'                    =>  $qval11,    # boolean
        'pretty'                   =>  $qval12,    # boolean
        'source'                   =>  $qval13,    # string
    );

L<OpenSearch documentation for cat-E<gt>segments|https://opensearch.org/docs/latest/api-reference/cat/cat-segments/>
    
=head2 shards

Lists the states of all primary and replica shards and how they are distributed.

I<Paths served by this method:>

=over

=item
C<GET /_cat/shards>

=item
C<GET /_cat/shards/{index}>

=back

    $resp = $client->cat->shards(
        
         # path parameters
        
        'index'                    =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'bytes'                    =>  $qval1,     # string
        'cluster_manager_timeout'  =>  $qval2,     # string
        'format'                   =>  $qval3,     # string
        'h'                        =>  $qval4,     # list
        'help'                     =>  $qval5,     # boolean
        'local'                    =>  $qval6,     # boolean
        'master_timeout'           =>  $qval7,     # string
        's'                        =>  $qval8,     # list
        'time'                     =>  $qval9,     # string
        'v'                        =>  $qval10,    # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval11,    # boolean
        'filter_path'              =>  $qval12,    # list
        'human'                    =>  $qval13,    # boolean
        'pretty'                   =>  $qval14,    # boolean
        'source'                   =>  $qval15,    # string
    );

L<OpenSearch documentation for cat-E<gt>shards|https://opensearch.org/docs/latest/api-reference/cat/cat-shards/>
    
=head2 snapshots

Lists all of the snapshots stored in a specific repository.

I<Paths served by this method:>

=over

=item
C<GET /_cat/snapshots>

=item
C<GET /_cat/snapshots/{repository}>

=back

    $resp = $client->cat->snapshots(
        
         # path parameters
        
        'repository'               =>  $repository,  # optional
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'format'                   =>  $qval2,     # string
        'h'                        =>  $qval3,     # list
        'help'                     =>  $qval4,     # boolean
        'ignore_unavailable'       =>  $qval5,     # boolean
        'master_timeout'           =>  $qval6,     # string
        'repository'               =>  $qval7,     # list
        's'                        =>  $qval8,     # list
        'time'                     =>  $qval9,     # string
        'v'                        =>  $qval10,    # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval11,    # boolean
        'filter_path'              =>  $qval12,    # list
        'human'                    =>  $qval13,    # boolean
        'pretty'                   =>  $qval14,    # boolean
        'source'                   =>  $qval15,    # string
    );

L<OpenSearch documentation for cat-E<gt>snapshots|https://opensearch.org/docs/latest/api-reference/cat/cat-snapshots/>
    
=head2 tasks

Lists the progress of all tasks currently running on the cluster.

I<Paths served by this method:>

=over

=item
C<GET /_cat/tasks>

=back

    $resp = $client->cat->tasks(
        
         # Endpoint specific query string parameters
        
        'actions'         =>  $qval1,     # list
        'detailed'        =>  $qval2,     # boolean
        'format'          =>  $qval3,     # string
        'h'               =>  $qval4,     # list
        'help'            =>  $qval5,     # boolean
        'nodes'           =>  $qval6,     # list
        'parent_task_id'  =>  $qval7,     # string
        's'               =>  $qval8,     # list
        'time'            =>  $qval9,     # string
        'v'               =>  $qval10,    # boolean
        
         # Common API query string parameters
        
        'error_trace'     =>  $qval11,    # boolean
        'filter_path'     =>  $qval12,    # list
        'human'           =>  $qval13,    # boolean
        'pretty'          =>  $qval14,    # boolean
        'source'          =>  $qval15,    # string
    );

L<OpenSearch documentation for cat-E<gt>tasks|https://opensearch.org/docs/latest/api-reference/cat/cat-tasks/>
    
=head2 templates

Lists the names, patterns, order numbers, and version numbers of index templates.

I<Paths served by this method:>

=over

=item
C<GET /_cat/templates>

=item
C<GET /_cat/templates/{name}>

=back

    $resp = $client->cat->templates(
        
         # path parameters
        
        'name'                     =>  $name,      # optional
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'format'                   =>  $qval2,     # string
        'h'                        =>  $qval3,     # list
        'help'                     =>  $qval4,     # boolean
        'local'                    =>  $qval5,     # boolean
        'master_timeout'           =>  $qval6,     # string
        's'                        =>  $qval7,     # list
        'v'                        =>  $qval8,     # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval9,     # boolean
        'filter_path'              =>  $qval10,    # list
        'human'                    =>  $qval11,    # boolean
        'pretty'                   =>  $qval12,    # boolean
        'source'                   =>  $qval13,    # string
    );

L<OpenSearch documentation for cat-E<gt>templates|https://opensearch.org/docs/latest/api-reference/cat/cat-templates/>
    
=head2 thread_pool

Returns cluster-wide thread pool statistics per node.
By default the active, queued, and rejected statistics are returned for all thread pools.

I<Paths served by this method:>

=over

=item
C<GET /_cat/thread_pool>

=item
C<GET /_cat/thread_pool/{thread_pool_patterns}>

=back

    $resp = $client->cat->thread_pool(
        
         # path parameters
        
        'thread_pool_patterns'     =>  $thread_pool_patterns,  # optional
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'format'                   =>  $qval2,     # string
        'h'                        =>  $qval3,     # list
        'help'                     =>  $qval4,     # boolean
        'local'                    =>  $qval5,     # boolean
        'master_timeout'           =>  $qval6,     # string
        's'                        =>  $qval7,     # list
        'size'                     =>  $qval8,     # number
        'v'                        =>  $qval9,     # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval10,    # boolean
        'filter_path'              =>  $qval11,    # list
        'human'                    =>  $qval12,    # boolean
        'pretty'                   =>  $qval13,    # boolean
        'source'                   =>  $qval14,    # string
    );

L<OpenSearch documentation for cat-E<gt>thread_pool|https://opensearch.org/docs/latest/api-reference/cat/cat-thread-pool/>

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

