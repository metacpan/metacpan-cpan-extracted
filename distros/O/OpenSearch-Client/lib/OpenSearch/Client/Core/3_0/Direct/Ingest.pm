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

package OpenSearch::Client::Core::3_0::Direct::Ingest;
$OpenSearch::Client::Core::3_0::Direct::Ingest::VERSION = '3.007005';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('ingest');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::Ingest>

=head1 VERSION

version 3.007005

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->ingest-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Ingest APIs>


Ingest APIs are a valuable tool for loading data into a system. Ingest APIs work together with ingest pipelines and ingest processors to process or transform data from a variety of sources and in a variety of formats.

L<See OpenSearch documentation for ingest.|https://docs.opensearch.org/latest/api-reference/ingest-apis/index/>

=head1 METHODS
    
=head2 ingest->delete_pipeline

Deletes an ingest pipeline.

I<Paths served by this method:>

=over

=item
C<DELETE /_ingest/pipeline/{id}>

=back

    $resp = $client->ingest->delete_pipeline(
        
         # path parameters
        
        'id'                       =>  $id,        # required
        
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

L<OpenSearch documentation for ingest.delete_pipeline|https://opensearch.org/docs/latest/api-reference/ingest-apis/delete-ingest/>
    
=head2 ingest->get_pipeline

Returns an ingest pipeline.

I<Paths served by this method:>

=over

=item
C<GET /_ingest/pipeline>

=item
C<GET /_ingest/pipeline/{id}>

=back

    $resp = $client->ingest->get_pipeline(
        
         # path parameters
        
        'id'                       =>  $id,        # optional
        
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

L<OpenSearch documentation for ingest.get_pipeline|https://opensearch.org/docs/latest/api-reference/ingest-apis/get-ingest/>
    
=head2 ingest->processor_grok

Returns a list of built-in grok patterns.

I<Paths served by this method:>

=over

=item
C<GET /_ingest/processor/grok>

=back

    $resp = $client->ingest->processor_grok(
        
         # Endpoint specific query string parameters
        
        's'            =>  $qval1,     # boolean
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval2,     # boolean
        'filter_path'  =>  $qval3,     # list
        'human'        =>  $qval4,     # boolean
        'pretty'       =>  $qval5,     # boolean
        'source'       =>  $qval6,     # string
    );

L<OpenSearch documentation for ingest.processor_grok|https://docs.opensearch.org/latest/api-reference/ingest-apis/index/>
    
=head2 ingest->put_pipeline

Creates or updates an ingest pipeline.

I<Paths served by this method:>

=over

=item
C<PUT /_ingest/pipeline/{id}>

=back

    $resp = $client->ingest->put_pipeline(
        
        'body'                     =>  $body,      # optional
        
         # path parameters
        
        'id'                       =>  $id,        # required
        
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

L<OpenSearch documentation for ingest.put_pipeline|https://docs.opensearch.org/latest/ingest-pipelines/create-ingest/>
    
=head2 ingest->simulate

Simulates an ingest pipeline with example documents.

I<Paths served by this method:>

=over

=item
C<GET /_ingest/pipeline/_simulate>

=item
C<GET /_ingest/pipeline/{id}/_simulate>

=item
C<POST /_ingest/pipeline/_simulate>

=item
C<POST /_ingest/pipeline/{id}/_simulate>

=back

    $resp = $client->ingest->simulate(
        
        'body'         =>  $body,      # required
        
         # path parameters
        
        'id'           =>  $id,        # optional
        
         # Endpoint specific query string parameters
        
        'verbose'      =>  $qval1,     # boolean
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval2,     # boolean
        'filter_path'  =>  $qval3,     # list
        'human'        =>  $qval4,     # boolean
        'pretty'       =>  $qval5,     # boolean
        'source'       =>  $qval6,     # string
    );

L<OpenSearch documentation for ingest.simulate|https://opensearch.org/docs/latest/api-reference/ingest-apis/simulate-ingest/>

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

