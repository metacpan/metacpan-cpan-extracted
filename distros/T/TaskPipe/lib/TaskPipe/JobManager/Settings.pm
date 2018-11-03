package TaskPipe::JobManager::Settings;

use Moose;
with 'MooseX::ConfigCascade';

=head1 NAME

TaskPipe::JobManager::Settings - settings for the L<TaskPipe::JobManager> module

=head1 METHODS

=over

=item max_kill_job_attempts

The maximum number of tries to kill all processes associated with a job before giving up

=cut

has max_kill_job_attempts => (is => 'ro', isa => 'Int', default => 5);


=item job_tracking

Whether to record the executed command as a job in the job table. Recording the command as a job means the job can be inspected and managed via commands like C<show jobs> and C<stop job>. This is the default behaviour. Specifying C<job_tracking=none> is necessary for commands like C<taskpipe setup> when the global database tables do not yet exist.

=back

=cut

has job_tracking => (is => 'ro', isa => 'Str', default => 'register');


=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;

