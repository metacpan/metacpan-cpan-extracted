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

package OpenSearch::Client::Core::3_0::Direct::Rollups;
$OpenSearch::Client::Core::3_0::Direct::Rollups::VERSION = '3.007006';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('rollups');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::Rollups>

=head1 VERSION

version 3.007006

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->rollups-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Index rollups API>


Time series data increases storage costs, strains cluster health, and slows down aggregations over time. Index rollup lets you periodically reduce data granularity by rolling up old data into summarized indexes.

L<See OpenSearch documentation for rollups.|https://docs.opensearch.org/latest/im-plugin/index-rollups/rollup-api/>

=head1 METHODS
    
=head2 delete

Deletes an index rollup job configuration.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_rollup/jobs/{id}>

=back

    $resp = $client->rollups->delete(
        
         # path parameters
        
        'id'           =>  $id,        # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for rollups-E<gt>delete|https://opensearch.org/docs/latest/im-plugin/index-rollups/rollup-api/#delete-an-index-rollup-job>
    
=head2 explain

Retrieves the execution status information for an index rollup job.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_rollup/jobs/{id}/_explain>

=back

    $resp = $client->rollups->explain(
        
         # path parameters
        
        'id'           =>  $id,        # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for rollups-E<gt>explain|https://opensearch.org/docs/latest/im-plugin/index-rollups/rollup-api/#explain-an-index-rollup-job>
    
=head2 get

Retrieves an index rollup job configuration by ID.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_rollup/jobs/{id}>

=back

    $resp = $client->rollups->get(
        
         # path parameters
        
        'id'           =>  $id,        # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for rollups-E<gt>get|https://opensearch.org/docs/latest/im-plugin/index-rollups/rollup-api/#get-an-index-rollup-job>
    
=head2 put

Creates or updates an index rollup job configuration.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_rollup/jobs/{id}>

=back

    $resp = $client->rollups->put(
        
        'body'             =>  $body,      # optional
        
         # path parameters
        
        'id'               =>  $id,        # required
        
         # Endpoint specific query string parameters
        
        'if_primary_term'  =>  $qval1,     # number
        'if_seq_no'        =>  $qval2,     # number
        
         # Common API query string parameters
        
        'error_trace'      =>  $qval3,     # boolean
        'filter_path'      =>  $qval4,     # list
        'human'            =>  $qval5,     # boolean
        'pretty'           =>  $qval6,     # boolean
        'source'           =>  $qval7,     # string
    );

L<OpenSearch documentation for rollups-E<gt>put|https://opensearch.org/docs/latest/im-plugin/index-rollups/rollup-api/#create-or-update-an-index-rollup-job>
    
=head2 start

Starts the execution of an index rollup job.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_rollup/jobs/{id}/_start>

=back

    $resp = $client->rollups->start(
        
         # path parameters
        
        'id'           =>  $id,        # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for rollups-E<gt>start|https://opensearch.org/docs/latest/im-plugin/index-rollups/rollup-api/#start-or-stop-an-index-rollup-job>
    
=head2 stop

Stops the execution of an index rollup job.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_rollup/jobs/{id}/_stop>

=back

    $resp = $client->rollups->stop(
        
         # path parameters
        
        'id'           =>  $id,        # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for rollups-E<gt>stop|https://opensearch.org/docs/latest/im-plugin/index-rollups/rollup-api/#start-or-stop-an-index-rollup-job>

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

