package Search::Elasticsearch::Client::6_0::Direct::Tasks;
$Search::Elasticsearch::Client::6_0::Direct::Tasks::VERSION = '6.81';
use Moo;
with 'Search::Elasticsearch::Client::6_0::Role::API';
with 'Search::Elasticsearch::Role::Client::Direct';
__PACKAGE__->_install_api('tasks');

1;

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Client::6_0::Direct::Tasks - A client for accessing the Task Management API

=head1 VERSION

version 6.81

=head1 DESCRIPTION

This module provides methods to access the Task Management API, such as listing
tasks and cancelling tasks.

It does L<Search::Elasticsearch::Role::Client::Direct>.

=head1 METHODS

=head2 C<list()>

    $response = $e->tasks->list(
        task_id => $task_id  # optional
    );

The C<list()> method returns all running tasks or, if a C<task_id> is specified, info
about that task.

Query string parameters:
    C<actions>,
    C<detailed>,
    C<error_trace>,
    C<group_by>,
    C<human>,
    C<nodes>,
    C<parent_task_id>,
    C<timeout>,
    C<wait_for_completion>

See the L<task management docs|http://www.elastic.co/guide/en/elasticsearch/reference/current/tasks.html>
for more information.

=head2 C<get()>

    $response = $e->tasks->get(
        task_id => $task_id  # required
    );

The C<get()> method returns the task with the specified ID.

Query string parameters:
    C<error_trace>,
    C<human>,
    C<wait_for_completion>

See the L<task management docs|http://www.elastic.co/guide/en/elasticsearch/reference/current/tasks.html>
for more information.

=head2 C<cancel()>

    $response = $e->tasks->cancel(
        task_id => $task_id  # required
    );

The C<cancel()> method attempts to cancel the specified C<task_id> or multiple tasks.

Query string parameters:
    C<actions>,
    C<error_trace>,
    C<human>,
    C<nodes>,
    C<parent_task_id>,
    C<timeout>

See the L<task management docs|http://www.elastic.co/guide/en/elasticsearch/reference/current/tasks.html>
for more information.

=head1 AUTHOR

Enrico Zimuel <enrico.zimuel@elastic.co>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Elasticsearch BV.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__

# ABSTRACT: A client for accessing the Task Management API

