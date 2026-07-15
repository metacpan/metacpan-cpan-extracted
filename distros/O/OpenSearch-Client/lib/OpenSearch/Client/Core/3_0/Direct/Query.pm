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

package OpenSearch::Client::Core::3_0::Direct::Query;
$OpenSearch::Client::Core::3_0::Direct::Query::VERSION = '3.007009';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

our %_api_method_supported_version_stash;

sub method_supported_in_version {
    my( $self, @args ) = @_;
    my %params = ( ref($args[0]) ) ? %{ $args[0] } : @args;
    my $version = $params{version};
    my $method  = $params{method};
    return 0 unless($method && $version);
    return 0 unless(exists($_api_method_supported_version_stash{$method}));
    my $supported_version = $_api_method_supported_version_stash{$method};
    my $checkversion = version->declare('v' . $version)->numify;
    return ( $checkversion < $supported_version ) ? 0 : 1;
}

__PACKAGE__->_install_api('query');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::Query>

=head1 VERSION

version 3.007009

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->query-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Metric analytics>


Configure metric analytics datasources

L<See OpenSearch documentation for query.|https://docs.opensearch.org/latest/observing-your-data/prometheusmetrics/>

=head1 METHODS
    
=head2 datasource_delete

Deletes a specific data source by name.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_query/_datasources/{datasource_name}>

=back

I<Method added in OpenSearch version 2.7>


    $resp = $client->query->datasource_delete(
        
         # path parameters
        
        'datasource_name'  =>  $datasource_name,  # required
        
         # Common API query string parameters
        
        'error_trace'      =>  $qval1,     # boolean
        'filter_path'      =>  $qval2,     # list
        'human'            =>  $qval3,     # boolean
        'pretty'           =>  $qval4,     # boolean
        'source'           =>  $qval5,     # string
    );

L<OpenSearch documentation for query-E<gt>datasource_delete|https://docs.opensearch.org/latest/observing-your-data/prometheusmetrics/>
    
=head2 datasource_retrieve

Retrieves a specific data source by name.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_query/_datasources/{datasource_name}>

=back

I<Method added in OpenSearch version 2.7>


    $resp = $client->query->datasource_retrieve(
        
         # path parameters
        
        'datasource_name'  =>  $datasource_name,  # required
        
         # Common API query string parameters
        
        'error_trace'      =>  $qval1,     # boolean
        'filter_path'      =>  $qval2,     # list
        'human'            =>  $qval3,     # boolean
        'pretty'           =>  $qval4,     # boolean
        'source'           =>  $qval5,     # string
    );

L<OpenSearch documentation for query-E<gt>datasource_retrieve|https://docs.opensearch.org/latest/observing-your-data/prometheusmetrics/>
    
=head2 datasources_create

Creates a new query data source.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_query/_datasources>

=back

I<Method added in OpenSearch version 2.7>


    $resp = $client->query->datasources_create(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for query-E<gt>datasources_create|https://docs.opensearch.org/latest/observing-your-data/prometheusmetrics/>
    
=head2 datasources_list

Retrieves a list of all available data sources.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_query/_datasources>

=back

I<Method added in OpenSearch version 2.7>


    $resp = $client->query->datasources_list(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for query-E<gt>datasources_list|https://docs.opensearch.org/latest/observing-your-data/prometheusmetrics/>
    
=head2 datasources_update

Updates an existing query data source.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_query/_datasources>

=back

I<Method added in OpenSearch version 2.7>


    $resp = $client->query->datasources_update(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for query-E<gt>datasources_update|https://docs.opensearch.org/latest/observing-your-data/prometheusmetrics/>

=head2 method_supported_in_version

Return whether a method in this module namespace is supported for an OpenSearch server version

    my $boolean = $os->query->method_supported_in_version(
        method  => 'datasource_delete',
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

