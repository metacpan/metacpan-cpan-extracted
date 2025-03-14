package Moo::Google::AuthStorage::ConfigJSON;
$Moo::Google::AuthStorage::ConfigJSON::VERSION = '0.03';

# ABSTRACT: Specific methods to fetch tokens from JSON data sources

use Moo;
use Config::JSON;

has 'pathToTokensFile' => ( is => 'rw', default => 'config.json' )
  ;    # default is config.json

# has 'tokensfile';  # Config::JSON object pointer
my $tokensfile;
has 'debug' => ( is => 'rw', default => 0 );

sub setup {
    my $self = shift;
    $tokensfile = Config::JSON->new( $self->pathToTokensFile );
}

sub get_credentials_for_refresh {
    my ( $self, $user ) = @_;
    return {
        client_id     => $self->get_client_id_from_storage(),
        client_secret => $self->get_client_secret_from_storage(),
        refresh_token => $self->get_refresh_token_from_storage($user)
    };
}

sub get_client_id_from_storage {
    $tokensfile->get('gapi/client_id');
}

sub get_client_secret_from_storage {
    $tokensfile->get('gapi/client_secret');
}

sub get_refresh_token_from_storage {
    my ( $self, $user ) = @_;
    warn "get_refresh_token_from_storage(" . $user . ")" if $self->debug;
    return $tokensfile->get( 'gapi/tokens/' . $user . '/refresh_token' );
}

sub get_access_token_from_storage {
    my ( $self, $user ) = @_;
    $tokensfile->get( 'gapi/tokens/' . $user . '/access_token' );
}

sub set_access_token_to_storage {
    my ( $self, $user, $token ) = @_;
    $tokensfile->set( 'gapi/tokens/' . $user . '/access_token', $token );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Moo::Google::AuthStorage::ConfigJSON - Specific methods to fetch tokens from JSON data sources

=head1 VERSION

version 0.03

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
