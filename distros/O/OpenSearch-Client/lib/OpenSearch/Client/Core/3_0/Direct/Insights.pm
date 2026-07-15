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

package OpenSearch::Client::Core::3_0::Direct::Insights;
$OpenSearch::Client::Core::3_0::Direct::Insights::VERSION = '3.007009';
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

__PACKAGE__->_install_api('insights');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::Insights>

=head1 VERSION

version 3.007009

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->insights-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Query insights>


To monitor and analyze the search queries within your OpenSearch cluster, you can obtain query insights.

L<See OpenSearch documentation for insights.|https://docs.opensearch.org/latest/observing-your-data/query-insights/index/>

=head1 METHODS
    
=head2 top_queries

Retrieves the top queries based on the given metric type (latency, CPU, or memory).

I<Paths served by this method:>

=over

=item
C<GET /_insights/top_queries>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->insights->top_queries(
        
         # Endpoint specific query string parameters
        
        'type'         =>  $qval1,     # string
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval2,     # boolean
        'filter_path'  =>  $qval3,     # list
        'human'        =>  $qval4,     # boolean
        'pretty'       =>  $qval5,     # boolean
        'source'       =>  $qval6,     # string
    );

L<OpenSearch documentation for insights-E<gt>top_queries|https://docs.opensearch.org/latest/observing-your-data/query-insights/index/>

=head2 method_supported_in_version

Return whether a method in this module namespace is supported for an OpenSearch server version

    my $boolean = $os->insights->method_supported_in_version(
        method  => 'top_queries',
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

