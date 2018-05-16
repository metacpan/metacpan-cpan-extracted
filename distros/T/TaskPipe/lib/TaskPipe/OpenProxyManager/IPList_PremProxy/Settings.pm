package TaskPipe::OpenProxyManager::IPList_PremProxy::Settings;

use Moose;
with 'MooseX::ConfigCascade';

=head1 NAME

TaskPipe::OpenProxyManager::IPList_PremProxy::Settings - settings for TaskPipe::OpenProxyManager::IPList_PremProxy

=head1 METHODS

=over

=item url_template

Used to create prem proxy urls

=cut


has url_template => (is => 'ro', isa => 'Str', default => 'https://premproxy.com/list/time-<page_num>.htm');

=item page_num_format

the format of page numbers to insert in the url

=cut



has page_num_format => (is => 'ro', isa => 'Str', default => '%02d');


=item ua_mgr_module

Which UserAgentManager module to use

=cut

has ua_mgr_module => (is => 'ro', isa => 'Str', default => 'TaskPipe::UserAgentManager_ProxyNet_TOR');


=item ua_handler_module

Which UserAgentHandler module to use

=back

=cut

has ua_handler_module => (is => 'ro', isa => 'Str', default => 'TaskPipe::UserAgentManager::UserAgentHandler_PhantomJS');


__PACKAGE__->meta->make_immutable;
1;

