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

package OpenSearch::Client::Core::3_0::Direct::Tasks;
$OpenSearch::Client::Core::3_0::Direct::Tasks::VERSION = '3.007007';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('tasks');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::Tasks>

=head1 VERSION

version 3.007007

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->tasks-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Tasks APIs>


A task is any operation that you run in a cluster. For example, searching your data collection of books for a title or author name is a task. When you run OpenSearch, a task is automatically created to monitor your cluster's health and performance. For more information about all of the tasks currently executing in your cluster, you can use the tasks API operation.

L<See OpenSearch documentation for tasks.|https://docs.opensearch.org/latest/api-reference/tasks/tasks/>

=head1 METHODS
    
=head2 cancel

Cancels a task, if it can be cancelled through an API.

I<Paths served by this method:>

=over

=item
C<POST /_tasks/_cancel>

=item
C<POST /_tasks/{task_id}/_cancel>

=back

    $resp = $client->tasks->cancel(
        
         # path parameters
        
        'task_id'              =>  $task_id,   # optional
        
         # Endpoint specific query string parameters
        
        'actions'              =>  $qval1,     # list
        'nodes'                =>  $qval2,     # list
        'parent_task_id'       =>  $qval3,     # string
        'wait_for_completion'  =>  $qval4,     # boolean
        
         # Common API query string parameters
        
        'error_trace'          =>  $qval5,     # boolean
        'filter_path'          =>  $qval6,     # list
        'human'                =>  $qval7,     # boolean
        'pretty'               =>  $qval8,     # boolean
        'source'               =>  $qval9,     # string
    );

L<OpenSearch documentation for tasks-E<gt>cancel|https://opensearch.org/docs/latest/api-reference/tasks/#task-canceling>
    
=head2 get

Returns information about a task.

I<Paths served by this method:>

=over

=item
C<GET /_tasks/{task_id}>

=back

    $resp = $client->tasks->get(
        
         # path parameters
        
        'task_id'              =>  $task_id,   # required
        
         # Endpoint specific query string parameters
        
        'timeout'              =>  $qval1,     # string
        'wait_for_completion'  =>  $qval2,     # boolean
        
         # Common API query string parameters
        
        'error_trace'          =>  $qval3,     # boolean
        'filter_path'          =>  $qval4,     # list
        'human'                =>  $qval5,     # boolean
        'pretty'               =>  $qval6,     # boolean
        'source'               =>  $qval7,     # string
    );

L<OpenSearch documentation for tasks-E<gt>get|https://opensearch.org/docs/latest/api-reference/tasks/>
    
=head2 list

Returns a list of tasks.

I<Paths served by this method:>

=over

=item
C<GET /_tasks>

=back

    $resp = $client->tasks->list(
        
         # Endpoint specific query string parameters
        
        'actions'              =>  $qval1,     # list
        'detailed'             =>  $qval2,     # boolean
        'group_by'             =>  $qval3,     # string
        'nodes'                =>  $qval4,     # list
        'parent_task_id'       =>  $qval5,     # string
        'timeout'              =>  $qval6,     # string
        'wait_for_completion'  =>  $qval7,     # boolean
        
         # Common API query string parameters
        
        'error_trace'          =>  $qval8,     # boolean
        'filter_path'          =>  $qval9,     # list
        'human'                =>  $qval10,    # boolean
        'pretty'               =>  $qval11,    # boolean
        'source'               =>  $qval12,    # string
    );

L<OpenSearch documentation for tasks-E<gt>list|https://opensearch.org/docs/latest/api-reference/tasks/>

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

