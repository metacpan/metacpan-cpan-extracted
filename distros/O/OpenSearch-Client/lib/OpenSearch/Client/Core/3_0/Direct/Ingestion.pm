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

package OpenSearch::Client::Core::3_0::Direct::Ingestion;
$OpenSearch::Client::Core::3_0::Direct::Ingestion::VERSION = '3.007007';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('ingestion');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::Ingestion>

=head1 VERSION

version 3.007007

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->ingestion-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Pull-based Ingestion Management>


Pull-based ingestion enables OpenSearch to ingest data from streaming sources such as Apache Kafka or Amazon Kinesis. Unlike traditional ingestion methods where clients actively push data to OpenSearch through REST APIs, pull-based ingestion allows OpenSearch to control the data flow by retrieving data directly from streaming sources. This approach provides native backpressure handling, helping prevent server overload during traffic spikes. Pull-based ingestion guarantees at-least-once ingestion semantics and uses external versioning to ensure data consistency.

L<See OpenSearch documentation for ingestion.|https://docs.opensearch.org/latest/api-reference/document-apis/pull-based-ingestion/>

=head1 METHODS
    
=head2 get_state

Use this API to retrieve the ingestion state for a given index.

I<Paths served by this method:>

=over

=item
C<GET /{index}/ingestion/_state>

=back

    $resp = $client->ingestion->get_state(
        
         # path parameters
        
        'index'        =>  $index,     # required
        
         # Endpoint specific query string parameters
        
        'next_token'   =>  $qval1,     # string
        'size'         =>  $qval2,     # number
        'timeout'      =>  $qval3,     # string
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval4,     # boolean
        'filter_path'  =>  $qval5,     # list
        'human'        =>  $qval6,     # boolean
        'pretty'       =>  $qval7,     # boolean
        'source'       =>  $qval8,     # string
    );

L<OpenSearch documentation for ingestion-E<gt>get_state|https://docs.opensearch.org/docs/latest/api-reference/document-apis/pull-based-ingestion-management/>
    
=head2 pause

Use this API to pause ingestion for a given index.

I<Paths served by this method:>

=over

=item
C<POST /{index}/ingestion/_pause>

=back

    $resp = $client->ingestion->pause(
        
         # path parameters
        
        'index'                    =>  $index,     # required
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'timeout'                  =>  $qval2,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval3,     # boolean
        'filter_path'              =>  $qval4,     # list
        'human'                    =>  $qval5,     # boolean
        'pretty'                   =>  $qval6,     # boolean
        'source'                   =>  $qval7,     # string
    );

L<OpenSearch documentation for ingestion-E<gt>pause|https://docs.opensearch.org/docs/latest/api-reference/document-apis/pull-based-ingestion-management/>
    
=head2 resume

Use this API to resume ingestion for the given index.

I<Paths served by this method:>

=over

=item
C<POST /{index}/ingestion/_resume>

=back

    $resp = $client->ingestion->resume(
        
        'body'                     =>  $body,      # optional
        
         # path parameters
        
        'index'                    =>  $index,     # required
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'timeout'                  =>  $qval2,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval3,     # boolean
        'filter_path'              =>  $qval4,     # list
        'human'                    =>  $qval5,     # boolean
        'pretty'                   =>  $qval6,     # boolean
        'source'                   =>  $qval7,     # string
    );

L<OpenSearch documentation for ingestion-E<gt>resume|https://docs.opensearch.org/docs/latest/api-reference/document-apis/pull-based-ingestion-management/>

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

