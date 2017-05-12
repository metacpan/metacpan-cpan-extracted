use warnings;
use strict;

package Remind::Client::libnotify;

=head1 NAME

Remind::Client::libnotify - class to send timed reminders to libnotify

=head1 SYNOPSIS

  use Remind::Client::libnotify;

  my $rc = Remind::Client::libnotify->new();
  $rc->run();

=head1 DESCRIPTION

This module is a subclass of Remind::Client, which provides support for
sending timed reminders directly to libnotify, via the notify-send
command.

=head1 METHODS

=cut

our $VERSION = '0.03';
$VERSION = eval $VERSION;

use base 'Remind::Client';

my $NOTIFY_SEND = 'notify-send';
my $DEFAULT_SUMMARY = __PACKAGE__;
my $DEFAULT_URGENCY = 'critical';

=head2 new

Construct a Remind::Client::libnotify object.

In addition to the parameters accepted by Remind::Client->new(), the
following named parameters are accepted:

=over 4

=item summary

The summary to use for all notifications. Defaults to
Remind::Client::libnotify.

=item urgency

The urgency to use for the notifications. One of 'low', 'normal', or
'critical'. Defaults to 'critical'.

=back

=cut

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new(%args);

    $self->{summary} ||= $DEFAULT_SUMMARY;
    $self->{urgency} ||= $DEFAULT_URGENCY;

    return $self;
}

=head2 reminder

Reminder event handler. This will create one libnotify notifier for each
reminder sent by remind.

=cut

sub reminder {
    my ($self, %args) = @_;

    $self->_notify(
        summary => $self->{summary},
        message => $args{message},
        urgency => $self->{urgency},
    );
}

sub _notify {
    my ($self, %args) = @_;

    $self->_debug("About to run: ",
        join(' ', $NOTIFY_SEND, "--urgency=$args{urgency}", $args{summary}, $args{message}));

    system $NOTIFY_SEND, "--urgency=$args{urgency}", $args{summary}, $args{message};
}

=head1 SEE ALSO

L<Remind::Client>, L<notify-send>(1)

=head1 AUTHOR

Mike Kelly <pioto@pioto.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009, Mike Kelly.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses at <http://www.perlfoundation.org/artistic_license_1_0>,
and <http://www.gnu.org/licenses/gpl-2.0.html>.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.

=cut

1; 

# vim: set ft=perl sw=4 sts=4 et :
