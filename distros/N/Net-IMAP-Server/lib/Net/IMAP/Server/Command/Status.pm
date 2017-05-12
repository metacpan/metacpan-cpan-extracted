package Net::IMAP::Server::Command::Status;

use warnings;
use strict;

use base qw/Net::IMAP::Server::Command/;

sub validate {
    my $self = shift;

    return $self->bad_command("Log in first") if $self->connection->is_unauth;

    my @options = $self->parsed_options;
    return $self->bad_command("Not enough options") if @options < 2;
    return $self->bad_command("Too many options") if @options > 2;

    my ( $name, $flags ) = @options;
    return $self->bad_command("Wrong second option") unless ref $flags;

    my $mailbox = $self->connection->model->lookup( $name );
    return $self->no_command("Mailbox does not exist") unless $mailbox;
    return $self->no_command("Mailbox is not selectable") unless $mailbox->is_selectable;

    return 1;
}

sub run {
    my $self = shift;

    my ( $name, $flags ) = $self->parsed_options;
    my $mailbox = $self->connection->model->lookup( $name );

    my %items = $mailbox->status(map {uc $_} @{$flags});
    $self->untagged_response( "STATUS ".$self->data_out({type=>"string", value => $name}) . " "
                              . $self->data_out([map {(\$_, $items{$_})}keys %items]) );
    $self->ok_completed;
}

1;
