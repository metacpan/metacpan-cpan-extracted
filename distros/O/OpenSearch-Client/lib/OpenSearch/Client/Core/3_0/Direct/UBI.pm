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

package OpenSearch::Client::Core::3_0::Direct::UBI;
$OpenSearch::Client::Core::3_0::Direct::UBI::VERSION = '3.007009';
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

__PACKAGE__->_install_api('ubi');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::UBI>

=head1 VERSION

version 3.007009

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->ubi-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Initialize User Behavior Insights Indices>


User Behavior Insights (UBI) is a schema for capturing user search behavior. Search behavior consists of the queries that the user submits, the results that are presented to them, and the actions they take on those results. The UBI schema links all user interactions (events) to the search result they were performed on. That is, it not only captures the chronological sequence of events but also captures the causal links between events. Analysis of this behavior is used for improving the quality of search results.

L<See OpenSearch documentation for ubi.|https://docs.opensearch.org/latest/search-plugins/ubi/index/>

=head1 METHODS
    
=head2 initialize

Initializes the UBI indexes.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/ubi/initialize>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->ubi->initialize(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ubi-E<gt>initialize|https://docs.opensearch.org/latest/search-plugins/ubi/index/>

=head2 method_supported_in_version

Return whether a method in this module namespace is supported for an OpenSearch server version

    my $boolean = $os->ubi->method_supported_in_version(
        method  => 'initialize',
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

