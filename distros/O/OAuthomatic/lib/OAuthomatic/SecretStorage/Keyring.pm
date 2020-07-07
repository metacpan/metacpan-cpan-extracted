package OAuthomatic::SecretStorage::Keyring;
# ABSTRACT: Save tokens in secure storage, using L<Passwd::Keyring::Auto>

use Moose;
use namespace::sweep;
use MooseX::AttributeShortcuts;
use Passwd::Keyring::Auto qw(get_keyring);
use Const::Fast;


has 'config' => (
    is => 'ro', isa => 'OAuthomatic::Config', required => 1,
    handles => [
        'app_name',
        'password_group',
        'debug',
       ]);


has 'server' => (
    is => 'ro', isa => 'OAuthomatic::Server', required => 1,
    handles => [
        'site_name',
       ]);


has 'keyring' => (
    is => 'lazy', trigger => sub {
        my ($self, $keyring, $old_val) = @_;
        unless($keyring->is_persistent) {
            OAuthomatic::Error::Generic->throw(
                ident => "Attempt to use non-persistent keyring",
                extra => "Suggested backend is non-persistent: ") . ref($keyring) . ".\n";
        }
    });

sub _build_keyring {
    my $self = shift;
    my $password_group = $self->password_group;
    my $app_name = $self->app_name;
    OAuthomatic::Error::Generic->throw(
        ident => "Bad parameter",
        extra => "You must specify password_group and app_name (or specify keyring)")
      unless ($password_group && $app_name);
    my $keyring = get_keyring(group => $password_group,
                              app => $app_name);
    unless($keyring->is_persistent) {
        OAuthomatic::Error::Generic->throw(
            ident => "Bad keyring configuration",
            extra => "Got non-persistent keyring backend (") . ref($keyring) . "). Reconfigure Passwd::Keyring::Auto (and maybe install some Passwd::Keyring::<backend>) to use something non-volatile.\n";
    }
    if($self->debug) {
        print "[OAuthomatic] Constructed keyring. Type: ", ref($keyring), ", app: $app_name, group: $password_group\n";
    }
    return $keyring;
}

const my $CLIENT_MAP_KEY => "oauthomatic_client_key";

sub get_client_cred {
    my ($self) = @_;

    my $client_key = $self->keyring->get_password($CLIENT_MAP_KEY, $self->site_name);
    return unless $client_key;
    my $client_secret = $self->keyring->get_password($client_key, $self->site_name);
    return unless $client_secret;
    return OAuthomatic::Types::ClientCred->new(
        key => $client_key,
        secret => $client_secret,
    );
}

sub save_client_cred {
    my ($self, $client) = @_;

    $self->keyring->set_password($client->key, $client->secret, $self->site_name);
    $self->keyring->set_password($CLIENT_MAP_KEY, $client->key, $self->site_name);

    return;
}

sub clear_client_cred {
    my ($self) = @_;

    # FIXME: give an option of clearing only mapping but keeping key in storage?

    my $client_key = $self->keyring->get_password($CLIENT_MAP_KEY, $self->site_name);
    return unless $client_key;

    $self->keyring->clear_password($client_key, $self->site_name);
    $self->keyring->clear_password($CLIENT_MAP_KEY, $self->site_name);

    return;
}

const my $TOKEN_MAP_KEY => "oauthomatic_token";

sub get_token_cred {
    my ($self) = @_;

    my $token = $self->keyring->get_password($TOKEN_MAP_KEY, $self->site_name);
    return unless $token;
    my $token_secret = $self->keyring->get_password($token, $self->site_name);
    return unless $token_secret;
    return OAuthomatic::Types::TokenCred->new(
        token => $token,
        secret => $token_secret,
    );
}

sub save_token_cred {
    my ($self, $access) = @_;

    $self->keyring->set_password($access->token, $access->secret, $self->site_name);
    $self->keyring->set_password($TOKEN_MAP_KEY, $access->token, $self->site_name);

    return;
}

sub clear_token_cred {
    my ($self) = @_;

    my $token = $self->keyring->get_password($TOKEN_MAP_KEY, $self->site_name);
    return unless $token;

    $self->keyring->clear_password($token, $self->site_name);
    $self->keyring->clear_password($TOKEN_MAP_KEY, $self->site_name);

    return;
}

with 'OAuthomatic::SecretStorage';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuthomatic::SecretStorage::Keyring - Save tokens in secure storage, using L<Passwd::Keyring::Auto>

=head1 VERSION

version 0.0202

=head1 DESCRIPTION

Implements L<OAuthomatic::SecretStorage> interface using
L<Passwd::Keyring::Auto> (what usually means saving data in Gnome
Keyring, KDE Wallet, Windows Vault or similar secure storage).

Note that tokens are saved in slightly specific way. Whenever client
key is saved, we create two entries in keyring:

    username: client_key
    password: client_secret

and

    username: "oauthomatic_client_key"
    password: client_key

The former is natural. The latter helps find what current key is
(this record is not very secret but it is easier to keep it too
than invent second configuration backend).

Access tokens are treated similarly:

    username: token
    password: token_secret

and

    username: "oauthomatic_token"
    password: token

=head1 ATTRIBUTES

=head2 config

L<OAuthomatic::Config> object used to bundle various configuration params.

=head2 server

L<OAuthomatic::Server> object used to bundle server-related configuration params.

=head2 keyring

Actual password backend in use.

Usually initialized automatically, guessing best possible password
backend (according to L<Passwd::Keyring::Auto> selection and using
it's C<app_name> and C<password_group> attributes), but can be
specified if application prefers to use sth. specific:

    keyring => Passwd::Keyring::KDEWallet->new(...))

=head1 AUTHOR

Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Marcin Kasperski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
