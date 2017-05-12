package Net::IMAP::Server::Command::Delete;

use warnings;
use strict;

use base qw/Net::IMAP::Server::Command/;

sub validate {
    my $self = shift;

    return $self->bad_command("Log in first") if $self->connection->is_unauth;

    my @options = $self->parsed_options;
    return $self->bad_command("Not enough options") if @options < 1;
    return $self->bad_command("Too many options") if @options > 1;

    my $mailbox = $self->connection->model->lookup( @options );
    return $self->no_command("Mailbox doesn't exist") unless $mailbox;
    return $self->no_command("INBOX cannot be deleted") if $mailbox->is_inbox;
    return $self->no_command("Mailbox has children") if @{$mailbox->children};

    return 1;
}

sub run {
    my $self = shift;

    my $mailbox = $self->connection->model->lookup($self->parsed_options);

    $mailbox->delete or return $self->no_command("Permission denied");

    $self->ok_completed();
}

1;
