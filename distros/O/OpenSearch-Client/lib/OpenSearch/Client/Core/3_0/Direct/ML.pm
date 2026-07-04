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

package OpenSearch::Client::Core::3_0::Direct::ML;
$OpenSearch::Client::Core::3_0::Direct::ML::VERSION = '3.007002';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('ml');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::ML>

=head1 VERSION

version 3.007002

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->ml-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Machine Learning APIs>


OpenSearch supports ML models that you can use to enhance search relevance through semantic understanding. You can either deploy models directly within your OpenSearch cluster or connect to models hosted on external platforms. These models can transform text into vector embeddings, enabling semantic search capabilities, or provide advanced features like text generation and question answering.

L<See OpenSearch documentation for ml.|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>

=head1 METHODS
    
=head2 ml->add_agentic_memory

Add agentic memory to a memory container.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/memory_containers/{memory_container_id}/memories>

=back

    $resp = $client->ml->add_agentic_memory(
        
        'body'                 =>  $body,      # optional
        
         # path parameters
        
        'memory_container_id'  =>  $memory_container_id,  # required
        
         # Common API query string parameters
        
        'error_trace'          =>  $qval1,     # boolean
        'filter_path'          =>  $qval2,     # list
        'human'                =>  $qval3,     # boolean
        'pretty'               =>  $qval4,     # boolean
        'source'               =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.add_agentic_memory|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->chunk_model

Uploads model chunk.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/models/{model_id}/chunk/{chunk_number}>

=back

    $resp = $client->ml->chunk_model(
        
        'body'          =>  $body,      # optional
        
         # path parameters
        
        'chunk_number'  =>  $chunk_number,  # required
        'model_id'      =>  $model_id,  # required
        
         # Common API query string parameters
        
        'error_trace'   =>  $qval1,     # boolean
        'filter_path'   =>  $qval2,     # list
        'human'         =>  $qval3,     # boolean
        'pretty'        =>  $qval4,     # boolean
        'source'        =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.chunk_model|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->create_connector

Creates a standalone connector.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/connectors/_create>

=back

    $resp = $client->ml->create_connector(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.create_connector|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->create_controller

Creates a controller.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/controllers/{model_id}>

=back

    $resp = $client->ml->create_controller(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'model_id'     =>  $model_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.create_controller|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->create_memory

Create a memory.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/memory>

=back

    $resp = $client->ml->create_memory(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.create_memory|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->create_memory_container

Create a memory container.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/memory_containers/_create>

=back

    $resp = $client->ml->create_memory_container(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.create_memory_container|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->create_memory_container_session

Create session in a memory container.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/memory_containers/{memory_container_id}/memories/sessions>

=back

    $resp = $client->ml->create_memory_container_session(
        
        'body'                 =>  $body,      # optional
        
         # path parameters
        
        'memory_container_id'  =>  $memory_container_id,  # required
        
         # Common API query string parameters
        
        'error_trace'          =>  $qval1,     # boolean
        'filter_path'          =>  $qval2,     # list
        'human'                =>  $qval3,     # boolean
        'pretty'               =>  $qval4,     # boolean
        'source'               =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.create_memory_container_session|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->create_message

Create a message.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/memory/{memory_id}/messages>

=back

    $resp = $client->ml->create_message(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'memory_id'    =>  $memory_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.create_message|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->create_model_meta

Registers model metadata.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/models/meta>

=back

    $resp = $client->ml->create_model_meta(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.create_model_meta|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->delete_agent

Delete an agent.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_ml/agents/{agent_id}>

=back

    $resp = $client->ml->delete_agent(
        
         # path parameters
        
        'agent_id'     =>  $agent_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.delete_agent|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->delete_agentic_memory

Delete a specific memory by its type and ID.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_ml/memory_containers/{memory_container_id}/memories/{type}/{id}>

=back

    $resp = $client->ml->delete_agentic_memory(
        
         # path parameters
        
        'id'                   =>  $id,        # required
        'memory_container_id'  =>  $memory_container_id,  # required
        'type'                 =>  $type,      # required
        
         # Common API query string parameters
        
        'error_trace'          =>  $qval1,     # boolean
        'filter_path'          =>  $qval2,     # list
        'human'                =>  $qval3,     # boolean
        'pretty'               =>  $qval4,     # boolean
        'source'               =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.delete_agentic_memory|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->delete_agentic_memory_query

Delete multiple memories using a query to match specific criteria.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/memory_containers/{memory_container_id}/memories/{type}/_delete_by_query>

=back

    $resp = $client->ml->delete_agentic_memory_query(
        
        'body'                 =>  $body,      # optional
        
         # path parameters
        
        'memory_container_id'  =>  $memory_container_id,  # required
        'type'                 =>  $type,      # required
        
         # Common API query string parameters
        
        'error_trace'          =>  $qval1,     # boolean
        'filter_path'          =>  $qval2,     # list
        'human'                =>  $qval3,     # boolean
        'pretty'               =>  $qval4,     # boolean
        'source'               =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.delete_agentic_memory_query|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->delete_connector

Deletes a standalone connector.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_ml/connectors/{connector_id}>

=back

    $resp = $client->ml->delete_connector(
        
         # path parameters
        
        'connector_id'  =>  $connector_id,  # required
        
         # Common API query string parameters
        
        'error_trace'   =>  $qval1,     # boolean
        'filter_path'   =>  $qval2,     # list
        'human'         =>  $qval3,     # boolean
        'pretty'        =>  $qval4,     # boolean
        'source'        =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.delete_connector|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->delete_controller

Deletes a controller.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_ml/controllers/{model_id}>

=back

    $resp = $client->ml->delete_controller(
        
         # path parameters
        
        'model_id'     =>  $model_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.delete_controller|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->delete_memory

Delete a memory.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_ml/memory/{memory_id}>

=back

    $resp = $client->ml->delete_memory(
        
         # path parameters
        
        'memory_id'    =>  $memory_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.delete_memory|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->delete_memory_container

Delete a memory container.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_ml/memory_containers/{memory_container_id}>

=back

    $resp = $client->ml->delete_memory_container(
        
         # path parameters
        
        'memory_container_id'  =>  $memory_container_id,  # required
        
         # Endpoint specific query string parameters
        
        'delete_all_memories'  =>  $qval1,     # boolean
        'delete_memories'      =>  $qval2,     # list
        
         # Common API query string parameters
        
        'error_trace'          =>  $qval3,     # boolean
        'filter_path'          =>  $qval4,     # list
        'human'                =>  $qval5,     # boolean
        'pretty'               =>  $qval6,     # boolean
        'source'               =>  $qval7,     # string
    );

L<OpenSearch documentation for ml.delete_memory_container|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->delete_model

Deletes a model.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_ml/models/{model_id}>

=back

    $resp = $client->ml->delete_model(
        
         # path parameters
        
        'model_id'     =>  $model_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.delete_model|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->delete_model_group

Deletes a model group.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_ml/model_groups/{model_group_id}>

=back

    $resp = $client->ml->delete_model_group(
        
         # path parameters
        
        'model_group_id'  =>  $model_group_id,  # required
        
         # Common API query string parameters
        
        'error_trace'     =>  $qval1,     # boolean
        'filter_path'     =>  $qval2,     # list
        'human'           =>  $qval3,     # boolean
        'pretty'          =>  $qval4,     # boolean
        'source'          =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.delete_model_group|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->delete_task

Deletes a task.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_ml/tasks/{task_id}>

=back

    $resp = $client->ml->delete_task(
        
         # path parameters
        
        'task_id'      =>  $task_id,   # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.delete_task|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->deploy_model

Deploys a model.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/models/{model_id}/_deploy>

=back

    $resp = $client->ml->deploy_model(
        
         # path parameters
        
        'model_id'     =>  $model_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.deploy_model|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->execute_agent

Execute an agent.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/agents/{agent_id}/_execute>

=back

    $resp = $client->ml->execute_agent(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'agent_id'     =>  $agent_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.execute_agent|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->execute_agent_stream

Execute an agent in streaming mode.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/agents/{agent_id}/_execute/stream>

=back

    $resp = $client->ml->execute_agent_stream(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'agent_id'     =>  $agent_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.execute_agent_stream|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->execute_algorithm

Execute an algorithm.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/_execute/{algorithm_name}>

=back

    $resp = $client->ml->execute_algorithm(
        
        'body'            =>  $body,      # optional
        
         # path parameters
        
        'algorithm_name'  =>  $algorithm_name,  # required
        
         # Common API query string parameters
        
        'error_trace'     =>  $qval1,     # boolean
        'filter_path'     =>  $qval2,     # list
        'human'           =>  $qval3,     # boolean
        'pretty'          =>  $qval4,     # boolean
        'source'          =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.execute_algorithm|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->execute_tool

Execute a tool.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/tools/_execute/{tool_name}>

=back

    $resp = $client->ml->execute_tool(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'tool_name'    =>  $tool_name,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.execute_tool|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->get_agent

Get an agent.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/agents/{agent_id}>

=back

    $resp = $client->ml->get_agent(
        
         # path parameters
        
        'agent_id'     =>  $agent_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.get_agent|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->get_agentic_memory

Get a specific memory by its type and ID.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/memory_containers/{memory_container_id}/memories/{type}/{id}>

=back

    $resp = $client->ml->get_agentic_memory(
        
         # path parameters
        
        'id'                   =>  $id,        # required
        'memory_container_id'  =>  $memory_container_id,  # required
        'type'                 =>  $type,      # required
        
         # Common API query string parameters
        
        'error_trace'          =>  $qval1,     # boolean
        'filter_path'          =>  $qval2,     # list
        'human'                =>  $qval3,     # boolean
        'pretty'               =>  $qval4,     # boolean
        'source'               =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.get_agentic_memory|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->get_all_memories

Get all memories.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/memory>

=back

    $resp = $client->ml->get_all_memories(
        
         # Endpoint specific query string parameters
        
        'max_results'  =>  $qval1,     # number
        'next_token'   =>  $qval2,     # number
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval3,     # boolean
        'filter_path'  =>  $qval4,     # list
        'human'        =>  $qval5,     # boolean
        'pretty'       =>  $qval6,     # boolean
        'source'       =>  $qval7,     # string
    );

L<OpenSearch documentation for ml.get_all_memories|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->get_all_messages

Get all messages in a memory.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/memory/{memory_id}/messages>

=back

    $resp = $client->ml->get_all_messages(
        
         # path parameters
        
        'memory_id'    =>  $memory_id,  # required
        
         # Endpoint specific query string parameters
        
        'max_results'  =>  $qval1,     # number
        'next_token'   =>  $qval2,     # number
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval3,     # boolean
        'filter_path'  =>  $qval4,     # list
        'human'        =>  $qval5,     # boolean
        'pretty'       =>  $qval6,     # boolean
        'source'       =>  $qval7,     # string
    );

L<OpenSearch documentation for ml.get_all_messages|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->get_all_tools

Get tools.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/tools>

=back

    $resp = $client->ml->get_all_tools(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.get_all_tools|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->get_connector

Retrieves a standalone connector.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/connectors/{connector_id}>

=back

    $resp = $client->ml->get_connector(
        
         # path parameters
        
        'connector_id'  =>  $connector_id,  # required
        
         # Common API query string parameters
        
        'error_trace'   =>  $qval1,     # boolean
        'filter_path'   =>  $qval2,     # list
        'human'         =>  $qval3,     # boolean
        'pretty'        =>  $qval4,     # boolean
        'source'        =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.get_connector|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->get_controller

Retrieves a controller.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/controllers/{model_id}>

=back

    $resp = $client->ml->get_controller(
        
         # path parameters
        
        'model_id'     =>  $model_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.get_controller|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->get_memory

Get a memory.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/memory/{memory_id}>

=back

    $resp = $client->ml->get_memory(
        
         # path parameters
        
        'memory_id'    =>  $memory_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.get_memory|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->get_memory_container

Get a memory container.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/memory_containers/{memory_container_id}>

=back

    $resp = $client->ml->get_memory_container(
        
         # path parameters
        
        'memory_container_id'  =>  $memory_container_id,  # required
        
         # Common API query string parameters
        
        'error_trace'          =>  $qval1,     # boolean
        'filter_path'          =>  $qval2,     # list
        'human'                =>  $qval3,     # boolean
        'pretty'               =>  $qval4,     # boolean
        'source'               =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.get_memory_container|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->get_message

Get a message.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/memory/message/{message_id}>

=back

    $resp = $client->ml->get_message(
        
         # path parameters
        
        'message_id'   =>  $message_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.get_message|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->get_message_traces

Get a message traces.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/memory/message/{message_id}/traces>

=back

    $resp = $client->ml->get_message_traces(
        
         # path parameters
        
        'message_id'   =>  $message_id,  # required
        
         # Endpoint specific query string parameters
        
        'max_results'  =>  $qval1,     # number
        'next_token'   =>  $qval2,     # number
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval3,     # boolean
        'filter_path'  =>  $qval4,     # list
        'human'        =>  $qval5,     # boolean
        'pretty'       =>  $qval6,     # boolean
        'source'       =>  $qval7,     # string
    );

L<OpenSearch documentation for ml.get_message_traces|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->get_model

Retrieves a model.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/models/{model_id}>

=back

    $resp = $client->ml->get_model(
        
         # path parameters
        
        'model_id'     =>  $model_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.get_model|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->get_model_group

Retrieves a model group.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/model_groups/{model_group_id}>

=back

    $resp = $client->ml->get_model_group(
        
         # path parameters
        
        'model_group_id'  =>  $model_group_id,  # required
        
         # Common API query string parameters
        
        'error_trace'     =>  $qval1,     # boolean
        'filter_path'     =>  $qval2,     # list
        'human'           =>  $qval3,     # boolean
        'pretty'          =>  $qval4,     # boolean
        'source'          =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.get_model_group|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->get_profile

Get a profile.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/profile>

=back

    $resp = $client->ml->get_profile(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.get_profile|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->get_profile_models

Get a profile models.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/profile/models>

=item
C<GET /_plugins/_ml/profile/models/{model_id}>

=back

    $resp = $client->ml->get_profile_models(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'model_id'     =>  $model_id,  # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.get_profile_models|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->get_profile_tasks

Get a profile tasks.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/profile/tasks>

=item
C<GET /_plugins/_ml/profile/tasks/{task_id}>

=back

    $resp = $client->ml->get_profile_tasks(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'task_id'      =>  $task_id,   # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.get_profile_tasks|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->get_stats

Get stats.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/stats>

=item
C<GET /_plugins/_ml/stats/{stat}>

=item
C<GET /_plugins/_ml/{node_id}/stats>

=item
C<GET /_plugins/_ml/{node_id}/stats/{stat}>

=back

    $resp = $client->ml->get_stats(
        
         # path parameters
        
        'node_id'      =>  $node_id,   # optional
        'stat'         =>  $stat,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.get_stats|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->get_task

Retrieves a task.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/tasks/{task_id}>

=back

    $resp = $client->ml->get_task(
        
         # path parameters
        
        'task_id'      =>  $task_id,   # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.get_task|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->get_tool

Get tools.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/tools/{tool_name}>

=back

    $resp = $client->ml->get_tool(
        
         # path parameters
        
        'tool_name'    =>  $tool_name,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.get_tool|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->load_model

Deploys a model.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/models/{model_id}/_load>

=back

    $resp = $client->ml->load_model(
        
         # path parameters
        
        'model_id'     =>  $model_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.load_model|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->predict

Predicts new data with trained model.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/_predict/{algorithm_name}/{model_id}>

=back

    $resp = $client->ml->predict(
        
        'body'            =>  $body,      # optional
        
         # path parameters
        
        'algorithm_name'  =>  $algorithm_name,  # required
        'model_id'        =>  $model_id,  # required
        
         # Common API query string parameters
        
        'error_trace'     =>  $qval1,     # boolean
        'filter_path'     =>  $qval2,     # list
        'human'           =>  $qval3,     # boolean
        'pretty'          =>  $qval4,     # boolean
        'source'          =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.predict|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->predict_model

Predicts a model.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/models/{model_id}/_predict>

=back

    $resp = $client->ml->predict_model(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'model_id'     =>  $model_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.predict_model|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->predict_model_stream

Predicts a model in streaming mode.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/models/{model_id}/_predict/stream>

=back

    $resp = $client->ml->predict_model_stream(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'model_id'     =>  $model_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.predict_model_stream|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->register_agents

Register an agent.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/agents/_register>

=back

    $resp = $client->ml->register_agents(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.register_agents|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->register_model

Registers a model.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/models/_register>

=back

    $resp = $client->ml->register_model(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.register_model|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->register_model_group

Registers a model group.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/model_groups/_register>

=back

    $resp = $client->ml->register_model_group(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.register_model_group|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->register_model_meta

Registers model metadata.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/models/_register_meta>

=back

    $resp = $client->ml->register_model_meta(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.register_model_meta|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->search_agentic_memory

Search for memories of a specific type within a memory container.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/memory_containers/{memory_container_id}/memories/{type}/_search>

=back

    $resp = $client->ml->search_agentic_memory(
        
        'body'                 =>  $body,      # optional
        
         # path parameters
        
        'memory_container_id'  =>  $memory_container_id,  # required
        'type'                 =>  $type,      # required
        
         # Common API query string parameters
        
        'error_trace'          =>  $qval1,     # boolean
        'filter_path'          =>  $qval2,     # list
        'human'                =>  $qval3,     # boolean
        'pretty'               =>  $qval4,     # boolean
        'source'               =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.search_agentic_memory|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->search_agents

Search agents.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/agents/_search>

=item
C<POST /_plugins/_ml/agents/_search>

=back

    $resp = $client->ml->search_agents(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.search_agents|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->search_connectors

Searches for standalone connectors.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/connectors/_search>

=item
C<POST /_plugins/_ml/connectors/_search>

=back

    $resp = $client->ml->search_connectors(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.search_connectors|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->search_memory

Search memory.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/memory/_search>

=item
C<POST /_plugins/_ml/memory/_search>

=back

    $resp = $client->ml->search_memory(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.search_memory|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->search_memory_container

Search memory containers.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/memory_containers/_search>

=item
C<POST /_plugins/_ml/memory_containers/_search>

=back

    $resp = $client->ml->search_memory_container(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.search_memory_container|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->search_message

Search messages.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/memory/{memory_id}/_search>

=item
C<POST /_plugins/_ml/memory/{memory_id}/_search>

=back

    $resp = $client->ml->search_message(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'memory_id'    =>  $memory_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.search_message|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->search_model_group

Searches for model groups.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/model_groups/_search>

=item
C<POST /_plugins/_ml/model_groups/_search>

=back

    $resp = $client->ml->search_model_group(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.search_model_group|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->search_models

Searches for models.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/models/_search>

=item
C<POST /_plugins/_ml/models/_search>

=back

    $resp = $client->ml->search_models(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.search_models|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->search_tasks

Searches for tasks.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_ml/tasks/_search>

=item
C<POST /_plugins/_ml/tasks/_search>

=back

    $resp = $client->ml->search_tasks(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.search_tasks|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->train

Trains a model synchronously.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/_train/{algorithm_name}>

=back

    $resp = $client->ml->train(
        
        'body'            =>  $body,      # optional
        
         # path parameters
        
        'algorithm_name'  =>  $algorithm_name,  # required
        
         # Common API query string parameters
        
        'error_trace'     =>  $qval1,     # boolean
        'filter_path'     =>  $qval2,     # list
        'human'           =>  $qval3,     # boolean
        'pretty'          =>  $qval4,     # boolean
        'source'          =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.train|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->train_predict

Trains a model and predicts against the same training dataset.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/_train_predict/{algorithm_name}>

=back

    $resp = $client->ml->train_predict(
        
        'body'            =>  $body,      # optional
        
         # path parameters
        
        'algorithm_name'  =>  $algorithm_name,  # required
        
         # Common API query string parameters
        
        'error_trace'     =>  $qval1,     # boolean
        'filter_path'     =>  $qval2,     # list
        'human'           =>  $qval3,     # boolean
        'pretty'          =>  $qval4,     # boolean
        'source'          =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.train_predict|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->undeploy_model

Undeploys a model.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/models/_undeploy>

=item
C<POST /_plugins/_ml/models/{model_id}/_undeploy>

=back

    $resp = $client->ml->undeploy_model(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'model_id'     =>  $model_id,  # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.undeploy_model|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->unload_model

Unloads a model.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/models/_unload>

=item
C<POST /_plugins/_ml/models/{model_id}/_unload>

=back

    $resp = $client->ml->unload_model(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'model_id'     =>  $model_id,  # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.unload_model|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->update_agentic_memory

Update a specific memory by its type and ID.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_ml/memory_containers/{memory_container_id}/memories/{type}/{id}>

=back

    $resp = $client->ml->update_agentic_memory(
        
        'body'                 =>  $body,      # optional
        
         # path parameters
        
        'id'                   =>  $id,        # required
        'memory_container_id'  =>  $memory_container_id,  # required
        'type'                 =>  $type,      # required
        
         # Common API query string parameters
        
        'error_trace'          =>  $qval1,     # boolean
        'filter_path'          =>  $qval2,     # list
        'human'                =>  $qval3,     # boolean
        'pretty'               =>  $qval4,     # boolean
        'source'               =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.update_agentic_memory|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->update_connector

Updates a standalone connector.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_ml/connectors/{connector_id}>

=back

    $resp = $client->ml->update_connector(
        
        'body'          =>  $body,      # optional
        
         # path parameters
        
        'connector_id'  =>  $connector_id,  # required
        
         # Common API query string parameters
        
        'error_trace'   =>  $qval1,     # boolean
        'filter_path'   =>  $qval2,     # list
        'human'         =>  $qval3,     # boolean
        'pretty'        =>  $qval4,     # boolean
        'source'        =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.update_connector|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->update_controller

Updates a controller.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_ml/controllers/{model_id}>

=back

    $resp = $client->ml->update_controller(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'model_id'     =>  $model_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.update_controller|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->update_memory

Update a memory.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_ml/memory/{memory_id}>

=back

    $resp = $client->ml->update_memory(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'memory_id'    =>  $memory_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.update_memory|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->update_memory_container

Update a memory container.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_ml/memory_containers/{memory_container_id}>

=back

    $resp = $client->ml->update_memory_container(
        
        'body'                 =>  $body,      # optional
        
         # path parameters
        
        'memory_container_id'  =>  $memory_container_id,  # required
        
         # Common API query string parameters
        
        'error_trace'          =>  $qval1,     # boolean
        'filter_path'          =>  $qval2,     # list
        'human'                =>  $qval3,     # boolean
        'pretty'               =>  $qval4,     # boolean
        'source'               =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.update_memory_container|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->update_message

Update a message.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_ml/memory/message/{message_id}>

=back

    $resp = $client->ml->update_message(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'message_id'   =>  $message_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.update_message|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->update_model

Updates a model.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_ml/models/{model_id}>

=back

    $resp = $client->ml->update_model(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'model_id'     =>  $model_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.update_model|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->update_model_group

Updates a model group.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_ml/model_groups/{model_group_id}>

=back

    $resp = $client->ml->update_model_group(
        
        'body'            =>  $body,      # optional
        
         # path parameters
        
        'model_group_id'  =>  $model_group_id,  # required
        
         # Common API query string parameters
        
        'error_trace'     =>  $qval1,     # boolean
        'filter_path'     =>  $qval2,     # list
        'human'           =>  $qval3,     # boolean
        'pretty'          =>  $qval4,     # boolean
        'source'          =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.update_model_group|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->upload_chunk

Uploads model chunk.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/models/{model_id}/upload_chunk/{chunk_number}>

=back

    $resp = $client->ml->upload_chunk(
        
        'body'          =>  $body,      # optional
        
         # path parameters
        
        'chunk_number'  =>  $chunk_number,  # required
        'model_id'      =>  $model_id,  # required
        
         # Common API query string parameters
        
        'error_trace'   =>  $qval1,     # boolean
        'filter_path'   =>  $qval2,     # list
        'human'         =>  $qval3,     # boolean
        'pretty'        =>  $qval4,     # boolean
        'source'        =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.upload_chunk|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>
    
=head2 ml->upload_model

Registers a model.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_ml/models/_upload>

=back

    $resp = $client->ml->upload_model(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for ml.upload_model|https://docs.opensearch.org/latest/ml-commons-plugin/api/index/>

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

