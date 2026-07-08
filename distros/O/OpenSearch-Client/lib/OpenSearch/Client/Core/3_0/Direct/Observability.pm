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

package OpenSearch::Client::Core::3_0::Direct::Observability;
$OpenSearch::Client::Core::3_0::Direct::Observability::VERSION = '3.007006';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('observability');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::Observability>

=head1 VERSION

version 3.007006

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->observability-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Observability>


OpenSearch provides observability capabilities for monitoring applications, infrastructure, and AI agents.

L<See OpenSearch documentation for observability.|https://docs.opensearch.org/latest/observing-your-data/>

=head1 METHODS
    
=head2 create_object

Creates a new observability object.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_observability/object>

=back

    $resp = $client->observability->create_object(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for observability-E<gt>create_object|https://docs.opensearch.org/latest/observing-your-data/>
    
=head2 delete_object

Deletes specific observability object specified by ID.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_observability/object/{object_id}>

=back

    $resp = $client->observability->delete_object(
        
         # path parameters
        
        'object_id'    =>  $object_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for observability-E<gt>delete_object|https://docs.opensearch.org/latest/observing-your-data/>
    
=head2 delete_objects

Deletes specific observability objects specified by ID or a list of IDs.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_observability/object>

=back

    $resp = $client->observability->delete_objects(
        
         # Endpoint specific query string parameters
        
        'objectId'      =>  $qval1,     # string
        'objectIdList'  =>  $qval2,     # string
        
         # Common API query string parameters
        
        'error_trace'   =>  $qval3,     # boolean
        'filter_path'   =>  $qval4,     # list
        'human'         =>  $qval5,     # boolean
        'pretty'        =>  $qval6,     # boolean
        'source'        =>  $qval7,     # string
    );

L<OpenSearch documentation for observability-E<gt>delete_objects|https://docs.opensearch.org/latest/observing-your-data/>
    
=head2 get_localstats

Retrieves local stats of all observability objects.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_observability/_local/stats>

=back

    $resp = $client->observability->get_localstats(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for observability-E<gt>get_localstats|https://docs.opensearch.org/latest/observing-your-data/>
    
=head2 get_object

Retrieves specific observability object specified by ID.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_observability/object/{object_id}>

=back

    $resp = $client->observability->get_object(
        
         # path parameters
        
        'object_id'    =>  $object_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for observability-E<gt>get_object|https://docs.opensearch.org/latest/observing-your-data/>
    
=head2 list_objects

Retrieves list of all observability objects.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_observability/object>

=back

    $resp = $client->observability->list_objects(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for observability-E<gt>list_objects|https://docs.opensearch.org/latest/observing-your-data/>
    
=head2 update_object

Updates an existing observability object.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_observability/object/{object_id}>

=back

    $resp = $client->observability->update_object(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'object_id'    =>  $object_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for observability-E<gt>update_object|https://docs.opensearch.org/latest/observing-your-data/>

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

