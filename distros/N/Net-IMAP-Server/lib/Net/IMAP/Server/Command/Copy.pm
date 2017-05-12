package Net::IMAP::Server::Command::Copy;

use warnings;
use strict;

use base qw/Net::IMAP::Server::Command/;

use Coro;

sub validate {
    my $self = shift;

    return $self->bad_command("Log in first") if $self->connection->is_unauth;
    return $self->bad_command("Select a mailbox first")
        unless $self->connection->is_selected;

    my @options = $self->parsed_options;
    return $self->bad_command("Not enough options") if @options < 2;
    return $self->bad_command("Too many options") if @options > 2;

    return $self->bad_command("Invalid message set")
        unless $options[0] =~ $self->connection->SEQUENCE_STRING;

    my $mailbox = $self->connection->model->lookup( $options[1] );
    return $self->no_command("[TRYCREATE] Mailbox does not exist") unless $mailbox;
    return $self->bad_command("Mailbox is read-only") if $mailbox->read_only;

    return 1;
}

sub run {
    my $self = shift;

    my ( $messages, $name ) = $self->parsed_options;
    my @messages = $self->connection->get_messages($messages);

    my $mailbox = $self->connection->model->lookup( $name );

    return $self->no_command("Permission denied") if grep {not $_->copy_allowed($mailbox)} @messages;

    my @new;
    for my $m (@messages) {
        push @new, $m->copy($mailbox);
        cede;
    }
    my $sequence = join(",",map {$_->uid} @messages);
    my $uids     = join(",",map {$_->uid} @new);
    $self->ok_command("[COPYUID @{[$mailbox->uidvalidity]} $sequence $uids] COPY COMPLETED");
}

1;
