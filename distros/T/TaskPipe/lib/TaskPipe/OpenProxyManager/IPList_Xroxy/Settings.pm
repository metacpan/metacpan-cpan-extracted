package TaskPipe::OpenProxyManager::IPList_Xroxy::Settings;

use Moose;
with 'MooseX::ConfigCascade';

=head1 NAME

TaskPipe::OpenProxyManager::IPList_Xroxy::Settings - settings for TaskPipe::OpenProxyManager::IPList_Xroxy

=head1 METHODS

=over

=item url_template

The template used to form xroxy urls

=cut

has url_template => (
    is => 'ro',
    isa => 'Str',
    default => 'http://www.xroxy.com/proxylist.php?port=&type=&ssl=&country=&latency=&reliability=&sort=reliability&desc=true&pnum=<page>#table'
);

=item ua_mgr_module

The UserAgentManager module to use

=cut

has ua_mgr_module => (is => 'ro', isa => 'Str', default => 'TaskPipe::UserAgentManager_ProxyNet_TOR');


=item ua_handler_module

The UserAgentHandler module to use

=cut

has ua_handler_module => (
    is => 'ro',
    isa => 'Str',
    default => 'TaskPipe::UserAgentManager::UserAgentHandler_PhantomJS'
);


=item proxies_per_page

The number of proxies expected to appear on each page

=back

=cut

has proxies_per_page => (is => 'ro', isa => 'Int', default => 10);


1;
__PACKAGE__->meta->make_immutable;
