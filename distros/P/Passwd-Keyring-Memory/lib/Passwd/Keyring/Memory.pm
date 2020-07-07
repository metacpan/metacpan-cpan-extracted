package Passwd::Keyring::Memory;

use 5.006;
use strict;
use warnings;

=head1 NAME

Passwd::Keyring::Memory - fallback keyring for environments
where no better keyring is available.

=head1 VERSION

Version 1.0000

=cut

our $VERSION = '1.0000';

=head1 SYNOPSIS

    use Passwd::Keyring::Memory;

    my $keyring = Passwd::Keyring::Memory->new();

    $keyring->set_password("John", "verysecret", "my-realm");

    my $password = $keyring->get_password("John", "my-realm");

    $keyring->clear_password("John", "my-realm");

Note: see L<Passwd::Keyring::Auto::KeyringAPI> for detailed comments on
keyring method semantics (this document is installed with
Passwd::Keyring::Auto package).


=head1 SUBROUTINES/METHODS

=head2 new

Initializes the processing.

=cut

# Global map of folders to simulate case of a few ring objects working on the same data.
# (could be state variable in new, but let's not limit perl versions)
my $_passwords = {}; 

sub new {
    my ($cls, %args) = @_;
    my $self = {
        app => $args{app} || "Passwd::Keyring::Memory",
        group => $args{group} || "Passwd::Keyring::Memory default passwords",
    };
    my $group = $self->{group};
    unless(exists $_passwords->{$group}) {
        $_passwords->{$group} = {};
    }

    $self->{_passwords} = $_passwords->{$group}; # key → password

    bless $self, $cls;
    return $self;
}

sub _password_key {
    my ($self, $realm, $user_name) = @_;
    return join("||", $realm, $user_name);
}

=head2 set_password(username, password, realm)

Sets (stores) password identified by given realm for given user 

=cut

sub set_password {
    my ($self, $user_name, $user_password, $realm) = @_;
    my $key = $self->_password_key($realm, $user_name);
    $self->{_passwords}->{ $key } = $user_password;

    #use Data::Dumper; print STDERR Dumper($_passwords);
}

=head2 get_password($user_name, $realm)

Reads previously stored password for given user in given app.
If such password can not be found, returns undef.

=cut

sub get_password {
    my ($self, $user_name, $realm) = @_;
    my $key = $self->_password_key($realm, $user_name);

    if( exists $self->{_passwords}->{$key} ) {
        return $self->{_passwords}->{$key};
    } else {
        return undef;
    }
}

=head2 clear_password($user_name, $realm)

Removes given password (if present)

=cut

sub clear_password {
    my ($self, $user_name, $realm) = @_;

    my $key = $self->_password_key($realm, $user_name);

    #use Data::Dumper; print STDERR Dumper($_passwords);

    if( exists $self->{_passwords}->{$key} ) {
        delete $self->{_passwords}->{$key};
        return 1;
    } else {
        return 0;
    }
}

=head2 is_persistent

Returns info, whether this keyring actually saves passwords persistently.

(false in this case)

=cut

sub is_persistent {
    my ($self) = @_;
    return 0;
}


=head1 AUTHOR

Marcin Kasperski

=head1 BUGS

Please report any bugs or feature requests to
issue tracker at L<https://helixteamhub.cloud/mekk/projects/perl/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Passwd::Keyring::Memory

You can also look for information at:

L<http://search.cpan.org/~mekk/Passwd-Keyring-Memory/>

Source code is tracked at:

L<https://helixteamhub.cloud/mekk/projects/perl/repositories/keyring-memory>

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2020 Marcin Kasperski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


1; # End of Passwd::Keyring::Memory
