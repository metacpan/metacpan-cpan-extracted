package Passwd::Keyring::Gnome;

use warnings;
use strict;
#use parent 'Keyring';

use Carp qw(croak);

require DynaLoader;
use base 'DynaLoader';

=head1 NAME

Passwd::Keyring::Gnome - Password storage implementation based on GNOME Keyring.

=head1 VERSION

Version 0.3003

=cut

our $VERSION = '0.3003';

bootstrap Passwd::Keyring::Gnome $VERSION;

=head1 SYNOPSIS

Gnome Keyring based implementation of L<Keyring>. Provide secure
storage for passwords and similar sensitive data.

    use Passwd::Keyring::Gnome;

    my $keyring = Passwd::Keyring::Gnome->new(
         app=>"blahblah scraper",
         group=>"Johnny web scrapers",
    );

    my $username = "John";  # or get from .ini, or from .argv...

    my $password = $keyring->get_password($username, "blahblah.com");
    unless( $password ) {
        $password = <somehow interactively prompt for password>;

        # securely save password for future use
        $keyring->set_password($username, $password, "blahblah.com");
    }

    login_somewhere_using($username, $password);
    if( password_was_wrong ) {
        $keyring->clear_password($username, "blahblah.com");
    }

Note: see L<Passwd::Keyring::Auto::KeyringAPI> for detailed comments
on keyring method semantics (this document is installed with
C<Passwd::Keyring::Auto> package).

=head1 SUBROUTINES/METHODS

=head2 new(app=>'app name', group=>'passwords folder')

Initializes the processing. Croaks if gnome keyring does not 
seem to be available.

Handled named parameters: 

- app - symbolic application name (not used at the moment, but can be
  used in future as comment and in prompts, so set sensibly)

- group - name for the password group (will be visible in seahorse so
  can be used by end user to manage passwords, different group means
  different password set, a few apps may share the same group if they
  need to use the same passwords set)

=cut

sub new {
    my ($cls, %opts) = @_;
    my $self = {
        app => $opts{app} || 'Passwd::Keyring',
        group => $opts{group} || 'Passwd::Keyring unclassified passwords',
    };
    bless $self;

    # TODO: catch and rethrow exceptions
    my $name = Passwd::Keyring::Gnome::_get_default_keyring_name();
    croak ("Gnome Keyring seems unavailable (failed to read default keyring name)") unless $name;

    return $self;
}

=head2 set_password(username, password, realm)

Sets (stores) password identified by given realm for given user 

=cut

sub set_password {
    my ($self, $user_name, $user_password, $realm) = @_;
    Passwd::Keyring::Gnome::_set_password(
        $user_name, $user_password,
        $realm, $self->{group},
        "$self->{group}/$realm/$user_name (by $self->{app})");
}

=head2 get_password($user_name, $realm)

Reads previously stored password for given user in given app.
If such password can not be found, returns undef.

=cut

sub get_password {
    my ($self, $user_name, $realm) = @_;
    my $pwd = Passwd::Keyring::Gnome::_get_password(
        $user_name, $realm, $self->{group});
    #return undef if (!defined($pwd)) or $pwd eq "";
    return $pwd;
}

=head2 clear_password($user_name, $realm)

Removes given password (if present)

Returns how many passwords actually were removed 

=cut

sub clear_password {
    my ($self, $user_name, $realm) = @_;
    return Passwd::Keyring::Gnome::_clear_password(
        $user_name, $realm, $self->{group});
}

=head2 is_persistent

Returns info, whether this keyring actually saves passwords persistently.

(true in this case)

=cut

sub is_persistent {
    my ($self) = @_;
    return 1;
}


=head1 AUTHOR

Marcin Kasperski

=head1 BUGS

Please report any bugs or feature requests to 
issue tracker at L<https://bitbucket.org/Mekk/perl-keyring-gnome>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Passwd::Keyring::Gnome

You can also look for information at:

L<http://search.cpan.org/~mekk/Passwd-Keyring-Gnome/>

Source code is tracked at:

L<https://bitbucket.org/Mekk/perl-keyring-gnome>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Marcin Kasperski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


1; # End of Passwd::Keyring::Gnome

