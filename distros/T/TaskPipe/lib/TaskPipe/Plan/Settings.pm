package TaskPipe::Plan::Settings;

use Moose;
with 'MooseX::ConfigCascade';
with 'TaskPipe::Role::MooseType_ShellMode';
with 'TaskPipe::Role::MooseType_IterateMode';

=head1 NAME

TaskPipe::Plan::Settings - settings for L<TaskPipe::Plan>

=head1 METHODS

=over

=item shell

Whether to run in the terminal or daemonize. Options are C<foreground> and C<background>

=cut

has shell => (is => 'ro', isa => 'ShellMode', default => 'foreground');



=item iterate

Choices are C<once> or C<repeat>. To kick off a daemon process that continually polls for open proxies, use C<--shell=background> together with C<--iterate=repeat>

=cut

has iterate => (is => 'ro', isa => 'IterateMode', default => 'once');



=item poll_interval

If --iterate=repeat then --poll_interval is the number of seconds to wait between iterations. --poll_interval is ignored if --iterate=once

=back

=cut

has poll_interval => (is => 'ro', isa => 'Int', default => 0);

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;
