package TaskPipe::Task_Scrape::Settings;

use Moose;
with 'MooseX::ConfigCascade';

=head1 NAME

TaskPipe::Task_Scrape::Settings - settings for L<TaskPipe::Task_Scrape>

=head1 METHODS

=over

=item max_retries

The maximum number of times to retry if the request fails

=cut

has max_retries => (is => 'ro', isa => 'Int', default => 3);

=item require_referer

Exit with an error if set to 1 and no referer is provided (alongside url)

=cut

has require_referer => (is => 'ro', isa => 'Bool', default => 1);


=item ua_mgr_module

The UserAgentManager module to use

=cut

has ua_mgr_module => (is => 'ro', isa => 'Str', default => 'TaskPipe::UserAgentManager');


=item ua_handler_module

The UserAgentHandler module to use

=cut

has ua_handler_module => (is => 'ro', isa => 'Str', default => 'TaskPipe::UserAgentManager::UserAgentHandler');

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut


__PACKAGE__->meta->make_immutable;
1;
__END__

