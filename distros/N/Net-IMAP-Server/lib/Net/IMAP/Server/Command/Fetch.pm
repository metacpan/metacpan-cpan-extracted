package Net::IMAP::Server::Command::Fetch;

use warnings;
use strict;

use base qw/Net::IMAP::Server::Command/;

use Coro;

sub validate {
    my $self = shift;

    return $self->bad_command("Login first") if $self->connection->is_unauth;
    return $self->bad_command("Select a mailbox first")
        unless $self->connection->is_selected;

    my @options = $self->parsed_options;
    return $self->bad_command("Not enough options") if @options < 2;
    return $self->bad_command("Too many options") if @options > 2;

    return $self->bad_command("Invalid message set")
        unless $options[0] =~ $self->connection->SEQUENCE_STRING;

    return 1;
}

sub run {
    my $self = shift;

    my ( $messages, $spec ) = $self->parsed_options;
    my @messages = $self->connection->get_messages($messages);
    for my $m (@messages) {
        $self->untagged_response( $self->connection->sequence($m)
                . " FETCH "
                . $self->data_out( [ $m->fetch($spec) ] ) );
        cede;
    }

    $self->ok_completed();
}

sub send_untagged {
    my $self = shift;

    $self->SUPER::send_untagged( expunged => 0 );
}

1;
