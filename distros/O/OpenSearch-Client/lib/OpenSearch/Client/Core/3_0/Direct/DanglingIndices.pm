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

package OpenSearch::Client::Core::3_0::Direct::DanglingIndices;
$OpenSearch::Client::Core::3_0::Direct::DanglingIndices::VERSION = '3.007002';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('dangling_indices');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::DanglingIndices>

=head1 VERSION

version 3.007002

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->dangling_indices-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Dangling indexes>


After a node joins a cluster, dangling indexes occur if any shards exist in the node's local directory that do not already exist in the cluster. Dangling indexes can be listed, deleted, or imported.

L<See OpenSearch documentation for dangling_indices.|https://docs.opensearch.org/latest/api-reference/index-apis/dangling-index/>

=head1 METHODS
    
=head2 dangling_indices->delete_dangling_index

Deletes the specified dangling index.

I<Paths served by this method:>

=over

=item
C<DELETE /_dangling/{index_uuid}>

=back

    $resp = $client->dangling_indices->delete_dangling_index(
        
         # path parameters
        
        'index_uuid'               =>  $index_uuid,  # required
        
         # Endpoint specific query string parameters
        
        'accept_data_loss'         =>  $qval1,     # boolean
        'cluster_manager_timeout'  =>  $qval2,     # string
        'master_timeout'           =>  $qval3,     # string
        'timeout'                  =>  $qval4,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval5,     # boolean
        'filter_path'              =>  $qval6,     # list
        'human'                    =>  $qval7,     # boolean
        'pretty'                   =>  $qval8,     # boolean
        'source'                   =>  $qval9,     # string
    );

L<OpenSearch documentation for dangling_indices.delete_dangling_index|https://opensearch.org/docs/latest/api-reference/index-apis/dangling-index/>
    
=head2 dangling_indices->import_dangling_index

Imports the specified dangling index.

I<Paths served by this method:>

=over

=item
C<POST /_dangling/{index_uuid}>

=back

    $resp = $client->dangling_indices->import_dangling_index(
        
         # path parameters
        
        'index_uuid'               =>  $index_uuid,  # required
        
         # Endpoint specific query string parameters
        
        'accept_data_loss'         =>  $qval1,     # boolean
        'cluster_manager_timeout'  =>  $qval2,     # string
        'master_timeout'           =>  $qval3,     # string
        'timeout'                  =>  $qval4,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval5,     # boolean
        'filter_path'              =>  $qval6,     # list
        'human'                    =>  $qval7,     # boolean
        'pretty'                   =>  $qval8,     # boolean
        'source'                   =>  $qval9,     # string
    );

L<OpenSearch documentation for dangling_indices.import_dangling_index|https://opensearch.org/docs/latest/api-reference/index-apis/dangling-index/>
    
=head2 dangling_indices->list_dangling_indices

Returns all dangling indexes.

I<Paths served by this method:>

=over

=item
C<GET /_dangling>

=back

    $resp = $client->dangling_indices->list_dangling_indices(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for dangling_indices.list_dangling_indices|https://opensearch.org/docs/latest/api-reference/index-apis/dangling-index/>

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

