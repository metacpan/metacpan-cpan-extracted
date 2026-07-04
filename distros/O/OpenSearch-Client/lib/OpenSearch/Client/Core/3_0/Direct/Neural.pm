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

package OpenSearch::Client::Core::3_0::Direct::Neural;
$OpenSearch::Client::Core::3_0::Direct::Neural::VERSION = '3.007002';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('neural');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::Neural>

=head1 VERSION

version 3.007002

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->neural-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Neural Search API>


The Neural Search plugin provides several APIs for monitoring semantic and hybrid search features.

L<See OpenSearch documentation for neural.|https://docs.opensearch.org/latest/vector-search/api/neural/>

=head1 METHODS
    
=head2 neural->stats

Provides information about the current status of the neural-search plugin.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_neural/stats>

=item
C<GET /_plugins/_neural/stats/{stat}>

=item
C<GET /_plugins/_neural/{node_id}/stats>

=item
C<GET /_plugins/_neural/{node_id}/stats/{stat}>

=back

    $resp = $client->neural->stats(
        
         # path parameters
        
        'node_id'                   =>  $node_id,   # optional
        'stat'                      =>  $stat,      # optional
        
         # Endpoint specific query string parameters
        
        'flat_stat_paths'           =>  $qval1,     # boolean
        'include_all_nodes'         =>  $qval2,     # boolean
        'include_individual_nodes'  =>  $qval3,     # boolean
        'include_info'              =>  $qval4,     # boolean
        'include_metadata'          =>  $qval5,     # boolean
        
         # Common API query string parameters
        
        'error_trace'               =>  $qval6,     # boolean
        'filter_path'               =>  $qval7,     # list
        'human'                     =>  $qval8,     # boolean
        'pretty'                    =>  $qval9,     # boolean
        'source'                    =>  $qval10,    # string
    );

L<OpenSearch documentation for neural.stats|https://docs.opensearch.org/latest/vector-search/api/neural/>

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

