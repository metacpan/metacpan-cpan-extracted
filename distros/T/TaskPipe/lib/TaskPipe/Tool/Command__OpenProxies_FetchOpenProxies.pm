package TaskPipe::Tool::Command__OpenProxies_FetchOpenProxies;

use Moose;
extends 'TaskPipe::Tool::Command__OpenProxies';

sub execute_specific{
    my ($self) = @_;

    $self->proxy_manager->fetch_proxies;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

TaskPipe::Tool::Command__OpenProxies_FetchOpenProxies - command to fetch open proxies

=head1 PURPOSE

Fetch proxy lists for available proxies and update the database

=head1 DESCRIPTION

C<fetch open proxies> retrieves IPs from a set of proxy lists (specified in the C<TaskPipe::OpenProxyManager::Settings> section in the config.) Collected IPs are placed in the database. 

Each IP list has settings which can be found in the C<global> config file in sections which look like C<TaskPipe::OpenProxyManager::IPList_ListName::Settings> (with C<ListName> replaced with the name of the list.)

The names of the lists to collect IPs from is specified in the C<ip_list_names> parameter in the C<TaskPipe::OpenProxyManager::Settings> config section.

To run this as a background process, include the C<--shell=background> parameter on the command line, and to run it repeatedly (ie turn it into a daemon) also specify C<--iterate=repeat>.

    taskpipe fetch open proxies --shell=background --iterate=repeat

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

1;
