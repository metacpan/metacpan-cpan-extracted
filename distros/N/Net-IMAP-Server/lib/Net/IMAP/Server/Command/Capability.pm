package Net::IMAP::Server::Command::Capability;

use warnings;
use strict;

use base qw/Net::IMAP::Server::Command/;

sub validate {
    my $self = shift;

    my @options = $self->parsed_options;
    return $self->bad_command("Too many options") if @options;

    return 1;
}

sub run {
    my $self = shift;
    $self->tagged_response( $self->connection->capability );
    $self->ok_completed;
}

1;
