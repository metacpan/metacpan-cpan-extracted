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

package OpenSearch::Client::Core::3_0::Direct::SearchRelevance;
$OpenSearch::Client::Core::3_0::Direct::SearchRelevance::VERSION = '3.007007';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('search_relevance');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::SearchRelevance>

=head1 VERSION

version 3.007007

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->search_relevance-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Search Relevance Workbench>


In search applications, tuning relevance is a constant, iterative exercise intended to provide the right search results to your end users. The tooling in Search Relevance Workbench helps search relevance engineers and business users create the best search experience possible for application users. It does this without hiding internal information, enabling engineers to experiment and investigate details as necessary.

L<See OpenSearch documentation for search_relevance.|https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/>

=head1 METHODS
    
=head2 delete_experiments

Deletes a specified experiment.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_search_relevance/experiments/{experiment_id}>

=back

    $resp = $client->search_relevance->delete_experiments(
        
         # path parameters
        
        'experiment_id'  =>  $experiment_id,  # required
        
         # Common API query string parameters
        
        'error_trace'    =>  $qval1,     # boolean
        'filter_path'    =>  $qval2,     # list
        'human'          =>  $qval3,     # boolean
        'pretty'         =>  $qval4,     # boolean
        'source'         =>  $qval5,     # string
    );

L<OpenSearch documentation for search_relevance-E<gt>delete_experiments|https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/>
    
=head2 delete_judgments

Deletes a specified judgment.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_search_relevance/judgments/{judgment_id}>

=back

    $resp = $client->search_relevance->delete_judgments(
        
         # path parameters
        
        'judgment_id'  =>  $judgment_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for search_relevance-E<gt>delete_judgments|https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/>
    
=head2 delete_query_sets

Deletes a query set.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_search_relevance/query_sets/{query_set_id}>

=back

    $resp = $client->search_relevance->delete_query_sets(
        
         # path parameters
        
        'query_set_id'  =>  $query_set_id,  # required
        
         # Common API query string parameters
        
        'error_trace'   =>  $qval1,     # boolean
        'filter_path'   =>  $qval2,     # list
        'human'         =>  $qval3,     # boolean
        'pretty'        =>  $qval4,     # boolean
        'source'        =>  $qval5,     # string
    );

L<OpenSearch documentation for search_relevance-E<gt>delete_query_sets|https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/>
    
=head2 delete_scheduled_experiments

Deletes a specified scheduled experiment.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_search_relevance/experiments/schedule/{experiment_id}>

=back

    $resp = $client->search_relevance->delete_scheduled_experiments(
        
         # path parameters
        
        'experiment_id'  =>  $experiment_id,  # required
        
         # Common API query string parameters
        
        'error_trace'    =>  $qval1,     # boolean
        'filter_path'    =>  $qval2,     # list
        'human'          =>  $qval3,     # boolean
        'pretty'         =>  $qval4,     # boolean
        'source'         =>  $qval5,     # string
    );

L<OpenSearch documentation for search_relevance-E<gt>delete_scheduled_experiments|https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/>
    
=head2 delete_search_configurations

Deletes a specified search configuration.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_search_relevance/search_configurations/{search_configuration_id}>

=back

    $resp = $client->search_relevance->delete_search_configurations(
        
         # path parameters
        
        'search_configuration_id'  =>  $search_configuration_id,  # required
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval1,     # boolean
        'filter_path'              =>  $qval2,     # list
        'human'                    =>  $qval3,     # boolean
        'pretty'                   =>  $qval4,     # boolean
        'source'                   =>  $qval5,     # string
    );

L<OpenSearch documentation for search_relevance-E<gt>delete_search_configurations|https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/>
    
=head2 get_experiments

Gets experiments.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_search_relevance/experiments>

=item
C<GET /_plugins/_search_relevance/experiments/{experiment_id}>

=back

    $resp = $client->search_relevance->get_experiments(
        
         # path parameters
        
        'experiment_id'  =>  $experiment_id,  # optional
        
         # Common API query string parameters
        
        'error_trace'    =>  $qval1,     # boolean
        'filter_path'    =>  $qval2,     # list
        'human'          =>  $qval3,     # boolean
        'pretty'         =>  $qval4,     # boolean
        'source'         =>  $qval5,     # string
    );

L<OpenSearch documentation for search_relevance-E<gt>get_experiments|https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/>
    
=head2 get_judgments

Gets judgments.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_search_relevance/judgments>

=item
C<GET /_plugins/_search_relevance/judgments/{judgment_id}>

=back

    $resp = $client->search_relevance->get_judgments(
        
         # path parameters
        
        'judgment_id'  =>  $judgment_id,  # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for search_relevance-E<gt>get_judgments|https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/>
    
=head2 get_node_stats

Gets stats by node.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_search_relevance/{node_id}/stats>

=item
C<GET /_plugins/_search_relevance/{node_id}/stats/{stat}>

=back

    $resp = $client->search_relevance->get_node_stats(
        
         # path parameters
        
        'node_id'                   =>  $node_id,   # required
        'stat'                      =>  $stat,      # optional
        
         # Endpoint specific query string parameters
        
        'flat_stat_paths'           =>  $qval1,     # string
        'include_all_nodes'         =>  $qval2,     # string
        'include_individual_nodes'  =>  $qval3,     # string
        'include_info'              =>  $qval4,     # string
        'include_metadata'          =>  $qval5,     # string
        
         # Common API query string parameters
        
        'error_trace'               =>  $qval6,     # boolean
        'filter_path'               =>  $qval7,     # list
        'human'                     =>  $qval8,     # boolean
        'pretty'                    =>  $qval9,     # boolean
        'source'                    =>  $qval10,    # string
    );

L<OpenSearch documentation for search_relevance-E<gt>get_node_stats|https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/>
    
=head2 get_query_sets

Lists the current query sets available.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_search_relevance/query_sets>

=item
C<GET /_plugins/_search_relevance/query_sets/{query_set_id}>

=back

    $resp = $client->search_relevance->get_query_sets(
        
         # path parameters
        
        'query_set_id'  =>  $query_set_id,  # optional
        
         # Common API query string parameters
        
        'error_trace'   =>  $qval1,     # boolean
        'filter_path'   =>  $qval2,     # list
        'human'         =>  $qval3,     # boolean
        'pretty'        =>  $qval4,     # boolean
        'source'        =>  $qval5,     # string
    );

L<OpenSearch documentation for search_relevance-E<gt>get_query_sets|https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/>
    
=head2 get_scheduled_experiments

Gets the scheduled experiments.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_search_relevance/experiments/schedule>

=item
C<GET /_plugins/_search_relevance/experiments/schedule/{experiment_id}>

=back

    $resp = $client->search_relevance->get_scheduled_experiments(
        
         # path parameters
        
        'experiment_id'  =>  $experiment_id,  # optional
        
         # Common API query string parameters
        
        'error_trace'    =>  $qval1,     # boolean
        'filter_path'    =>  $qval2,     # list
        'human'          =>  $qval3,     # boolean
        'pretty'         =>  $qval4,     # boolean
        'source'         =>  $qval5,     # string
    );

L<OpenSearch documentation for search_relevance-E<gt>get_scheduled_experiments|https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/>
    
=head2 get_search_configurations

Gets the search configurations.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_search_relevance/search_configurations>

=item
C<GET /_plugins/_search_relevance/search_configurations/{search_configuration_id}>

=back

    $resp = $client->search_relevance->get_search_configurations(
        
         # path parameters
        
        'search_configuration_id'  =>  $search_configuration_id,  # optional
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval1,     # boolean
        'filter_path'              =>  $qval2,     # list
        'human'                    =>  $qval3,     # boolean
        'pretty'                   =>  $qval4,     # boolean
        'source'                   =>  $qval5,     # string
    );

L<OpenSearch documentation for search_relevance-E<gt>get_search_configurations|https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/>
    
=head2 get_stats

Gets stats.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_search_relevance/stats>

=item
C<GET /_plugins/_search_relevance/stats/{stat}>

=back

    $resp = $client->search_relevance->get_stats(
        
         # path parameters
        
        'stat'                      =>  $stat,      # optional
        
         # Endpoint specific query string parameters
        
        'flat_stat_paths'           =>  $qval1,     # string
        'include_all_nodes'         =>  $qval2,     # string
        'include_individual_nodes'  =>  $qval3,     # string
        'include_info'              =>  $qval4,     # string
        'include_metadata'          =>  $qval5,     # string
        
         # Common API query string parameters
        
        'error_trace'               =>  $qval6,     # boolean
        'filter_path'               =>  $qval7,     # list
        'human'                     =>  $qval8,     # boolean
        'pretty'                    =>  $qval9,     # boolean
        'source'                    =>  $qval10,    # string
    );

L<OpenSearch documentation for search_relevance-E<gt>get_stats|https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/>
    
=head2 post_query_sets

Creates a new query set by sampling queries from the user behavior data.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_search_relevance/query_sets>

=back

    $resp = $client->search_relevance->post_query_sets(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for search_relevance-E<gt>post_query_sets|https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/>
    
=head2 post_scheduled_experiments

Creates a scheduled experiment.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_search_relevance/experiments/schedule>

=back

    $resp = $client->search_relevance->post_scheduled_experiments(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for search_relevance-E<gt>post_scheduled_experiments|https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/>
    
=head2 put_experiments

Creates an experiment.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_search_relevance/experiments>

=back

    $resp = $client->search_relevance->put_experiments(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for search_relevance-E<gt>put_experiments|https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/>
    
=head2 put_judgments

Creates a judgment.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_search_relevance/judgments>

=back

    $resp = $client->search_relevance->put_judgments(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for search_relevance-E<gt>put_judgments|https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/>
    
=head2 put_query_sets

Creates a new query set by uploading manually.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_search_relevance/query_sets>

=back

    $resp = $client->search_relevance->put_query_sets(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for search_relevance-E<gt>put_query_sets|https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/>
    
=head2 put_search_configurations

Creates a search configuration.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_search_relevance/search_configurations>

=back

    $resp = $client->search_relevance->put_search_configurations(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for search_relevance-E<gt>put_search_configurations|https://docs.opensearch.org/latest/search-plugins/search-relevance/using-search-relevance-workbench/>

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

