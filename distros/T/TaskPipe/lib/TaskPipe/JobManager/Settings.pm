package TaskPipe::JobManager::Settings;

use Moose;
with 'MooseX::ConfigCascade';

=head1 NAME

TaskPipe::JobManager::Settings - settings for the L<TaskPipe::JobManager> module

=head1 METHODS

=over

=item max_kill_job_attempts

The maximum number of tries to kill all processes associated with a job before giving up

=back

=cut

has max_kill_job_attempts => (is => 'ro', isa => 'Int', default => 5);

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;

