package Net::IMAP::Server::Command::Subscribe;

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
    return $self->no_command("Mailbox does not exist") unless $mailbox;

    return 1;
}

sub run {
    my $self = shift;

    my $mailbox = $self->connection->model->lookup( $self->parsed_options );
    $mailbox->subscribed(1);

    $self->ok_completed();
}

1;
