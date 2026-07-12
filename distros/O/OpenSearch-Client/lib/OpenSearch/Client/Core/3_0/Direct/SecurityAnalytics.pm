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

package OpenSearch::Client::Core::3_0::Direct::SecurityAnalytics;
$OpenSearch::Client::Core::3_0::Direct::SecurityAnalytics::VERSION = '3.007007';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('security_analytics');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::SecurityAnalytics>

=head1 VERSION

version 3.007007

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->security_analytics-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Security Analytics>


Security Analytics includes a number of APIs to help administrators maintain and update an implementation. The APIs often mimic the same controls available for setting up Security Analytics in OpenSearch Dashboards, and they provide another option for administering the plugin.

L<See OpenSearch documentation for security_analytics.|https://docs.opensearch.org/latest/security-analytics/api-tools/index/>

=head1 METHODS
    
=head2 get_alerts

Retrieve alerts related to a specific detector type or detector ID.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security_analytics/alerts>

=back

    $resp = $client->security_analytics->get_alerts(
        
         # Endpoint specific query string parameters
        
        'alertState'     =>  $qval1,     # string
        'detectorType'   =>  $qval2,     # string
        'detector_id'    =>  $qval3,     # string
        'endTime'        =>  $qval4,     # number
        'missing'        =>  $qval5,     # string
        'searchString'   =>  $qval6,     # string
        'severityLevel'  =>  $qval7,     # string
        'size'           =>  $qval8,     # number
        'sortOrder'      =>  $qval9,     # string
        'sortString'     =>  $qval10,    # string
        'startIndex'     =>  $qval11,    # number
        'startTime'      =>  $qval12,    # number
        
         # Common API query string parameters
        
        'error_trace'    =>  $qval13,    # boolean
        'filter_path'    =>  $qval14,    # list
        'human'          =>  $qval15,    # boolean
        'pretty'         =>  $qval16,    # boolean
        'source'         =>  $qval17,    # string
    );

L<OpenSearch documentation for security_analytics-E<gt>get_alerts|https://docs.opensearch.org/docs/latest/security-analytics/api-tools/alert-finding-api/#get-alerts>
    
=head2 get_findings

Retrieve findings related to a specific detector type or detector ID.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security_analytics/findings/_search>

=back

    $resp = $client->security_analytics->get_findings(
        
         # Endpoint specific query string parameters
        
        'detectionType'  =>  $qval1,     # string
        'detectorType'   =>  $qval2,     # string
        'detector_id'    =>  $qval3,     # string
        'endTime'        =>  $qval4,     # string
        'findingIds'     =>  $qval5,     # string
        'missing'        =>  $qval6,     # string
        'searchString'   =>  $qval7,     # string
        'severity'       =>  $qval8,     # string
        'size'           =>  $qval9,     # number
        'sortOrder'      =>  $qval10,    # string
        'sortString'     =>  $qval11,    # string
        'startIndex'     =>  $qval12,    # number
        'startTime'      =>  $qval13,    # number
        
         # Common API query string parameters
        
        'error_trace'    =>  $qval14,    # boolean
        'filter_path'    =>  $qval15,    # list
        'human'          =>  $qval16,    # boolean
        'pretty'         =>  $qval17,    # boolean
        'source'         =>  $qval18,    # string
    );

L<OpenSearch documentation for security_analytics-E<gt>get_findings|https://docs.opensearch.org/docs/latest/security-analytics/api-tools/alert-finding-api/#get-findings>
    
=head2 search_finding_correlations

List correlations for a finding.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security_analytics/findings/correlate>

=back

    $resp = $client->security_analytics->search_finding_correlations(
        
         # Endpoint specific query string parameters
        
        'detector_type'    =>  $qval1,     # string
        'finding'          =>  $qval2,     # string
        'nearby_findings'  =>  $qval3,     # number
        'time_window'      =>  $qval4,     # number
        
         # Common API query string parameters
        
        'error_trace'      =>  $qval5,     # boolean
        'filter_path'      =>  $qval6,     # list
        'human'            =>  $qval7,     # boolean
        'pretty'           =>  $qval8,     # boolean
        'source'           =>  $qval9,     # string
    );

L<OpenSearch documentation for security_analytics-E<gt>search_finding_correlations|https://docs.opensearch.org/docs/latest/security-analytics/api-tools/correlation-eng/#list-correlations-for-a-finding-belonging-to-a-log-type>

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

