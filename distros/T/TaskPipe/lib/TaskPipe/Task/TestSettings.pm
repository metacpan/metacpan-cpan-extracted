package TaskPipe::Task::TestSettings;

use Moose;
with 'TaskPipe::Role::MooseType_OutputMode';
with 'MooseX::ConfigCascade';

=head1 NAME

TaskPipe::Task::TestSettings - test settings for L<TaskPipe::Task>

=head1 METHODS

=over

=item file_prefix

The test output file filename prefix

=cut

has file_prefix => (is => 'ro', isa => 'Str', default => 'TestResult.');

=item file_suffix

The test output file extension

=cut

has file_suffix => (is => 'ro', isa => 'Str', default => '.log');


=item output

Whether to print test output to screen, file or both. (Options are C<file>, C<screen> or C<file,screen>). This defaults to C<file> because the test result output can be substantial.

=back

=cut

has output => (is => 'ro', isa => 'OutputMode', default => 'file');

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut


__PACKAGE__->meta->make_immutable;
1;


