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

package OpenSearch::Client::Core::3_0::Direct::Replication;
$OpenSearch::Client::Core::3_0::Direct::Replication::VERSION = '3.007002';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('replication');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::Replication>

=head1 VERSION

version 3.007002

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->replication-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Cross-cluster replication>


Use these replication operations to programmatically manage cross-cluster replication.

L<See OpenSearch documentation for replication.|https://docs.opensearch.org/latest/tuning-your-cluster/replication-plugin/api/>

=head1 METHODS
    
=head2 replication->autofollow_stats

Retrieves information about any auto-follow activity and any replication rules configured on the specified cluster.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_replication/autofollow_stats>

=back

    $resp = $client->replication->autofollow_stats(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for replication.autofollow_stats|https://opensearch.org/docs/latest/tuning-your-cluster/replication-plugin/api/#get-auto-follow-stats>
    
=head2 replication->create_replication_rule

Automatically starts the replication on indexes matching a specified pattern.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_replication/_autofollow>

=back

    $resp = $client->replication->create_replication_rule(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for replication.create_replication_rule|https://opensearch.org/docs/latest/tuning-your-cluster/replication-plugin/api/#create-replication-rule>
    
=head2 replication->delete_replication_rule

Deletes the specified replication rule.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_replication/_autofollow>

=back

    $resp = $client->replication->delete_replication_rule(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for replication.delete_replication_rule|https://opensearch.org/docs/latest/tuning-your-cluster/replication-plugin/api/#delete-replication-rule>
    
=head2 replication->follower_stats

Retrieves information about any follower (syncing) indexes on a specified cluster.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_replication/follower_stats>

=back

    $resp = $client->replication->follower_stats(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for replication.follower_stats|https://opensearch.org/docs/latest/tuning-your-cluster/replication-plugin/api/#get-follower-cluster-stats>
    
=head2 replication->leader_stats

Retrieves information about any replicated leader indexes on a specified cluster.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_replication/leader_stats>

=back

    $resp = $client->replication->leader_stats(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for replication.leader_stats|https://opensearch.org/docs/latest/tuning-your-cluster/replication-plugin/api/#get-leader-cluster-stats>
    
=head2 replication->pause

Pauses the replication of the leader index.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_replication/{index}/_pause>

=back

    $resp = $client->replication->pause(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'index'        =>  $index,     # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for replication.pause|https://opensearch.org/docs/latest/tuning-your-cluster/replication-plugin/api/#pause-replication>
    
=head2 replication->resume

Resumes replication of the leader index.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_replication/{index}/_resume>

=back

    $resp = $client->replication->resume(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'index'        =>  $index,     # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for replication.resume|https://opensearch.org/docs/latest/tuning-your-cluster/replication-plugin/api/#resume-replication>
    
=head2 replication->start

Initiates the replication of an index from the leader cluster to the follower cluster.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_replication/{index}/_start>

=back

    $resp = $client->replication->start(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'index'        =>  $index,     # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for replication.start|https://opensearch.org/docs/latest/tuning-your-cluster/replication-plugin/api/#start-replication>
    
=head2 replication->status

Retrieves the the status of an index replication.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_replication/{index}/_status>

=back

    $resp = $client->replication->status(
        
         # path parameters
        
        'index'        =>  $index,     # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for replication.status|https://opensearch.org/docs/latest/tuning-your-cluster/replication-plugin/api/#get-replication-status>
    
=head2 replication->stop

Terminates the replication and converts the follower index to a standard index.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_replication/{index}/_stop>

=back

    $resp = $client->replication->stop(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'index'        =>  $index,     # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for replication.stop|https://opensearch.org/docs/latest/tuning-your-cluster/replication-plugin/api/#stop-replication>
    
=head2 replication->update_settings

Updates any settings on the follower index.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_replication/{index}/_update>

=back

    $resp = $client->replication->update_settings(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'index'        =>  $index,     # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for replication.update_settings|https://opensearch.org/docs/latest/tuning-your-cluster/replication-plugin/api/#update-settings>

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

