package TaskPipe::UserAgentManager::Settings;

use Moose;
with 'MooseX::ConfigCascade';

=head1 NAME

TaskPipe::UserAgentManager::Settings - settings for TaskPipe::UserAgentManger

=head1 DESCRIPTION

Settings for L<TaskPipe::UserAgentManager>

=head1 METHODS

=over

=item max_retries

The maximum number of times to retry if a request fails

=cut

has max_retries => (is => 'ro', isa=> 'Int', default => 3);


=item delay_base

The minimum number of seconds to delay between requests for a particular thread

=cut

has delay_base => (is => 'ro', isa => 'Int', default => 4);


=item delay_max_rand

Randomise the number of seconds to wait between requests. Specify C<delay_max_rand> to add a random number of seconds to add to C<delay_base> between 0 and C<delay_max_rand>

=back

=cut

has delay_max_rand => (is => 'ro', isa => 'Int', default => 8);

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;
