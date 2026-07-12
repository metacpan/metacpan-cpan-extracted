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

package OpenSearch::Client::Core::3_0::Direct::Cluster;
$OpenSearch::Client::Core::3_0::Direct::Cluster::VERSION = '3.007007';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('cluster');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::Cluster>

=head1 VERSION

version 3.007007

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->cluster-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Cluster APIs>


The cluster APIs allow you to manage your cluster. You can use them to check cluster health, modify settings, retrieve statistics, and more.

L<See OpenSearch documentation for cluster.|https://docs.opensearch.org/latest/api-reference/cluster-api/index/>

=head1 METHODS
    
=head2 allocation_explain

Explains how shards are allocated in the current cluster and provides an explanation for why unassigned shards can't be allocated to a node.

I<Paths served by this method:>

=over

=item
C<GET /_cluster/allocation/explain>

=item
C<POST /_cluster/allocation/explain>

=back

    $resp = $client->cluster->allocation_explain(
        
        'body'                   =>  $body,      # optional
        
         # Endpoint specific query string parameters
        
        'include_disk_info'      =>  $qval1,     # boolean
        'include_yes_decisions'  =>  $qval2,     # boolean
        
         # Common API query string parameters
        
        'error_trace'            =>  $qval3,     # boolean
        'filter_path'            =>  $qval4,     # list
        'human'                  =>  $qval5,     # boolean
        'pretty'                 =>  $qval6,     # boolean
        'source'                 =>  $qval7,     # string
    );

L<OpenSearch documentation for cluster-E<gt>allocation_explain|https://opensearch.org/docs/latest/api-reference/cluster-api/cluster-allocation/>
    
=head2 delete_component_template

Deletes a component template.

I<Paths served by this method:>

=over

=item
C<DELETE /_component_template/{name}>

=back

    $resp = $client->cluster->delete_component_template(
        
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

L<OpenSearch documentation for cluster-E<gt>delete_component_template|https://docs.opensearch.org/latest/api-reference/cluster-api/index/>
    
=head2 delete_decommission_awareness

Recommissions a decommissioned zone.

I<Paths served by this method:>

=over

=item
C<DELETE /_cluster/decommission/awareness>

=back

    $resp = $client->cluster->delete_decommission_awareness(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for cluster-E<gt>delete_decommission_awareness|https://opensearch.org/docs/latest/api-reference/cluster-api/cluster-decommission/#example-decommissioning-and-recommissioning-a-zone>
    
=head2 delete_voting_config_exclusions

Clears any cluster voting configuration exclusions.

I<Paths served by this method:>

=over

=item
C<DELETE /_cluster/voting_config_exclusions>

=back

    $resp = $client->cluster->delete_voting_config_exclusions(
        
         # Endpoint specific query string parameters
        
        'wait_for_removal'  =>  $qval1,     # boolean
        
         # Common API query string parameters
        
        'error_trace'       =>  $qval2,     # boolean
        'filter_path'       =>  $qval3,     # list
        'human'             =>  $qval4,     # boolean
        'pretty'            =>  $qval5,     # boolean
        'source'            =>  $qval6,     # string
    );

L<OpenSearch documentation for cluster-E<gt>delete_voting_config_exclusions|https://docs.opensearch.org/latest/api-reference/cluster-api/index/>
    
=head2 delete_weighted_routing

Delete weighted shard routing weights.

I<Paths served by this method:>

=over

=item
C<DELETE /_cluster/routing/awareness/weights>

=back

    $resp = $client->cluster->delete_weighted_routing(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for cluster-E<gt>delete_weighted_routing|https://opensearch.org/docs/latest/api-reference/cluster-api/cluster-awareness/#example-deleting-weights>
    
=head2 exists_component_template

Returns information about whether a particular component template exist.

I<Paths served by this method:>

=over

=item
C<HEAD /_component_template/{name}>

=back

    $resp = $client->cluster->exists_component_template(
        
         # path parameters
        
        'name'                     =>  $name,      # required
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'local'                    =>  $qval2,     # boolean
        'master_timeout'           =>  $qval3,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval4,     # boolean
        'filter_path'              =>  $qval5,     # list
        'human'                    =>  $qval6,     # boolean
        'pretty'                   =>  $qval7,     # boolean
        'source'                   =>  $qval8,     # string
    );

L<OpenSearch documentation for cluster-E<gt>exists_component_template|https://docs.opensearch.org/latest/api-reference/cluster-api/index/>
    
=head2 get_component_template

Returns one or more component templates.

I<Paths served by this method:>

=over

=item
C<GET /_component_template>

=item
C<GET /_component_template/{name}>

=back

    $resp = $client->cluster->get_component_template(
        
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

L<OpenSearch documentation for cluster-E<gt>get_component_template|https://docs.opensearch.org/latest/api-reference/cluster-api/index/>
    
=head2 get_decommission_awareness

Retrieves the decommission status for all zones.

I<Paths served by this method:>

=over

=item
C<GET /_cluster/decommission/awareness/{awareness_attribute_name}/_status>

=back

    $resp = $client->cluster->get_decommission_awareness(
        
         # path parameters
        
        'awareness_attribute_name'  =>  $awareness_attribute_name,  # required
        
         # Common API query string parameters
        
        'error_trace'               =>  $qval1,     # boolean
        'filter_path'               =>  $qval2,     # list
        'human'                     =>  $qval3,     # boolean
        'pretty'                    =>  $qval4,     # boolean
        'source'                    =>  $qval5,     # string
    );

L<OpenSearch documentation for cluster-E<gt>get_decommission_awareness|https://opensearch.org/docs/latest/api-reference/cluster-api/cluster-decommission/#example-getting-zone-decommission-status>
    
=head2 get_settings

Returns cluster settings.

I<Paths served by this method:>

=over

=item
C<GET /_cluster/settings>

=back

    $resp = $client->cluster->get_settings(
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'flat_settings'            =>  $qval2,     # boolean
        'include_defaults'         =>  $qval3,     # boolean
        'master_timeout'           =>  $qval4,     # string
        'timeout'                  =>  $qval5,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval6,     # boolean
        'filter_path'              =>  $qval7,     # list
        'human'                    =>  $qval8,     # boolean
        'pretty'                   =>  $qval9,     # boolean
        'source'                   =>  $qval10,    # string
    );

L<OpenSearch documentation for cluster-E<gt>get_settings|https://opensearch.org/docs/latest/api-reference/cluster-api/cluster-settings/>
    
=head2 get_weighted_routing

Fetches weighted shard routing weights.

I<Paths served by this method:>

=over

=item
C<GET /_cluster/routing/awareness/{attribute}/weights>

=back

    $resp = $client->cluster->get_weighted_routing(
        
         # path parameters
        
        'attribute'    =>  $attribute,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for cluster-E<gt>get_weighted_routing|https://opensearch.org/docs/latest/api-reference/cluster-api/cluster-awareness/#example-getting-weights-for-all-zones>
    
=head2 health

Returns basic information about the health of the cluster.

I<Paths served by this method:>

=over

=item
C<GET /_cluster/health>

=item
C<GET /_cluster/health/{index}>

=back

    $resp = $client->cluster->health(
        
         # path parameters
        
        'index'                            =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'awareness_attribute'              =>  $qval1,     # string
        'cluster_manager_timeout'          =>  $qval2,     # string
        'expand_wildcards'                 =>  $qval3,     # list
        'level'                            =>  $qval4,     # string
        'local'                            =>  $qval5,     # boolean
        'master_timeout'                   =>  $qval6,     # string
        'timeout'                          =>  $qval7,     # string
        'wait_for_active_shards'           =>  $qval8,     # string
        'wait_for_events'                  =>  $qval9,     # string
        'wait_for_no_initializing_shards'  =>  $qval10,    # boolean
        'wait_for_no_relocating_shards'    =>  $qval11,    # boolean
        'wait_for_nodes'                   =>  $qval12,    # number|string
        'wait_for_status'                  =>  $qval13,    # string
        
         # Common API query string parameters
        
        'error_trace'                      =>  $qval14,    # boolean
        'filter_path'                      =>  $qval15,    # list
        'human'                            =>  $qval16,    # boolean
        'pretty'                           =>  $qval17,    # boolean
        'source'                           =>  $qval18,    # string
    );

L<OpenSearch documentation for cluster-E<gt>health|https://opensearch.org/docs/latest/api-reference/cluster-api/cluster-health/>
    
=head2 pending_tasks

Returns a list of pending cluster-level tasks, such as index creation, mapping updates,
or new allocations.

I<Paths served by this method:>

=over

=item
C<GET /_cluster/pending_tasks>

=back

    $resp = $client->cluster->pending_tasks(
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'local'                    =>  $qval2,     # boolean
        'master_timeout'           =>  $qval3,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval4,     # boolean
        'filter_path'              =>  $qval5,     # list
        'human'                    =>  $qval6,     # boolean
        'pretty'                   =>  $qval7,     # boolean
        'source'                   =>  $qval8,     # string
    );

L<OpenSearch documentation for cluster-E<gt>pending_tasks|https://docs.opensearch.org/latest/api-reference/cluster-api/index/>
    
=head2 post_voting_config_exclusions

Updates the cluster voting configuration by excluding certain node IDs or names.

I<Paths served by this method:>

=over

=item
C<POST /_cluster/voting_config_exclusions>

=back

    $resp = $client->cluster->post_voting_config_exclusions(
        
         # Endpoint specific query string parameters
        
        'node_ids'     =>  $qval1,     # list
        'node_names'   =>  $qval2,     # list
        'timeout'      =>  $qval3,     # string
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval4,     # boolean
        'filter_path'  =>  $qval5,     # list
        'human'        =>  $qval6,     # boolean
        'pretty'       =>  $qval7,     # boolean
        'source'       =>  $qval8,     # string
    );

L<OpenSearch documentation for cluster-E<gt>post_voting_config_exclusions|https://docs.opensearch.org/latest/api-reference/cluster-api/index/>
    
=head2 put_component_template

Creates or updates a component template.

I<Paths served by this method:>

=over

=item
C<POST /_component_template/{name}>

=item
C<PUT /_component_template/{name}>

=back

    $resp = $client->cluster->put_component_template(
        
        'body'                     =>  $body,      # required
        
         # path parameters
        
        'name'                     =>  $name,      # required
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'create'                   =>  $qval2,     # boolean
        'master_timeout'           =>  $qval3,     # string
        'timeout'                  =>  $qval4,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval5,     # boolean
        'filter_path'              =>  $qval6,     # list
        'human'                    =>  $qval7,     # boolean
        'pretty'                   =>  $qval8,     # boolean
        'source'                   =>  $qval9,     # string
    );

L<OpenSearch documentation for cluster-E<gt>put_component_template|https://opensearch.org/docs/latest/im-plugin/index-templates/#use-component-templates-to-create-an-index-template>
    
=head2 put_decommission_awareness

Decommissions a cluster zone based on awareness. This can greatly benefit multi-zone deployments, where awareness attributes can aid in applying new upgrades to a cluster in a controlled fashion.

I<Paths served by this method:>

=over

=item
C<PUT /_cluster/decommission/awareness/{awareness_attribute_name}/{awareness_attribute_value}>

=back

    $resp = $client->cluster->put_decommission_awareness(
        
         # path parameters
        
        'awareness_attribute_name'   =>  $awareness_attribute_name,  # required
        'awareness_attribute_value'  =>  $awareness_attribute_value,  # required
        
         # Common API query string parameters
        
        'error_trace'                =>  $qval1,     # boolean
        'filter_path'                =>  $qval2,     # list
        'human'                      =>  $qval3,     # boolean
        'pretty'                     =>  $qval4,     # boolean
        'source'                     =>  $qval5,     # string
    );

L<OpenSearch documentation for cluster-E<gt>put_decommission_awareness|https://opensearch.org/docs/latest/api-reference/cluster-api/cluster-decommission/#example-decommissioning-and-recommissioning-a-zone>
    
=head2 put_settings

Updates the cluster settings.

I<Paths served by this method:>

=over

=item
C<PUT /_cluster/settings>

=back

    $resp = $client->cluster->put_settings(
        
        'body'                     =>  $body,      # optional
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'flat_settings'            =>  $qval2,     # boolean
        'master_timeout'           =>  $qval3,     # string
        'timeout'                  =>  $qval4,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval5,     # boolean
        'filter_path'              =>  $qval6,     # list
        'human'                    =>  $qval7,     # boolean
        'pretty'                   =>  $qval8,     # boolean
        'source'                   =>  $qval9,     # string
    );

L<OpenSearch documentation for cluster-E<gt>put_settings|https://opensearch.org/docs/latest/api-reference/cluster-settings/>
    
=head2 put_weighted_routing

Updates weighted shard routing weights.

I<Paths served by this method:>

=over

=item
C<PUT /_cluster/routing/awareness/{attribute}/weights>

=back

    $resp = $client->cluster->put_weighted_routing(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'attribute'    =>  $attribute,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for cluster-E<gt>put_weighted_routing|https://opensearch.org/docs/latest/api-reference/cluster-api/cluster-awareness/#example-weighted-round-robin-search>
    
=head2 remote_info

Returns the information about configured remote clusters.

I<Paths served by this method:>

=over

=item
C<GET /_remote/info>

=back

    $resp = $client->cluster->remote_info(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for cluster-E<gt>remote_info|https://opensearch.org/docs/latest/api-reference/remote-info/>
    
=head2 reroute

Allows to manually change the allocation of individual shards in the cluster.

I<Paths served by this method:>

=over

=item
C<POST /_cluster/reroute>

=back

    $resp = $client->cluster->reroute(
        
        'body'                     =>  $body,      # optional
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'dry_run'                  =>  $qval2,     # boolean
        'explain'                  =>  $qval3,     # boolean
        'master_timeout'           =>  $qval4,     # string
        'metric'                   =>  $qval5,     # list
        'retry_failed'             =>  $qval6,     # boolean
        'timeout'                  =>  $qval7,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval8,     # boolean
        'filter_path'              =>  $qval9,     # list
        'human'                    =>  $qval10,    # boolean
        'pretty'                   =>  $qval11,    # boolean
        'source'                   =>  $qval12,    # string
    );

L<OpenSearch documentation for cluster-E<gt>reroute|https://docs.opensearch.org/latest/api-reference/cluster-api/index/>
    
=head2 state

Returns comprehensive information about the state of the cluster.

I<Paths served by this method:>

=over

=item
C<GET /_cluster/state>

=item
C<GET /_cluster/state/{metric}>

=item
C<GET /_cluster/state/{metric}/{index}>

=back

    $resp = $client->cluster->state(
        
         # path parameters
        
        'index'                      =>  $index,     # optional
        'metric'                     =>  $metric,    # optional
        
         # Endpoint specific query string parameters
        
        'allow_no_indices'           =>  $qval1,     # boolean
        'cluster_manager_timeout'    =>  $qval2,     # string
        'expand_wildcards'           =>  $qval3,     # list
        'flat_settings'              =>  $qval4,     # boolean
        'ignore_unavailable'         =>  $qval5,     # boolean
        'local'                      =>  $qval6,     # boolean
        'master_timeout'             =>  $qval7,     # string
        'wait_for_metadata_version'  =>  $qval8,     # number
        'wait_for_timeout'           =>  $qval9,     # string
        
         # Common API query string parameters
        
        'error_trace'                =>  $qval10,    # boolean
        'filter_path'                =>  $qval11,    # list
        'human'                      =>  $qval12,    # boolean
        'pretty'                     =>  $qval13,    # boolean
        'source'                     =>  $qval14,    # string
    );

L<OpenSearch documentation for cluster-E<gt>state|https://docs.opensearch.org/latest/api-reference/cluster-api/index/>
    
=head2 stats

Returns a high-level overview of cluster statistics.

I<Paths served by this method:>

=over

=item
C<GET /_cluster/stats>

=item
C<GET /_cluster/stats/nodes/{node_id}>

=item
C<GET /_cluster/stats/{metric}/nodes/{node_id}>

=item
C<GET /_cluster/stats/{metric}/{index_metric}/nodes/{node_id}>

=back

    $resp = $client->cluster->stats(
        
         # path parameters
        
        'index_metric'   =>  $index_metric,  # optional
        'metric'         =>  $metric,    # optional
        'node_id'        =>  $node_id,   # optional
        
         # Endpoint specific query string parameters
        
        'flat_settings'  =>  $qval1,     # boolean
        'timeout'        =>  $qval2,     # string
        
         # Common API query string parameters
        
        'error_trace'    =>  $qval3,     # boolean
        'filter_path'    =>  $qval4,     # list
        'human'          =>  $qval5,     # boolean
        'pretty'         =>  $qval6,     # boolean
        'source'         =>  $qval7,     # string
    );

L<OpenSearch documentation for cluster-E<gt>stats|https://opensearch.org/docs/latest/api-reference/cluster-api/cluster-stats/>

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

