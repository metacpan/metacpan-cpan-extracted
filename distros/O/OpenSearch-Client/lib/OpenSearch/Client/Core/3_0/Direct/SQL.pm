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

package OpenSearch::Client::Core::3_0::Direct::SQL;
$OpenSearch::Client::Core::3_0::Direct::SQL::VERSION = '3.007006';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('sql');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::SQL>

=head1 VERSION

version 3.007006

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->sql-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<SQL>


Use the SQL and PPL API to send queries to the SQL plugin. Use the _sql endpoint to send queries in SQL, and the _ppl endpoint to send queries in PPL. For both of these, you can also use the _explain endpoint to translate your query into OpenSearch domain-specific language (DSL) or to troubleshoot errors.

=head1 METHODS
    
=head2 close

Closes an open cursor to free server-side resources.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_sql/close>

=back

    $resp = $client->sql->close(
        
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

L<OpenSearch documentation for sql-E<gt>close|https://opensearch.org/docs/latest/search-plugins/sql/sql-ppl-api/>
    
=head2 explain

Returns the execution plan for a SQL or PPL query.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_sql/_explain>

=back

    $resp = $client->sql->explain(
        
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

L<OpenSearch documentation for sql-E<gt>explain|https://opensearch.org/docs/latest/search-plugins/sql/sql-ppl-api/>
    
=head2 get_stats

Retrieves performance metrics for the SQL plugin.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_sql/stats>

=back

    $resp = $client->sql->get_stats(
        
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

L<OpenSearch documentation for sql-E<gt>get_stats|https://opensearch.org/docs/latest/search-plugins/sql/monitoring/>
    
=head2 post_stats

Retrieves filtered performance metrics for the SQL plugin.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_sql/stats>

=back

    $resp = $client->sql->post_stats(
        
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

L<OpenSearch documentation for sql-E<gt>post_stats|https://opensearch.org/docs/latest/search-plugins/sql/monitoring/>
    
=head2 query

Executes SQL or PPL queries against OpenSearch indexes.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_sql>

=back

    $resp = $client->sql->query(
        
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

L<OpenSearch documentation for sql-E<gt>query|https://opensearch.org/docs/latest/search-plugins/sql/sql-ppl-api/>
    
=head2 settings

Updates SQL plugin settings in the OpenSearch cluster configuration.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_query/settings>

=back

    $resp = $client->sql->settings(
        
        'body'         =>  $body,      # optional
        
         # Endpoint specific query string parameters
        
        'format'       =>  $qval1,     # string
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval2,     # boolean
        'filter_path'  =>  $qval3,     # list
        'human'        =>  $qval4,     # boolean
        'pretty'       =>  $qval5,     # boolean
        'source'       =>  $qval6,     # string
    );

L<OpenSearch documentation for sql-E<gt>settings|https://opensearch.org/docs/latest/search-plugins/sql/settings/>

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

