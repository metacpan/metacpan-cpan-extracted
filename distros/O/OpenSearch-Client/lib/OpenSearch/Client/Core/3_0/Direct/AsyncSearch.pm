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

package OpenSearch::Client::Core::3_0::Direct::AsyncSearch;
$OpenSearch::Client::Core::3_0::Direct::AsyncSearch::VERSION = '3.007009';
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

__PACKAGE__->_install_api('asynchronous_search');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::AsyncSearch>

=head1 VERSION

version 3.007009

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->asynchronous_search-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Asynchronous Search>


Searching large volumes of data can take a long time, especially if you're searching across warm nodes or multiple remote clusters. Asynchronous search in OpenSearch lets you send search requests that run in the background. You can monitor the progress of these searches and get back partial results as they become available. After the search finishes, you can save the results to examine at a later time.'

L<See OpenSearch documentation for asynchronous_search.|https://docs.opensearch.org/latest/search-plugins/async/index/>

=head1 METHODS
    
=head2 delete

Deletes any responses from an asynchronous search.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_asynchronous_search/{id}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->asynchronous_search->delete(
        
         # path parameters
        
        'id'           =>  $id,        # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for asynchronous_search-E<gt>delete|https://opensearch.org/docs/latest/search-plugins/async/index/#delete-searches-and-results>
    
=head2 get

Gets partial responses from an asynchronous search.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_asynchronous_search/{id}>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->asynchronous_search->get(
        
         # path parameters
        
        'id'           =>  $id,        # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for asynchronous_search-E<gt>get|https://opensearch.org/docs/latest/search-plugins/async/index/#get-partial-results>
    
=head2 search

Performs an asynchronous search.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_asynchronous_search>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->asynchronous_search->search(
        
        'body'                         =>  $body,      # optional
        
         # Endpoint specific query string parameters
        
        'index'                        =>  $qval1,     # string
        'keep_alive'                   =>  $qval2,     # string
        'keep_on_completion'           =>  $qval3,     # boolean
        'wait_for_completion_timeout'  =>  $qval4,     # string
        
         # Common API query string parameters
        
        'error_trace'                  =>  $qval5,     # boolean
        'filter_path'                  =>  $qval6,     # list
        'human'                        =>  $qval7,     # boolean
        'pretty'                       =>  $qval8,     # boolean
        'source'                       =>  $qval9,     # string
    );

L<OpenSearch documentation for asynchronous_search-E<gt>search|https://opensearch.org/docs/latest/search-plugins/async/index/#rest-api>
    
=head2 stats

Monitors any asynchronous searches that are `running`, `completed`, or `persisted`.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_asynchronous_search/stats>

=back

I<Method added in OpenSearch version 1.0>


    $resp = $client->asynchronous_search->stats(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for asynchronous_search-E<gt>stats|https://opensearch.org/docs/latest/search-plugins/async/index/#monitor-stats>

=head2 method_supported_in_version

Return whether a method in this module namespace is supported for an OpenSearch server version

    my $boolean = $os->asynchronous_search->method_supported_in_version(
        method  => 'delete',
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

