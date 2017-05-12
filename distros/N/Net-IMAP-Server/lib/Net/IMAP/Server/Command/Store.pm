package Net::IMAP::Server::Command::Store;

use warnings;
use strict;

use base qw/Net::IMAP::Server::Command/;

use Coro;

sub validate {
    my $self = shift;

    return $self->bad_command("Login first") if $self->connection->is_unauth;
    return $self->bad_command("Select a mailbox first")
        unless $self->connection->is_selected;

    return $self->bad_command("Mailbox is read-only") if $self->connection->selected->read_only;

    my @options = $self->parsed_options;
    return $self->bad_command("Not enough options") if @options < 3;
    return $self->bad_command("Too many options") if @options > 3;

    return $self->bad_command("Invalid message set")
        unless $options[0] =~ $self->connection->SEQUENCE_STRING;

    return $self->bad_command("Invalid FLAGS option")
        unless $options[1] =~ /^[+-]?FLAGS(\.SILENT)?$/;

    return 1;
}

sub run {
    my $self = shift;

    my ( $messages, $what, $flags ) = $self->parsed_options;
    $flags = ref $flags ? $flags : [$flags];

    return $self->bad_command("Invalid flag $_") for grep {not $self->connection->selected->can_set_flag($_)} @{$flags};

    my @messages = $self->connection->get_messages($messages);
    $self->connection->ignore_flags(1) if $what =~ /\.SILENT$/i;
    for my $m (@messages) {
        $m->store( $what => $flags );
        cede;
    }
    $self->connection->ignore_flags(0) if $what =~ /\.SILENT$/i;

    $self->ok_completed();
}

sub send_untagged {
    my $self = shift;

    $self->SUPER::send_untagged( expunged => 0 );
}

1;
