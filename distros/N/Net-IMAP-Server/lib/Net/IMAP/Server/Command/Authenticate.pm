package Net::IMAP::Server::Command::Authenticate;

use warnings;
use strict;

use MIME::Base64;
use base qw/Net::IMAP::Server::Command/;

__PACKAGE__->mk_accessors(qw(sasl pending_auth));

sub validate {
    my $self = shift;

    return $self->bad_command("Already logged in")
        unless $self->connection->is_unauth;

    my @options = $self->parsed_options;
    return $self->bad_command("Not enough options") if @options < 1;
    return $self->bad_command("Too many options") if @options > 2;

    $self->untagged_response("BAD [ALERT] Plaintext authentication not over SSL is insecure -- your password was just exposed.")
        if $options[0] eq "PLAIN" and not $self->connection->is_encrypted;

    return $self->no_command("Authentication type not supported")
      unless $self->connection->capability =~ /\bAUTH=$options[0]\b/i;

    return 1;
}

sub run {
    my $self = shift;

    my($type, $arg) = $self->parsed_options;
    $self->server->auth_class->require || $self->log( 1, $@ );
    my $auth = $self->server->auth_class->new;
    if ( grep {uc $type eq uc $_} $auth->sasl_provides ) {
        $type = lc $type;
        $type =~ s/\W/_/g;
        my $function = "sasl_$type";
        $self->sasl( $auth->$function() );
        $self->pending_auth($auth);
        $self->connection->pending(sub {$self->continue(@_)});
        $self->continue( $arg || "");
    } else {
        $self->no_command("Authentication type not supported");
    }
}

sub continue {
    my $self = shift;
    my $line = shift;

    $self->connection->pending(undef);

    return $self->bad_command("Login cancelled")
        if not defined $line or $line =~ /^\*[\r\n]+$/;

    $line =~ s/[\r\n]+$//;
    my $decoded = decode_base64($line);
    return $self->bad_command("Invalid base64")
        if encode_base64($decoded, "") ne $line;

    my $response = $self->sasl->($decoded);
    if ( ref $response ) {
        $self->connection->pending(sub{$self->continue(@_)});
        $self->out( "+ " . encode_base64($$response, "") );
    } elsif (not $response) {
        $self->no_command("Invalid login");
    } elsif ($response < 0) {
        $self->bad_command("Protocol failure");
    } else {
        $self->connection->auth( $self->pending_auth );
        $self->ok_completed();
    }
}

1;
