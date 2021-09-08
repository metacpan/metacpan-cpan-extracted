package Passwd::Keyring::Secret;

use strict;
use warnings;

use Carp qw(carp croak);
use Glib::Object::Introspection;

Glib::Object::Introspection->setup(
    basename => 'Secret',
    version => '1',
    package => 'Secret',
    class_static_methods => [
        'Secret::Collection::for_alias_sync',
        'Secret::Service::get_sync',
    ]
);

=head1 NAME

Passwd::Keyring::Secret - Password storage implementation using the GObject-based Secret library.

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

C<Passwd::Keyring> compliant implementation that is using the
GObject-based Secret library to provide secure storage for passwords
and similar sensitive data.

    use Passwd::Keyring::Secret;

    my $keyring = Passwd::Keyring::Secret->new(
        app => "blahblah scraper",
        group => "Johnny web scrapers"
    );

    my $username = "John";  # or get from .ini, or from .argv ...

    my $password = $keyring->get_password($username, "blahblah.com");
    unless ($password)
    {
        $password = <somehow interactively prompt for password>;

        # securely save password for future use
        $keyring->set_password($username, $password, "blahblah.com");
    }

    login_somewhere_using($username, $password);
    if (password_was_wrong)
    {
        $keyring->clear_password($username, "blahblah.com");
    }

B<Note:> see L<Passwd::Keyring::Auto::KeyringAPI> for detailed comments
on keyring method semantics (this document is installed with the
L<Passwd::Keyring::Auto> package).

=head1 METHODS

=head2 new(app => 'app name', group => 'passwords folder', ...)

Initializes the processing. Croaks if keyring for a given alias name
or the Secret service itself does not seem to be available.

Handled named parameters:

- app - symbolic application name (not used at the moment, but may be
  used as comment and in prompts in the future, so set sensibly)

- group - name for the password group (will be visible in Seahorse, so
  can be used by the user to manage passwords; different group means
  different password set; a few apps may share the same group if they
  need to use the same password set)

- alias (I<optional>) - alias name of the keyring (the default keyring
  will be used if undefined; use C<"session"> to store passwords in the
  session keyring which doesn't get stored across login sessions)

=cut

sub new
{
    my ($ref, %params) = @_;
    my $class = ref($ref) || $ref;
    my $self = (ref($ref) eq '') ? {
        app => $params{app} || 'Passwd::Keyring',
        group => $params{group} || 'Passwd::Keyring passwords',
        alias => $params{alias} || 'default'
    } : {
        app => $params{app} || $ref->{app},
        group => $params{group} || $ref->{group},
        alias => $params{alias} || $ref->{alias}
    };
    bless($self, $class);

    $self->{schema} = undef;

    my $service_proxy = Secret::Service->get_sync('open-session');
    my $collection = Secret::Collection->for_alias_sync($service_proxy, $self->{alias}, 'none');
    croak "Secret store seems to be unavailable (failed to get $self->{alias} keyring)" unless $collection;
    $self->{_service_proxy} = $service_proxy;

    return $self;
}

=head2 set_password($username, $password, $realm)

Stores password identified by given realm for given user.

=cut

sub set_password
{
    my ($self, $user_name, $user_password, $realm) = @_;
    Secret::password_store_sync(
        $self->{schema},
        { group => $self->{group}, realm => $realm, user => $user_name },
        $self->{alias},
        "$self->{group}/$realm/$user_name (by $self->{app})",
        $user_password
    ) or croak "Failed to set password";
}

=head2 get_password($username, $realm)

Looks up previously stored password for given user and given realm.
Returns C<undef> if such a password could not be found.

=cut

sub get_password
{
    my ($self, $user_name, $realm) = @_;
    my $pwd = Secret::password_lookup_sync(
        $self->{schema},
        { group => $self->{group}, realm => $realm, user => $user_name }
    );
    #carp "Cannot find a password" unless defined $pwd;
    return $pwd;
}

=head2 clear_password($username, $realm)

Removes password matching given user and given realm (if present).
Returns whether a password was removed.

=cut

sub clear_password
{
    my ($self, $user_name, $realm) = @_;
    return Secret::password_clear_sync(
        $self->{schema},
        { group => $self->{group}, realm => $realm, user => $user_name }
    );
}

=head2 is_persistent()

Returns whether this keyring actually saves passwords persistently
(true unless initial parameter C<alias> was set to C<"session">).

=cut

sub is_persistent
{
    my ($self) = @_;
    return $self->{alias} ne 'session';
}

=head1 INSTALLATION

Run the following commands to install this module:

    ./Build.PL
    ./Build
    ./Build test
    ./Build install

=head1 SUPPORT

After installation, you can find the documentation for this module
using the perldoc command:

    perldoc Passwd::Keyring::Secret

You can also look for information at

L<https://search.cpan.org/~uhle/Passwd-Keyring-Secret/>.

The source code is tracked at

L<https://gitlab.com/uhle/Passwd-Keyring-Secret>.

=head1 BUGS

Please report any bugs or feature requests to the issue tracker at
L<https://gitlab.com/uhle/Passwd-Keyring-Secret/-/issues>.

=head1 AUTHOR

Thomas Uhle <uhle@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2020-2021 Thomas Uhle. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0 as published by the Perl
Foundation.

See L<https://www.perlfoundation.org/artistic-license-20.html> for more
information.

=cut

1;

__END__
