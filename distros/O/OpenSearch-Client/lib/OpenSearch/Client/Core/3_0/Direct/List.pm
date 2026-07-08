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

package OpenSearch::Client::Core::3_0::Direct::List;
$OpenSearch::Client::Core::3_0::Direct::List::VERSION = '3.007006';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('list');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::List>

=head1 VERSION

version 3.007006

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->list-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<List APIs>


The List API retrieves statistics about indexes and shards in a paginated format. This streamlines the task of processing responses that include many indexes.

L<See OpenSearch documentation for list.|https://docs.opensearch.org/latest/api-reference/list/index/>

=head1 METHODS
    
=head2 help

Returns help for the List APIs.

I<Paths served by this method:>

=over

=item
C<GET /_list>

=back

    $resp = $client->list->help(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for list-E<gt>help|https://opensearch.org/docs/latest/api-reference/list/index/>
    
=head2 indices

Returns paginated information about indexes including number of primaries and replicas, document counts, disk size.

I<Paths served by this method:>

=over

=item
C<GET /_list/indices>

=item
C<GET /_list/indices/{index}>

=back

    $resp = $client->list->indices(
        
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
        'next_token'                 =>  $qval11,    # string
        'pri'                        =>  $qval12,    # boolean
        's'                          =>  $qval13,    # list
        'size'                       =>  $qval14,    # number
        'sort'                       =>  $qval15,    # string
        'time'                       =>  $qval16,    # string
        'v'                          =>  $qval17,    # boolean
        
         # Common API query string parameters
        
        'error_trace'                =>  $qval18,    # boolean
        'filter_path'                =>  $qval19,    # list
        'human'                      =>  $qval20,    # boolean
        'pretty'                     =>  $qval21,    # boolean
        'source'                     =>  $qval22,    # string
    );

L<OpenSearch documentation for list-E<gt>indices|https://opensearch.org/docs/latest/api-reference/list/list-indices/>
    
=head2 shards

Returns paginated details of shard allocation on nodes.

I<Paths served by this method:>

=over

=item
C<GET /_list/shards>

=item
C<GET /_list/shards/{index}>

=back

    $resp = $client->list->shards(
        
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
        'next_token'               =>  $qval8,     # string
        's'                        =>  $qval9,     # list
        'size'                     =>  $qval10,    # number
        'sort'                     =>  $qval11,    # string
        'time'                     =>  $qval12,    # string
        'v'                        =>  $qval13,    # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval14,    # boolean
        'filter_path'              =>  $qval15,    # list
        'human'                    =>  $qval16,    # boolean
        'pretty'                   =>  $qval17,    # boolean
        'source'                   =>  $qval18,    # string
    );

L<OpenSearch documentation for list-E<gt>shards|https://opensearch.org/docs/latest/api-reference/list/list-shards/>

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

