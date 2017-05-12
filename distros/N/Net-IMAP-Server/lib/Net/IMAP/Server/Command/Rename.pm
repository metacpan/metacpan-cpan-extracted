package Net::IMAP::Server::Command::Rename;

use warnings;
use strict;

use base qw/Net::IMAP::Server::Command/;

sub validate {
    my $self = shift;

    return $self->bad_command("Log in first") if $self->connection->is_unauth;

    my @options = $self->parsed_options;
    return $self->bad_command("Not enough options") if @options < 2;
    return $self->bad_command("Too many options") if @options > 2;

    my($old, $new) = @options;
    my $oldbox = $self->connection->model->lookup($old);
    return $self->no_command("Mailbox doesn't exist") unless $oldbox;
    my $newbox = $self->connection->model->lookup($new);
    return $self->no_command("Mailbox already exists") if $newbox;

    # Test that the new name is valid
    return $self->valid_mailbox($new);
}

sub run {
    my $self = shift;

    my($old, $new) = $self->parsed_options;
    my @parts = $self->connection->model->split($new);

    my $newname = pop @parts;
    my $mailbox = $self->connection->model->lookup($old);

    my $base = $self->connection->model->root;
    for my $n (0.. $#parts) {
        my $sep = $self->connection->model->root->separator || "";
        my $path = join($sep, @parts[0 .. $n]);
        my $part = $self->connection->model->lookup($path);
        unless ($part) {
            unless ($part = $base->create( name => $parts[$n] )) {
                return $self->no_command("Permission denied");
            }
        }
        $base = $part;
    }

    $mailbox->reparent($base, $newname) or return $self->no_command("Permission denied");

    $self->ok_completed();
}

1;
