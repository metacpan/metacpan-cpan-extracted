package Net::IMAP::Server::Command::Check;

use warnings;
use strict;

use base qw/Net::IMAP::Server::Command/;

sub validate {
    my $self = shift;

    return $self->bad_command("Login first") if $self->connection->is_unauth;
    return $self->bad_command("Select a mailbox first")
        unless $self->connection->is_selected;

    my @options = $self->parsed_options;
    return $self->bad_command("Too many options") if @options;

    return 1;
}

sub run {
    my $self = shift;
    $self->connection->poll;
    $self->ok_completed();
}

1;
