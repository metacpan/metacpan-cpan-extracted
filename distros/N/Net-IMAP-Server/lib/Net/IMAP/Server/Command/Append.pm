package Net::IMAP::Server::Command::Append;

use warnings;
use strict;

use base qw/Net::IMAP::Server::Command/;

use DateTime::Format::Strptime;

sub validate {
    my $self = shift;

    return $self->bad_command("Log in first") if $self->connection->is_unauth;

    my @options = $self->parsed_options;
    return $self->bad_command("Not enough options") if @options < 2;
    return $self->bad_command("Too many options") if @options > 4;

    my $mailbox = $self->connection->model->lookup( $options[0] );
    return $self->no_command("[TRYCREATE] Mailbox does not exist") unless $mailbox;
    return $self->bad_command("Mailbox is read-only") if $mailbox->read_only;

    return 1;
}

sub run {
    my $self = shift;

    my @options = $self->parsed_options;

    my $mailbox = $self->connection->model->lookup( shift @options );
    if (my $msg = $mailbox->append(pop @options)) {
        if (@options and grep {ref $_} @options) {
            my ($flags) = grep {ref $_} @options;
            $msg->set_flag($_, 1) for @{$flags};
        }
        if (@options and grep {not ref $_} @options) {
            my ($time) = grep {not ref $_} @options;
            $msg->internaldate( $time )
                or return $self->bad_command("Invalid date");
        }

        $self->connection->previous_exists( $self->connection->previous_exists + 1 )
          if $self->connection->is_selected and $mailbox eq $self->connection->selected;
        $self->ok_command("[APPENDUID @{[$mailbox->uidvalidity]} @{[$msg->uid]}] APPEND COMPLETED");
    } else {
        $self->no_command("Permission denied");
    }
}

1;
