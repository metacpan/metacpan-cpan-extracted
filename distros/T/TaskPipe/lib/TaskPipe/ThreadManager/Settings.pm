package TaskPipe::ThreadManager::Settings;

use Moose;
with 'MooseX::ConfigCascade';


=head1 NAME

TaskPipe::ThreadManager::Settings - Settings for L<TaskPipe::ThreadManager>

=head1 METHODS

=over

=item max_threads

The maximum number of threads to use when running a plan. Taskpipe tries to adhere strictly to the number of threads you specify here - so parent threads are included in the value. You should experiment with your setup to determine the optimum value for your system

=cut

has max_threads => (is => 'ro', isa => 'Int', default => 80);



=item refresh_mins

The number of minutes after which a thread should be refreshed. Refreshing a thread has the same effect as stopping the thread and running it again - it resumes where it left off, but obviously there is a performance penalty. The point of doing this is to mitigate memory leaks which occur in long running code. The less leaky the code, the longer C<refresh_mins> can be. (However, even L<LWP::UserAgent> and L<Web::Scraper> both appear to leak slightly in long runs, so it is probably better to accept leaks as a fact of life and compensate for them rather than spending hours trying to eliminate them entirely.)

=cut

has refresh_mins => (is => 'ro', isa => 'Int', default => 20);



=item thread_table_deadlock_retries

The number of times to retry an update to the thread table in the event of a "serialization failure" (deadlock)

=cut

has thread_table_deadlock_retries => (is => 'ro', isa => 'Int', default => 4 );



=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut


__PACKAGE__->meta->make_immutable;
1;

