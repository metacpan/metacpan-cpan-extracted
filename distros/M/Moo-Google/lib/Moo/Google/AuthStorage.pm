package Moo::Google::AuthStorage;
$Moo::Google::AuthStorage::VERSION = '0.02';

# ABSTRACT: Provide universal methods to fetch tokens from different types of data sources. Default is jsonfile

use Moo;

use Moo::Google::AuthStorage::ConfigJSON;
use Moo::Google::AuthStorage::DBI;
use Moo::Google::AuthStorage::MongoDB;

has 'storage' =>
  ( is => 'rw', default => sub { Moo::Google::AuthStorage::ConfigJSON->new } )
  ;    # by default
has 'is_set' => ( is => 'rw', default => 0 );


sub setup {
    my ( $self, $params ) = @_;
    if ( $params->{type} eq 'jsonfile' ) {
        $self->storage->pathToTokensFile( $params->{path} );
        $self->storage->setup;
        $self->is_set(1);
    }
    elsif ( $params->{type} eq 'dbi' ) {
        $self->storage( Moo::Google::AuthStorage::DBI->new );
        $self->storage->dbi( $params->{path} );
        $self->storage->setup;
        $self->is_set(1);
    }
    elsif ( $params->{type} eq 'mongo' ) {
        $self->storage( Moo::Google::AuthStorage::MongoDB->new );
        $self->storage->mongo( $params->{path} );
        $self->storage->setup;
        $self->is_set(1);
    }
    else {
        die "Unknown storage type. Allowed types are jsonfile, dbi and mongo";
    }
}


sub file_exists {
    my ( $self, $filename ) = @_;
    if ( -e $filename ) {
        return 1;
    }
    else {
        return 0;
    }
}

### Below are list of methods that each Storage subclass must provide


sub get_credentials_for_refresh {
    my ( $self, $user ) = @_;
    $self->storage->get_credentials_for_refresh($user);
}

sub get_access_token_from_storage {
    my ( $self, $user ) = @_;
    $self->storage->get_access_token_from_storage($user);
}

sub set_access_token_to_storage {
    my ( $self, $user, $access_token ) = @_;
    $self->storage->set_access_token_to_storage( $user, $access_token );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Moo::Google::AuthStorage - Provide universal methods to fetch tokens from different types of data sources. Default is jsonfile

=head1 VERSION

version 0.02

=head1 METHODS

=head2 setup

Set appropriate storage

  my $auth_storage = Moo::Google::AuthStorage->new;
  $auth_storage->setup; # by default will be config.json
  $auth_storage->setup({type => 'jsonfile', path => '/abs_path' });
  $auth_storage->setup({ type => 'dbi', path => 'DBI object' });
  $auth_storage->setup({ type => 'mongodb', path => 'details' });`

=head2 file_exists

Check if file exists in a root catalog.
Function is used to speed up unit testing.

=head2 get_credentials_for_refresh

Return all parameters that is needed for Mojo::Google::AutoTokenRefresh::refresh_access_token() function: client_id, client_secret and refresh_token

$c->get_credentials_for_refresh('examplemail@gmail.com')

This method must have all subclasses of Moo::Google::AuthStorage

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
