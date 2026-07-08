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

package OpenSearch::Client::Core::3_0::Direct::Transforms;
$OpenSearch::Client::Core::3_0::Direct::Transforms::VERSION = '3.007006';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('transforms');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::Transforms>

=head1 VERSION

version 3.007006

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->transforms-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Index transforms>


Whereas index rollup jobs let you reduce data granularity by rolling up old data into condensed indexes, transform jobs let you create a different, summarized view of your data centered around certain fields, so you can visualize or analyze the data in different ways.

L<See OpenSearch documentation for transforms.|https://docs.opensearch.org/latest/im-plugin/index-transforms/transforms-apis/>

=head1 METHODS
    
=head2 delete

Delete an index transform.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_transform/{id}>

=back

    $resp = $client->transforms->delete(
        
         # path parameters
        
        'id'           =>  $id,        # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for transforms-E<gt>delete|https://opensearch.org/docs/latest/im-plugin/index-transforms/transforms-apis/#delete-a-transform-job>
    
=head2 explain

Returns the status and metadata of a transform job.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_transform/{id}/_explain>

=back

    $resp = $client->transforms->explain(
        
         # path parameters
        
        'id'           =>  $id,        # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for transforms-E<gt>explain|https://opensearch.org/docs/latest/im-plugin/index-transforms/transforms-apis/#get-the-status-of-a-transform-job>
    
=head2 get

Returns the status and metadata of a transform job.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_transform/{id}>

=back

    $resp = $client->transforms->get(
        
         # path parameters
        
        'id'           =>  $id,        # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for transforms-E<gt>get|https://opensearch.org/docs/latest/im-plugin/index-transforms/transforms-apis/#get-a-transform-jobs-details>
    
=head2 preview

Returns a preview of what a transformed index would look like.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_transform/_preview>

=back

    $resp = $client->transforms->preview(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for transforms-E<gt>preview|https://opensearch.org/docs/latest/im-plugin/index-transforms/transforms-apis/#preview-a-transform-jobs-results>
    
=head2 put

Create an index transform, or update a transform if `if_seq_no` and `if_primary_term` are provided.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_transform/{id}>

=back

    $resp = $client->transforms->put(
        
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

L<OpenSearch documentation for transforms-E<gt>put|https://opensearch.org/docs/latest/im-plugin/index-transforms/transforms-apis/#create-a-transform-job>
    
=head2 search

Returns the details of all transform jobs.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_transform>

=back

    $resp = $client->transforms->search(
        
         # Endpoint specific query string parameters
        
        'from'           =>  $qval1,     # number
        'search'         =>  $qval2,     # string
        'size'           =>  $qval3,     # number
        'sortDirection'  =>  $qval4,     # string
        'sortField'      =>  $qval5,     # string
        
         # Common API query string parameters
        
        'error_trace'    =>  $qval6,     # boolean
        'filter_path'    =>  $qval7,     # list
        'human'          =>  $qval8,     # boolean
        'pretty'         =>  $qval9,     # boolean
        'source'         =>  $qval10,    # string
    );

L<OpenSearch documentation for transforms-E<gt>search|https://opensearch.org/docs/latest/im-plugin/index-transforms/transforms-apis/#get-a-transform-jobs-details>
    
=head2 start

Start transform.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_transform/{id}/_start>

=back

    $resp = $client->transforms->start(
        
         # path parameters
        
        'id'           =>  $id,        # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for transforms-E<gt>start|https://opensearch.org/docs/latest/im-plugin/index-transforms/transforms-apis/#start-a-transform-job>
    
=head2 stop

Stop transform.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_transform/{id}/_stop>

=back

    $resp = $client->transforms->stop(
        
         # path parameters
        
        'id'           =>  $id,        # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for transforms-E<gt>stop|https://opensearch.org/docs/latest/im-plugin/index-transforms/transforms-apis/#stop-a-transform-job>

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

