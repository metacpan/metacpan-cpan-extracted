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

package OpenSearch::Client::Core::3_0::Direct::Snapshot;
$OpenSearch::Client::Core::3_0::Direct::Snapshot::VERSION = '3.007005';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('snapshot');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::Snapshot>

=head1 VERSION

version 3.007005

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->snapshot-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Snapshot APIs>


The snapshot APIs allow you to manage snapshots and snapshot repositories.

L<See OpenSearch documentation for snapshot.|https://docs.opensearch.org/latest/api-reference/snapshots/index/>

=head1 METHODS
    
=head2 snapshot->cleanup_repository

Removes any stale data from a snapshot repository.

I<Paths served by this method:>

=over

=item
C<POST /_snapshot/{repository}/_cleanup>

=back

    $resp = $client->snapshot->cleanup_repository(
        
         # path parameters
        
        'repository'               =>  $repository,  # required
        
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

L<OpenSearch documentation for snapshot.cleanup_repository|https://docs.opensearch.org/latest/api-reference/snapshots/index/>
    
=head2 snapshot->clone

Creates a clone of all or part of a snapshot in the same repository as the original snapshot.

I<Paths served by this method:>

=over

=item
C<PUT /_snapshot/{repository}/{snapshot}/_clone/{target_snapshot}>

=back

    $resp = $client->snapshot->clone(
        
        'body'                     =>  $body,      # optional
        
         # path parameters
        
        'repository'               =>  $repository,  # required
        'snapshot'                 =>  $snapshot,  # required
        'target_snapshot'          =>  $target_snapshot,  # required
        
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

L<OpenSearch documentation for snapshot.clone|https://docs.opensearch.org/latest/api-reference/snapshots/index/>
    
=head2 snapshot->create

Creates a snapshot within an existing repository.

I<Paths served by this method:>

=over

=item
C<POST /_snapshot/{repository}/{snapshot}>

=item
C<PUT /_snapshot/{repository}/{snapshot}>

=back

    $resp = $client->snapshot->create(
        
        'body'                     =>  $body,      # optional
        
         # path parameters
        
        'repository'               =>  $repository,  # required
        'snapshot'                 =>  $snapshot,  # required
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'master_timeout'           =>  $qval2,     # string
        'wait_for_completion'      =>  $qval3,     # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval4,     # boolean
        'filter_path'              =>  $qval5,     # list
        'human'                    =>  $qval6,     # boolean
        'pretty'                   =>  $qval7,     # boolean
        'source'                   =>  $qval8,     # string
    );

L<OpenSearch documentation for snapshot.create|https://opensearch.org/docs/latest/api-reference/snapshots/create-snapshot/>
    
=head2 snapshot->create_repository

Creates a snapshot repository.

I<Paths served by this method:>

=over

=item
C<POST /_snapshot/{repository}>

=item
C<PUT /_snapshot/{repository}>

=back

    $resp = $client->snapshot->create_repository(
        
        'body'                     =>  $body,      # required
        
         # path parameters
        
        'repository'               =>  $repository,  # required
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'master_timeout'           =>  $qval2,     # string
        'timeout'                  =>  $qval3,     # string
        'verify'                   =>  $qval4,     # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval5,     # boolean
        'filter_path'              =>  $qval6,     # list
        'human'                    =>  $qval7,     # boolean
        'pretty'                   =>  $qval8,     # boolean
        'source'                   =>  $qval9,     # string
    );

L<OpenSearch documentation for snapshot.create_repository|https://opensearch.org/docs/latest/api-reference/snapshots/create-repository/>
    
=head2 snapshot->delete

Deletes a snapshot.

I<Paths served by this method:>

=over

=item
C<DELETE /_snapshot/{repository}/{snapshot}>

=back

    $resp = $client->snapshot->delete(
        
         # path parameters
        
        'repository'               =>  $repository,  # required
        'snapshot'                 =>  $snapshot,  # required
        
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

L<OpenSearch documentation for snapshot.delete|https://opensearch.org/docs/latest/api-reference/snapshots/delete-snapshot/>
    
=head2 snapshot->delete_repository

Deletes a snapshot repository.

I<Paths served by this method:>

=over

=item
C<DELETE /_snapshot/{repository}>

=back

    $resp = $client->snapshot->delete_repository(
        
         # path parameters
        
        'repository'               =>  $repository,  # required
        
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

L<OpenSearch documentation for snapshot.delete_repository|https://opensearch.org/docs/latest/api-reference/snapshots/delete-snapshot-repository/>
    
=head2 snapshot->get

Returns information about a snapshot.

I<Paths served by this method:>

=over

=item
C<GET /_snapshot/{repository}/{snapshot}>

=back

    $resp = $client->snapshot->get(
        
         # path parameters
        
        'repository'               =>  $repository,  # required
        'snapshot'                 =>  $snapshot,  # required
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'ignore_unavailable'       =>  $qval2,     # boolean
        'master_timeout'           =>  $qval3,     # string
        'verbose'                  =>  $qval4,     # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval5,     # boolean
        'filter_path'              =>  $qval6,     # list
        'human'                    =>  $qval7,     # boolean
        'pretty'                   =>  $qval8,     # boolean
        'source'                   =>  $qval9,     # string
    );

L<OpenSearch documentation for snapshot.get|https://docs.opensearch.org/latest/api-reference/snapshots/index/>
    
=head2 snapshot->get_repository

Returns information about a snapshot repository.

I<Paths served by this method:>

=over

=item
C<GET /_snapshot>

=item
C<GET /_snapshot/{repository}>

=back

    $resp = $client->snapshot->get_repository(
        
         # path parameters
        
        'repository'               =>  $repository,  # optional
        
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

L<OpenSearch documentation for snapshot.get_repository|https://opensearch.org/docs/latest/api-reference/snapshots/get-snapshot-repository/>
    
=head2 snapshot->restore

Restores a snapshot.

I<Paths served by this method:>

=over

=item
C<POST /_snapshot/{repository}/{snapshot}/_restore>

=back

    $resp = $client->snapshot->restore(
        
        'body'                     =>  $body,      # optional
        
         # path parameters
        
        'repository'               =>  $repository,  # required
        'snapshot'                 =>  $snapshot,  # required
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'master_timeout'           =>  $qval2,     # string
        'wait_for_completion'      =>  $qval3,     # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval4,     # boolean
        'filter_path'              =>  $qval5,     # list
        'human'                    =>  $qval6,     # boolean
        'pretty'                   =>  $qval7,     # boolean
        'source'                   =>  $qval8,     # string
    );

L<OpenSearch documentation for snapshot.restore|https://opensearch.org/docs/latest/api-reference/snapshots/restore-snapshot/>
    
=head2 snapshot->status

Returns information about the status of a snapshot.

I<Paths served by this method:>

=over

=item
C<GET /_snapshot/_status>

=item
C<GET /_snapshot/{repository}/_status>

=item
C<GET /_snapshot/{repository}/{snapshot}/_status>

=back

    $resp = $client->snapshot->status(
        
         # path parameters
        
        'repository'               =>  $repository,  # optional
        'snapshot'                 =>  $snapshot,  # optional
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'ignore_unavailable'       =>  $qval2,     # boolean
        'master_timeout'           =>  $qval3,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval4,     # boolean
        'filter_path'              =>  $qval5,     # list
        'human'                    =>  $qval6,     # boolean
        'pretty'                   =>  $qval7,     # boolean
        'source'                   =>  $qval8,     # string
    );

L<OpenSearch documentation for snapshot.status|https://opensearch.org/docs/latest/api-reference/snapshots/get-snapshot-status/>
    
=head2 snapshot->verify_repository

Verifies a repository.

I<Paths served by this method:>

=over

=item
C<POST /_snapshot/{repository}/_verify>

=back

    $resp = $client->snapshot->verify_repository(
        
         # path parameters
        
        'repository'               =>  $repository,  # required
        
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

L<OpenSearch documentation for snapshot.verify_repository|https://opensearch.org/docs/latest/api-reference/snapshots/verify-snapshot-repository/>

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

