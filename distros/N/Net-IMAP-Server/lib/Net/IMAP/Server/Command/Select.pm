package Net::IMAP::Server::Command::Select;

use warnings;
use strict;

use base qw/Net::IMAP::Server::Command/;

sub validate {
    my $self = shift;

    return $self->bad_command("Log in first") if $self->connection->is_unauth;

    my @options = $self->parsed_options;
    return $self->bad_command("Not enough options") if @options < 1;
    return $self->bad_command("Too many options") if @options > 1;

    return 1;
}

sub run {
    my $self = shift;

    $self->connection->selected->expunge
        if $self->connection->selected
            and not $self->connection->selected->read_only;
    $self->connection->selected(undef);

    my $mailbox = $self->connection->model->lookup( $self->parsed_options );
    return $self->no_command("Mailbox does not exist") unless $mailbox;
    return $self->no_command("Mailbox is not selectable") unless $mailbox->is_selectable;

    $mailbox->poll;
    $self->connection->last_poll(time);
    $self->connection->selected($mailbox, $self->command eq "Examine");

    $self->untagged_response(
        'FLAGS (' . join( ' ', $mailbox->flags ) . ')' );
    $self->untagged_response( $mailbox->exists . ' EXISTS' );
    $self->untagged_response( $mailbox->recent . ' RECENT' );

    my $unseen = $mailbox->first_unseen;
    $self->untagged_response("OK [UNSEEN $unseen]");

    my $uidvalidity = $mailbox->uidvalidity;
    $self->untagged_response("OK [UIDVALIDITY $uidvalidity]")
        if defined $uidvalidity;

    my $uidnext = $mailbox->uidnext;
    $self->untagged_response("OK [UIDNEXT $uidnext]") if defined $uidnext;

    my $permanentflags = $mailbox->permanentflags;
    $self->untagged_response( "OK [PERMANENTFLAGS ("
            . join( ' ', $mailbox->permanentflags )
            . ')]' );

    if ( $mailbox->read_only ) {
        $self->ok_command("[READ-ONLY] Completed");
    } else {
        $self->ok_command("[READ-WRITE] Completed");
    }
}

sub poll_after { 0 }

1;
