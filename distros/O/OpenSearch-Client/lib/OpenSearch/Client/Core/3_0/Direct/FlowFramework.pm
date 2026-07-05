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

package OpenSearch::Client::Core::3_0::Direct::FlowFramework;
$OpenSearch::Client::Core::3_0::Direct::FlowFramework::VERSION = '3.007005';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('flow_framework');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::FlowFramework>

=head1 VERSION

version 3.007005

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->flow_framework-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Automating configurations>


You can automate complex OpenSearch setup and preprocessing tasks by providing templates for common use cases. For example, automating machine learning (ML) setup tasks streamlines the use of OpenSearch ML offerings.

L<See OpenSearch documentation for flow_framework.|https://docs.opensearch.org/latest/automating-configurations/index/>

=head1 METHODS
    
=head2 flow_framework->create

Creates a new workflow template.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_flow_framework/workflow>

=back

    $resp = $client->flow_framework->create(
        
        'body'           =>  $body,      # optional
        
         # Endpoint specific query string parameters
        
        'provision'      =>  $qval1,     # boolean
        'reprovision'    =>  $qval2,     # boolean
        'update_fields'  =>  $qval3,     # boolean
        'use_case'       =>  $qval4,     # string
        'validation'     =>  $qval5,     # string
        
         # Common API query string parameters
        
        'error_trace'    =>  $qval6,     # boolean
        'filter_path'    =>  $qval7,     # list
        'human'          =>  $qval8,     # boolean
        'pretty'         =>  $qval9,     # boolean
        'source'         =>  $qval10,    # string
    );

L<OpenSearch documentation for flow_framework.create|https://opensearch.org/docs/latest/automating-configurations/api/create-workflow/>
    
=head2 flow_framework->delete

Deletes a workflow template.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_flow_framework/workflow/{workflow_id}>

=back

    $resp = $client->flow_framework->delete(
        
         # path parameters
        
        'workflow_id'   =>  $workflow_id,  # required
        
         # Endpoint specific query string parameters
        
        'clear_status'  =>  $qval1,     # boolean
        
         # Common API query string parameters
        
        'error_trace'   =>  $qval2,     # boolean
        'filter_path'   =>  $qval3,     # list
        'human'         =>  $qval4,     # boolean
        'pretty'        =>  $qval5,     # boolean
        'source'        =>  $qval6,     # string
    );

L<OpenSearch documentation for flow_framework.delete|https://opensearch.org/docs/latest/automating-configurations/api/delete-workflow/>
    
=head2 flow_framework->deprovision

Deprovision workflow's resources when you no longer need them.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_flow_framework/workflow/{workflow_id}/_deprovision>

=back

    $resp = $client->flow_framework->deprovision(
        
         # path parameters
        
        'workflow_id'   =>  $workflow_id,  # required
        
         # Endpoint specific query string parameters
        
        'allow_delete'  =>  $qval1,     # string
        
         # Common API query string parameters
        
        'error_trace'   =>  $qval2,     # boolean
        'filter_path'   =>  $qval3,     # list
        'human'         =>  $qval4,     # boolean
        'pretty'        =>  $qval5,     # boolean
        'source'        =>  $qval6,     # string
    );

L<OpenSearch documentation for flow_framework.deprovision|https://opensearch.org/docs/latest/automating-configurations/api/deprovision-workflow/>
    
=head2 flow_framework->get

Retrieves a workflow template.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_flow_framework/workflow/{workflow_id}>

=back

    $resp = $client->flow_framework->get(
        
         # path parameters
        
        'workflow_id'  =>  $workflow_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for flow_framework.get|https://opensearch.org/docs/latest/automating-configurations/api/get-workflow/>
    
=head2 flow_framework->get_status

Retrieves the current workflow provisioning status.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_flow_framework/workflow/{workflow_id}/_status>

=back

    $resp = $client->flow_framework->get_status(
        
         # path parameters
        
        'workflow_id'  =>  $workflow_id,  # required
        
         # Endpoint specific query string parameters
        
        'all'          =>  $qval1,     # boolean
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval2,     # boolean
        'filter_path'  =>  $qval3,     # list
        'human'        =>  $qval4,     # boolean
        'pretty'       =>  $qval5,     # boolean
        'source'       =>  $qval6,     # string
    );

L<OpenSearch documentation for flow_framework.get_status|https://opensearch.org/docs/latest/automating-configurations/api/get-workflow-status/>
    
=head2 flow_framework->get_steps

Retrieves available workflow steps.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_flow_framework/workflow/_steps>

=back

    $resp = $client->flow_framework->get_steps(
        
         # Endpoint specific query string parameters
        
        'workflow_step'  =>  $qval1,     # string
        
         # Common API query string parameters
        
        'error_trace'    =>  $qval2,     # boolean
        'filter_path'    =>  $qval3,     # list
        'human'          =>  $qval4,     # boolean
        'pretty'         =>  $qval5,     # boolean
        'source'         =>  $qval6,     # string
    );

L<OpenSearch documentation for flow_framework.get_steps|https://opensearch.org/docs/latest/automating-configurations/api/get-workflow-steps/>
    
=head2 flow_framework->provision

Provisioning a workflow. This API is also executed when the Create or Update Workflow API is called with the provision parameter set to true.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_flow_framework/workflow/{workflow_id}/_provision>

=back

    $resp = $client->flow_framework->provision(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'workflow_id'  =>  $workflow_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for flow_framework.provision|https://opensearch.org/docs/latest/automating-configurations/api/provision-workflow/>
    
=head2 flow_framework->search

Search for workflows by using a query matching a field.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_flow_framework/workflow/_search>

=item
C<POST /_plugins/_flow_framework/workflow/_search>

=back

    $resp = $client->flow_framework->search(
        
        'body'         =>  $body,      # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for flow_framework.search|https://opensearch.org/docs/latest/automating-configurations/api/provision-workflow/>
    
=head2 flow_framework->search_state

Search for workflows by using a query matching a field.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_flow_framework/workflow/state/_search>

=item
C<POST /_plugins/_flow_framework/workflow/state/_search>

=back

    $resp = $client->flow_framework->search_state(
        
        'body'         =>  $body,      # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for flow_framework.search_state|https://opensearch.org/docs/latest/automating-configurations/api/search-workflow-state/>
    
=head2 flow_framework->update

Updates a workflow template that has not been provisioned.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_flow_framework/workflow/{workflow_id}>

=back

    $resp = $client->flow_framework->update(
        
        'body'           =>  $body,      # optional
        
         # path parameters
        
        'workflow_id'    =>  $workflow_id,  # required
        
         # Endpoint specific query string parameters
        
        'provision'      =>  $qval1,     # boolean
        'reprovision'    =>  $qval2,     # boolean
        'update_fields'  =>  $qval3,     # boolean
        'use_case'       =>  $qval4,     # string
        'validation'     =>  $qval5,     # string
        
         # Common API query string parameters
        
        'error_trace'    =>  $qval6,     # boolean
        'filter_path'    =>  $qval7,     # list
        'human'          =>  $qval8,     # boolean
        'pretty'         =>  $qval9,     # boolean
        'source'         =>  $qval10,    # string
    );

L<OpenSearch documentation for flow_framework.update|https://opensearch.org/docs/latest/automating-configurations/api/create-workflow/>

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

