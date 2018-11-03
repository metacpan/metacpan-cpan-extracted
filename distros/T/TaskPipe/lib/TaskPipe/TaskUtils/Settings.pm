package TaskPipe::TaskUtils::Settings;

use Moose;
with 'MooseX::ConfigCascade';

=head1 NAME

TaskPipe::TaskUtils::Settings - settings for the L<TaskPipe::TaskUtils> module

=head1 METHODS

=over

=item xtask_script

The filename of the script which executes an individual task

=back

=cut


has xtask_script => (is => 'ro', isa => 'Str', default => 'taskpipe-xtask');

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;
