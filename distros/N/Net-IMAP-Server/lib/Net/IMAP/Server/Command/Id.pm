package Net::IMAP::Server::Command::Id;

use warnings;
use strict;

use base qw/Net::IMAP::Server::Command/;

sub validate {
    my $self = shift;

    my @options = $self->parsed_options;
    return $self->bad_command("Not enough options") if @options < 1;
    return $self->bad_command("Too many options") if @options > 1;
    return $self->bad_command("Argument must be a list or NIL") unless $options[0] eq "NIL"
      or ref $options[0] eq "ARRAY";

    return 1;
}

sub run {
    my $self = shift;

    my @options = $self->parsed_options;
    $options[0] = [] if $options[0] eq "NIL";
    $self->connection->client_id(@{$options[0]});
    $self->untagged_response("ID " . $self->data_out([$self->server->id]));

    $self->ok_completed();
}

1;
