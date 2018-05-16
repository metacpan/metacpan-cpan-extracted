package TaskPipe::OpenProxyManager::IPList::Settings;

use Moose;
with 'MooseX::ConfigCascade';

=head1 NAME

TaskPipe::OpenProxyManager::IPList::Settings - Settings for TaskPipe::OpenProxyManager::IPList

=head1 METHODS

=over

=item default_port

The port to use if no port is specified (this should probably always be 80)

=cut

has default_port => (is => 'ro', isa => 'Int', default => 80);

=item max_threads

The maximum number of threads to use when fetching/testing proxies

=cut

has max_threads => (is => 'ro', isa => 'Int', default => 10);


=item max_retries

The maximum number of times to retry a request when fetching/testing proxies

=back

=cut

has max_retries => (
    is => 'ro',
    isa => 'Str',
    default => 3
);




1;
