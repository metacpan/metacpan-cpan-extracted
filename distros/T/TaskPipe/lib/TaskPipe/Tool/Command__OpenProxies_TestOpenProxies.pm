package TaskPipe::Tool::Command__OpenProxies_TestOpenProxies;

use Moose;
extends 'TaskPipe::Tool::Command__OpenProxies';

sub execute_specific{
    my ($self) = @_;

    $self->proxy_manager->test_proxies;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

TaskPipe::Tool::Command__OpenProxies_TestOpenProxies - command to test open proxies

=head1 PURPOSE

Test the proxies that were retrieved by C<fetch open proxies>.

=head1 DESCRIPTION

C<test open proxies> goes through the list of proxies which C<fetch open proxies> retrieved. C<fetch open proxies> should be run, or at least started in advance of running C<test open proxies>. 

C<test open proxies> proceeds through the table of IPs retrieved by C<fetch open proxies> starting with the proxy that was last tested the longest ago, or not tested at all. Proxies that test successfully are marked C<available> and will be used by C<TaskPipe::UserAgentManager_ProxyNet_Open>. 

Proxies that test unsuccessfully are marked for deletion, but not immediately deleted. This is to prevent retesting of proxies retrieved by C<fetch open proxies> which are known to be dud.

After the time period specified in C<clean_dud_proxies_after>, dud proxies are deleted completely (and thus will be re-found and re-tested if they remain on any list which C<fetch open proxies> is gathering IPs from).

C<test open proxies> can be run as a daemon process by including C<--iterate=repeat> and C<--shell=background>:

    taskpipe test open proxies --iterate=repeat --shell=background

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

1;
