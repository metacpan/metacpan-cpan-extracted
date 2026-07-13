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

package OpenSearch::Client::Core::3_0::Direct::PPL;
$OpenSearch::Client::Core::3_0::Direct::PPL::VERSION = '3.007008';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('ppl');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::PPL>

=head1 VERSION

version 3.007008

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->ppl-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Piped Processing Language (PPL)>


Use the SQL and PPL API to send queries to the SQL plugin. Use the _sql endpoint to send queries in SQL, and the _ppl endpoint to send queries in PPL. For both of these, you can also use the _explain endpoint to translate your query into OpenSearch domain-specific language (DSL) or to troubleshoot errors.

L<See OpenSearch documentation for ppl.|https://docs.opensearch.org/latest/sql-and-ppl/>

=head1 METHODS
    
=head2 explain

Returns the execution plan for a PPL query.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ppl/_explain>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->ppl->explain(
        
        'body'         =>  $body,      # optional
        
         # Endpoint specific query string parameters
        
        'format'       =>  $qval1,     # string
        'sanitize'     =>  $qval2,     # boolean
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval3,     # boolean
        'filter_path'  =>  $qval4,     # list
        'human'        =>  $qval5,     # boolean
        'pretty'       =>  $qval6,     # boolean
        'source'       =>  $qval7,     # string
    );

L<OpenSearch documentation for ppl-E<gt>explain|https://opensearch.org/docs/latest/search-plugins/sql/sql-ppl-api/>
    
=head2 get_stats

Retrieves performance metrics for the PPL plugin.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ppl/stats>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->ppl->get_stats(
        
         # Endpoint specific query string parameters
        
        'format'       =>  $qval1,     # string
        'sanitize'     =>  $qval2,     # boolean
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval3,     # boolean
        'filter_path'  =>  $qval4,     # list
        'human'        =>  $qval5,     # boolean
        'pretty'       =>  $qval6,     # boolean
        'source'       =>  $qval7,     # string
    );

L<OpenSearch documentation for ppl-E<gt>get_stats|https://opensearch.org/docs/latest/search-plugins/sql/monitoring/>
    
=head2 post_stats

Retrieves filtered performance metrics for the PPL plugin.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ppl/stats>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->ppl->post_stats(
        
        'body'         =>  $body,      # optional
        
         # Endpoint specific query string parameters
        
        'format'       =>  $qval1,     # string
        'sanitize'     =>  $qval2,     # boolean
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval3,     # boolean
        'filter_path'  =>  $qval4,     # list
        'human'        =>  $qval5,     # boolean
        'pretty'       =>  $qval6,     # boolean
        'source'       =>  $qval7,     # string
    );

L<OpenSearch documentation for ppl-E<gt>post_stats|https://opensearch.org/docs/latest/search-plugins/sql/monitoring/>
    
=head2 query

Executes a PPL query against OpenSearch indexes.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ppl>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->ppl->query(
        
        'body'         =>  $body,      # optional
        
         # Endpoint specific query string parameters
        
        'format'       =>  $qval1,     # string
        'sanitize'     =>  $qval2,     # boolean
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval3,     # boolean
        'filter_path'  =>  $qval4,     # list
        'human'        =>  $qval5,     # boolean
        'pretty'       =>  $qval6,     # boolean
        'source'       =>  $qval7,     # string
    );

L<OpenSearch documentation for ppl-E<gt>query|https://opensearch.org/docs/latest/search-plugins/sql/sql-ppl-api/>

=head2 method_supported_in_version

Return whether a method in this module namespace is supported for an OpenSearch server version

    my $boolean = $os->ppl->method_supported_in_version(
        method  => 'explain',
        version => '2.4.0'
    );

Both C<method> and C<version> are required.

See also L<global_method_supported_in_version|OpenSearch::Client::Core::3_0::Direct#global_method_supported_in_version>

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

