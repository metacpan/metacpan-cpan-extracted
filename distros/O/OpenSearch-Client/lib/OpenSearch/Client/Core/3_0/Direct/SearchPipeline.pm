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

package OpenSearch::Client::Core::3_0::Direct::SearchPipeline;
$OpenSearch::Client::Core::3_0::Direct::SearchPipeline::VERSION = '3.007007';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('search_pipeline');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::SearchPipeline>

=head1 VERSION

version 3.007007

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->search_pipeline-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Search pipelines>


You can use search pipelines to build new or reuse existing result rerankers, query rewriters, and other components that operate on queries or results. Search pipelines make it easier for you to process search queries and search results within OpenSearch. Moving some of your application functionality into an OpenSearch search pipeline reduces the overall complexity of your application. As part of a search pipeline, you specify a list of search processors that perform modular tasks. You can then easily add or reorder these processors to customize search results for your application.

L<See OpenSearch documentation for search_pipeline.|https://docs.opensearch.org/latest/search-plugins/search-pipelines/index/>

=head1 METHODS
    
=head2 delete

Deletes the specified search pipeline.

I<Paths served by this method:>

=over

=item
C<DELETE /_search/pipeline/{id}>

=back

    $resp = $client->search_pipeline->delete(
        
         # path parameters
        
        'id'                       =>  $id,        # required
        
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

L<OpenSearch documentation for search_pipeline-E<gt>delete|https://docs.opensearch.org/latest/search-plugins/search-pipelines/index/>
    
=head2 get

Retrieves information about a specified search pipeline.

I<Paths served by this method:>

=over

=item
C<GET /_search/pipeline>

=item
C<GET /_search/pipeline/{id}>

=back

    $resp = $client->search_pipeline->get(
        
         # path parameters
        
        'id'                       =>  $id,        # optional
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval2,     # boolean
        'filter_path'              =>  $qval3,     # list
        'human'                    =>  $qval4,     # boolean
        'pretty'                   =>  $qval5,     # boolean
        'source'                   =>  $qval6,     # string
    );

L<OpenSearch documentation for search_pipeline-E<gt>get|https://docs.opensearch.org/latest/search-plugins/search-pipelines/index/>
    
=head2 put

Creates or replaces the specified search pipeline.

I<Paths served by this method:>

=over

=item
C<PUT /_search/pipeline/{id}>

=back

    $resp = $client->search_pipeline->put(
        
        'body'                     =>  $body,      # optional
        
         # path parameters
        
        'id'                       =>  $id,        # required
        
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

L<OpenSearch documentation for search_pipeline-E<gt>put|https://opensearch.org/docs/latest/search-plugins/search-pipelines/creating-search-pipeline/>

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

