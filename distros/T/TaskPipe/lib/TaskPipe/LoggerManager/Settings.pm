package TaskPipe::LoggerManager::Settings;

use Moose;
with 'MooseX::ConfigCascade';

=head1 NAME

TaskPipe::LoggerManager::Settings - settings for the L<TaskPipe::LoggerManager> module

=head1 METHODS

=over

=item log_mode

Whether to log to file or to the screen (or both). Choices are 

C<file> - always log to file
C<screen> - always log to screen
C<shell> - log to file if command is run in the background, but screen otherwise
C<always> - always log to both screen and file

=back

=cut

has log_mode => (is => 'ro', isa => 'Str', default => 'shell');


=item log_level

The log level to report. Options are C<TRACE>, C<DEBUG>, C<INFO>, C<WARN>, C<ERROR> and C<FATAL>. TaskPipe uses Log::Log4perl - check the documentation this module's CPAN entry for more information.

=cut

has log_level => (is => 'ro', isa => 'Str', default => 'INFO');


=item log_file_access

whether to C<append> or C<overwrite> the log file with each run

=cut

has log_file_access => (is => 'ro', isa => 'Str', default => 'append');


=item log_file_pattern

The logging pattern to use with files. See the documentation for Log::Log4perl for more information

=cut

has log_file_pattern => (is => 'ro', isa => 'Str', default => '[%d] (%p) %F line %L: %m%n');


=item log_screen_pattern

The logging pattern to use when displaying to terminal. See the documentation for Log::Log4perl for more information

=cut

has log_screen_pattern => (is => 'ro', isa => 'Str', default => '%-5p%5J%3i%6P%3h%N %m%n');


=item log_screen_colors

The colors to use when displaying to terminal. This maps C<Log::Log4perl> entities (C<%p>, C<%m> etc.) to ansi color values (C<blue>, C<bold while>, C<yellow on_blue> etc.)

=cut

has log_screen_colors => (is => 'ro', isa => 'HashRef', default => sub {{
    p => {
        TRACE => 'bold green',
        DEBUG => 'white',
        INFO => 'bold white',
        WARN => 'yellow',
        ERROR => 'red',
        FATAL => 'bold red'
    },
    d => 'blue',
    J => 'blue on_white',
    i => 'white on_blue',
    P => 'white on_cyan',
    h => 'red on_white',
    N => 'bold blue'
}});

=item log_dir_format

The format of the logging directory

=cut

has log_dir_format => (is => 'ro', isa => 'Str', default => '<% job_id %>-<% cmd %>');


=item log_filename_format

The format of the log file to write

=back

=cut

has log_filename_format => (is => 'ro', isa => 'Str', default => 'Thread-<% thread_id %>.log');


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
