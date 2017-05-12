package Net::IMAP::Server::Command::Login;

use warnings;
use strict;

use base qw/Net::IMAP::Server::Command/;

sub validate {
    my $self = shift;

    return $self->bad_command("Already logged in")
        unless $self->connection->is_unauth;

    my @options = $self->parsed_options;
    return $self->bad_command("Not enough options") if @options < 2;
    return $self->bad_command("Too many options") if @options > 2;

    $self->untagged_response("BAD [ALERT] Plaintext authentication not over SSL is insecure -- your password was just exposed.")
        unless $self->connection->is_encrypted;

    return $self->no_command("Login is disabled")
      if $self->connection->capability =~ /\bLOGINDISABLED\b/;

    return 1;
}

sub run {
    my $self = shift;

    $self->server->auth_class->require || $self->log( 1, $@ );
    my $auth = $self->server->auth_class->new;
    if (not $auth->provides_plain) {
        $self->bad_command("Protocol failure");
    } elsif ( $auth->auth_plain( $self->parsed_options ) ) {
        $self->connection->auth($auth);
        $self->ok_completed();
    } else {
        $self->no_command("Invalid login");
    }
}

1;
