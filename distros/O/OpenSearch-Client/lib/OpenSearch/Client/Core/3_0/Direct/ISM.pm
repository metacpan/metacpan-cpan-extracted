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

package OpenSearch::Client::Core::3_0::Direct::ISM;
$OpenSearch::Client::Core::3_0::Direct::ISM::VERSION = '3.007007';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('ism');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::ISM>

=head1 VERSION

version 3.007007

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->ism-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Index State Management>


Use the index state management operations to programmatically work with policies and managed indexes.

L<See OpenSearch documentation for ism.|https://docs.opensearch.org/latest/im-plugin/ism/index/>

=head1 METHODS
    
=head2 add_policy

Adds a policy to an index.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ism/add>

=item
C<POST /_plugins/_ism/add/{index}>

=back

    $resp = $client->ism->add_policy(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'index'        =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'index'        =>  $qval1,     # string
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval2,     # boolean
        'filter_path'  =>  $qval3,     # list
        'human'        =>  $qval4,     # boolean
        'pretty'       =>  $qval5,     # boolean
        'source'       =>  $qval6,     # string
    );

L<OpenSearch documentation for ism-E<gt>add_policy|https://opensearch.org/docs/latest/im-plugin/ism/api/#add-policy>
    
=head2 change_policy

Updates the managed index policy to a new policy.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ism/change_policy>

=item
C<POST /_plugins/_ism/change_policy/{index}>

=back

    $resp = $client->ism->change_policy(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'index'        =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'index'        =>  $qval1,     # string
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval2,     # boolean
        'filter_path'  =>  $qval3,     # list
        'human'        =>  $qval4,     # boolean
        'pretty'       =>  $qval5,     # boolean
        'source'       =>  $qval6,     # string
    );

L<OpenSearch documentation for ism-E<gt>change_policy|https://opensearch.org/docs/latest/im-plugin/ism/api/#update-managed-index-policy>
    
=head2 delete_policy

Deletes a policy.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_ism/policies/{policy_id}>

=back

    $resp = $client->ism->delete_policy(
        
         # path parameters
        
        'policy_id'    =>  $policy_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ism-E<gt>delete_policy|https://opensearch.org/docs/latest/im-plugin/ism/api/#delete-policy>
    
=head2 exists_policy

Checks for the existence of a policy.

I<Paths served by this method:>

=over

=item
C<HEAD /_plugins/_ism/policies/{policy_id}>

=back

    $resp = $client->ism->exists_policy(
        
         # path parameters
        
        'policy_id'    =>  $policy_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ism-E<gt>exists_policy|https://opensearch.org/docs/latest/im-plugin/ism/api/#get-policy>
    
=head2 explain_policy

Retrieves the currently applied policy on the specified indexes.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ism/explain>

=item
C<GET /_plugins/_ism/explain/{index}>

=item
C<POST /_plugins/_ism/explain>

=item
C<POST /_plugins/_ism/explain/{index}>

=back

    $resp = $client->ism->explain_policy(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'index'        =>  $index,     # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ism-E<gt>explain_policy|https://opensearch.org/docs/latest/im-plugin/ism/api/#explain-index>
    
=head2 get_policies

Retrieves the policies.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ism/policies>

=back

    $resp = $client->ism->get_policies(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ism-E<gt>get_policies|https://opensearch.org/docs/latest/im-plugin/ism/api/#get-policy>
    
=head2 get_policy

Retrieves a specific policy.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ism/policies/{policy_id}>

=back

    $resp = $client->ism->get_policy(
        
         # path parameters
        
        'policy_id'    =>  $policy_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ism-E<gt>get_policy|https://opensearch.org/docs/latest/im-plugin/ism/api/#put-policy>
    
=head2 put_policies

Creates or updates policies.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_ism/policies>

=back

    $resp = $client->ism->put_policies(
        
        'body'             =>  $body,      # optional
        
         # Endpoint specific query string parameters
        
        'if_primary_term'  =>  $qval1,     # number
        'if_seq_no'        =>  $qval2,     # number
        'policyID'         =>  $qval3,     # string
        
         # Common API query string parameters
        
        'error_trace'      =>  $qval4,     # boolean
        'filter_path'      =>  $qval5,     # list
        'human'            =>  $qval6,     # boolean
        'pretty'           =>  $qval7,     # boolean
        'source'           =>  $qval8,     # string
    );

L<OpenSearch documentation for ism-E<gt>put_policies|https://opensearch.org/docs/latest/im-plugin/ism/api/#create-policy>
    
=head2 put_policy

Creates or updates a policy.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_ism/policies/{policy_id}>

=back

    $resp = $client->ism->put_policy(
        
        'body'             =>  $body,      # optional
        
         # path parameters
        
        'policy_id'        =>  $policy_id,  # required
        
         # Endpoint specific query string parameters
        
        'if_primary_term'  =>  $qval1,     # number
        'if_seq_no'        =>  $qval2,     # number
        
         # Common API query string parameters
        
        'error_trace'      =>  $qval3,     # boolean
        'filter_path'      =>  $qval4,     # list
        'human'            =>  $qval5,     # boolean
        'pretty'           =>  $qval6,     # boolean
        'source'           =>  $qval7,     # string
    );

L<OpenSearch documentation for ism-E<gt>put_policy|https://opensearch.org/docs/latest/im-plugin/ism/api/#create-policy>
    
=head2 refresh_search_analyzers

Refreshes search analyzers in real time.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_refresh_search_analyzers/{index}>

=back

    $resp = $client->ism->refresh_search_analyzers(
        
         # path parameters
        
        'index'        =>  $index,     # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ism-E<gt>refresh_search_analyzers|https://opensearch.org/docs/latest/im-plugin/refresh-analyzer/>
    
=head2 remove_policy

Removes a policy from an index.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ism/remove>

=item
C<POST /_plugins/_ism/remove/{index}>

=back

    $resp = $client->ism->remove_policy(
        
         # path parameters
        
        'index'        =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'index'        =>  $qval1,     # string
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval2,     # boolean
        'filter_path'  =>  $qval3,     # list
        'human'        =>  $qval4,     # boolean
        'pretty'       =>  $qval5,     # boolean
        'source'       =>  $qval6,     # string
    );

L<OpenSearch documentation for ism-E<gt>remove_policy|https://opensearch.org/docs/latest/im-plugin/ism/api/#remove-policy>
    
=head2 retry_index

Retries the failed action for an index.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ism/retry>

=item
C<POST /_plugins/_ism/retry/{index}>

=back

    $resp = $client->ism->retry_index(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'index'        =>  $index,     # optional
        
         # Endpoint specific query string parameters
        
        'index'        =>  $qval1,     # string
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval2,     # boolean
        'filter_path'  =>  $qval3,     # list
        'human'        =>  $qval4,     # boolean
        'pretty'       =>  $qval5,     # boolean
        'source'       =>  $qval6,     # string
    );

L<OpenSearch documentation for ism-E<gt>retry_index|https://opensearch.org/docs/latest/im-plugin/ism/api/#retry-failed-index>

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

