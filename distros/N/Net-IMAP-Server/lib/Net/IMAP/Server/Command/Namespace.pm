package Net::IMAP::Server::Command::Namespace;

use warnings;
use strict;

use base qw/Net::IMAP::Server::Command/;

sub validate {
    my $self = shift;

    return $self->bad_command("Login first") if $self->connection->is_unauth;

    my @options = $self->parsed_options;
    return $self->bad_command("Too many options") if @options;

    return 1;
}

sub run {
    my $self = shift;

    my @namespaces = $self->connection->model->namespaces;
    @namespaces = map {
        ref($_) eq "ARRAY"
            ? "(" . join( "", map { $self->data_out($_) } @{$_} ) . ")"
            : $self->data_out($_)
    } @namespaces;
    $self->untagged_response(join(" ", NAMESPACE => @namespaces));

    $self->ok_completed();
}

1;
