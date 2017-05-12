package Net::IMAP::Server::Error;

use warnings;
use strict;

use base qw/Net::IMAP::Server::Command/;

=head1 NAME

Net::IMAP::Server::Error - A command which failed catastrophically

=head1 DESCRIPTION

A subclass of L<Net::IMAP::Server::Command> used when the true command
fails to compile or load, for whatever reason.  This is intentionally
not C<Net::IMAP::Server::Command::Error>, as that would make it
available to clients as the C<ERROR> command.

=head1 METHODS

=head2 run

Produces a server error.

=cut

sub run {
    my $self = shift;

    $self->no_command("Server error");
}

1;
