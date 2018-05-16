package TaskPipe::OpenProxyManager::IPList_ProxyNova::Settings;

use Moose;
with 'MooseX::ConfigCascade';


=head1 NAME

TaskPipe::OpenProxyManager::IPList_ProxyNova::Settings - Settings for TaskPipe::OpenProxyManager::IPList_ProxyNova

=head1 METHODS

=over

=item countries_url

The URL to use to retrieve countries

=cut

has countries_url => (
    is => 'ro',
    isa => 'Str',
    default => 'https://www.proxynova.com/proxy-server-list/'
);

=item url_template

The template to build URLs with

=cut

has url_template => (
    is => 'ro',
    isa => 'Str',
    default => 'https://www.proxynova.com/proxy-server-list/country-<country_code>/'
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


=item default_port

The port to use if no port is specified (probably will always be 80)

=cut

has default_port => (is => 'ro', isa => 'Int', default => 80);




__PACKAGE__->meta->make_immutable;
1;
