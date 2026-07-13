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

package OpenSearch::Client::Core::3_0::Direct::Nodes;
$OpenSearch::Client::Core::3_0::Direct::Nodes::VERSION = '3.007008';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('nodes');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::Nodes>

=head1 VERSION

version 3.007008

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->nodes-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Nodes APIs>


The Nodes API makes it possible to retrieve information about individual nodes in your cluster.

L<See OpenSearch documentation for nodes.|https://docs.opensearch.org/latest/api-reference/nodes-apis/index/>

=head1 METHODS
    
=head2 hot_threads

Returns information about hot threads on each node in the cluster.

I<Paths served by this method:>

=over

=item
C<GET /_nodes/hot_threads>

=item
C<GET /_nodes/{node_id}/hot_threads>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->nodes->hot_threads(
        
         # path parameters
        
        'node_id'              =>  $node_id,   # optional
        
         # Endpoint specific query string parameters
        
        'ignore_idle_threads'  =>  $qval1,     # boolean
        'interval'             =>  $qval2,     # string
        'snapshots'            =>  $qval3,     # number
        'threads'              =>  $qval4,     # number
        'timeout'              =>  $qval5,     # string
        'type'                 =>  $qval6,     # string
        
         # Common API query string parameters
        
        'error_trace'          =>  $qval7,     # boolean
        'filter_path'          =>  $qval8,     # list
        'human'                =>  $qval9,     # boolean
        'pretty'               =>  $qval10,    # boolean
        'source'               =>  $qval11,    # string
    );

L<OpenSearch documentation for nodes-E<gt>hot_threads|https://opensearch.org/docs/latest/api-reference/nodes-apis/nodes-hot-threads/>
    
=head2 info

Returns information about nodes in the cluster.

I<Paths served by this method:>

=over

=item
C<GET /_nodes>

=item
C<GET /_nodes/{metric}>

=item
C<GET /_nodes/{node_id}>

=item
C<GET /_nodes/{node_id}/{metric}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->nodes->info(
        
         # path parameters
        
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

L<OpenSearch documentation for nodes-E<gt>info|https://opensearch.org/docs/latest/api-reference/nodes-apis/nodes-info/>
    
=head2 reload_secure_settings

Reloads secure settings.

I<Paths served by this method:>

=over

=item
C<POST /_nodes/reload_secure_settings>

=item
C<POST /_nodes/{node_id}/reload_secure_settings>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->nodes->reload_secure_settings(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'node_id'      =>  $node_id,   # optional
        
         # Endpoint specific query string parameters
        
        'timeout'      =>  $qval1,     # string
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval2,     # boolean
        'filter_path'  =>  $qval3,     # list
        'human'        =>  $qval4,     # boolean
        'pretty'       =>  $qval5,     # boolean
        'source'       =>  $qval6,     # string
    );

L<OpenSearch documentation for nodes-E<gt>reload_secure_settings|https://opensearch.org/docs/latest/api-reference/nodes-apis/nodes-reload-secure/>
    
=head2 stats

Returns statistical information about nodes in the cluster.

I<Paths served by this method:>

=over

=item
C<GET /_nodes/stats>

=item
C<GET /_nodes/stats/{metric}>

=item
C<GET /_nodes/stats/{metric}/{index_metric}>

=item
C<GET /_nodes/{node_id}/stats>

=item
C<GET /_nodes/{node_id}/stats/{metric}>

=item
C<GET /_nodes/{node_id}/stats/{metric}/{index_metric}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->nodes->stats(
        
         # path parameters
        
        'index_metric'                =>  $index_metric,  # optional
        'metric'                      =>  $metric,    # optional
        'node_id'                     =>  $node_id,   # optional
        
         # Endpoint specific query string parameters
        
        'completion_fields'           =>  $qval1,     # list
        'fielddata_fields'            =>  $qval2,     # list
        'fields'                      =>  $qval3,     # list
        'groups'                      =>  $qval4,     # list
        'include_segment_file_sizes'  =>  $qval5,     # boolean
        'level'                       =>  $qval6,     # string
        'timeout'                     =>  $qval7,     # string
        'types'                       =>  $qval8,     # list
        
         # Common API query string parameters
        
        'error_trace'                 =>  $qval9,     # boolean
        'filter_path'                 =>  $qval10,    # list
        'human'                       =>  $qval11,    # boolean
        'pretty'                      =>  $qval12,    # boolean
        'source'                      =>  $qval13,    # string
    );

L<OpenSearch documentation for nodes-E<gt>stats|https://opensearch.org/docs/latest/api-reference/nodes-apis/nodes-usage/>
    
=head2 usage

Returns low-level information about REST actions usage on nodes.

I<Paths served by this method:>

=over

=item
C<GET /_nodes/usage>

=item
C<GET /_nodes/usage/{metric}>

=item
C<GET /_nodes/{node_id}/usage>

=item
C<GET /_nodes/{node_id}/usage/{metric}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->nodes->usage(
        
         # path parameters
        
        'metric'       =>  $metric,    # optional
        'node_id'      =>  $node_id,   # optional
        
         # Endpoint specific query string parameters
        
        'timeout'      =>  $qval1,     # string
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval2,     # boolean
        'filter_path'  =>  $qval3,     # list
        'human'        =>  $qval4,     # boolean
        'pretty'       =>  $qval5,     # boolean
        'source'       =>  $qval6,     # string
    );

L<OpenSearch documentation for nodes-E<gt>usage|https://docs.opensearch.org/latest/api-reference/nodes-apis/index/>

=head2 method_supported_in_version

Return whether a method in this module namespace is supported for an OpenSearch server version

    my $boolean = $os->nodes->method_supported_in_version(
        method  => 'hot_threads',
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

