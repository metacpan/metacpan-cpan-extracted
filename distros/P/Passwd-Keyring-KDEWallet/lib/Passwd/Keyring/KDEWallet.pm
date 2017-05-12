package Passwd::Keyring::KDEWallet;

use warnings;
use strict;
#use parent 'Keyring';
use Net::DBus;
use Try::Tiny;
use Proc::SyncExec qw/sync_exec/;
use Carp;

=head1 NAME

Passwd::Keyring::KDEWallet - Password storage implementation based on KDE Wallet.

=head1 VERSION

Version 0.60

=cut

our $VERSION = '0.60';

our $APP_NAME = "Passwd::Keyring";
our $FOLDER_NAME = "Perl-Passwd-Keyring";

# Max time we wait for kwalletd
our $KWALLETD_START_TIMEOUT = 2.0;
# Frequency of checks
our $KWALLETD_CHECK_FREQUENCY = 0.1;

=head1 SYNOPSIS

KDE Wallet based implementation of L<Passwd::Keyring>.

    use Passwd::Keyring::KDEWallet;

    my $keyring = Passwd::Keyring::KDEWallet->new(
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

=head2 new

    Passwd::Keyring::KDEWallet->new(
        app=>'app name', group=>'passwords folder');

    Passwd::Keyring::KDEWallet->new(
        app=>'app name', group=>'passwords folder',
        start_kwalletd_if_missing=>1);

Initializes the processing. Croaks if kwallet (or d-bus, or anything
needed) does not seem to be available.

Handled named parameters:

=over 4

=item app

symbolic application name (used in "Application .... is asking
to open the wallet" KDE Wallet prompt)

=item group

name for the password group (used as KDE Wallet folder name)

=item dont_start_daemon

by default, in case kwalletd service is missing, we try to start
it, this option disables this behaviour

=item kwalletd_path

path to kwalletd binary, used in case we try starting it. Default:
C<kwalletd> (relative path means searching in C<PATH>).

=back

=cut

sub new {
    my ($cls, %args) = @_;

    my $self = {};
    $self->{app} = $args{app} || 'Passwd::Keyring::KDEWallet';
    $self->{group} = $args{group} || 'Passwd::Keyring::default';
    $self->{dont_start_daemon} = $args{dont_start_daemon} || '';
    $self->{kwalletd_path} = $args{kwalletd_path} || 'kwalletd';
    bless $self, $cls;

    #$self->{bus} = Net::DBus->find()
    $self->{bus} = Net::DBus->session()
      or croak("KWallet not available (can't access DBus)");

    $self->_init_kwallet();

    $self->_open_if_not_open();

    unless($self->{kwallet}->hasFolder($self->{handle}, $self->{group}, $self->{app})) {
        $self->{kwallet}->createFolder($self->{handle}, $self->{group}, $self->{app})
          or croak("Failed to create or access $self->{group} folder (app $self->{app}).\nDid you reject prompt to open the wallet?\n");
    }

    return $self;
}

# Called from the constructor, setups self->{kwallet} attribute (top level
# service object)
sub _init_kwallet {
    my $self = shift;

    # get_service may fail by itself, if kwalletd is down, in some
    # cases it fails with
    #
    # org.freedesktop.DBus.Error.ServiceUnknown: The name org.kde.kwalletd was not provided by any .service files

    my $kwallet_svc;
    my $error;
    try {
        $kwallet_svc = $self->{bus}->get_service('org.kde.kwalletd');
    } catch {
        $error = $_;
        chomp($error);
    };

    unless($kwallet_svc) {
        # Mayhaps we are allowed to start kwalletd?
        if(! $self->{dont_start_daemon}
             && $error =~ /^org\.freedesktop\.DBus\.Error\.ServiceUnknown:/) {
            print STDERR "KWallet service not available, attempting to start $self->{kwalletd_path}\n";
            # spawn kwalletd
            my $pid = sync_exec
                sub {
                    # Without this prove (tests) hang
                    close (STDOUT);
                    return 1;
                },
                $self->{kwalletd_path};
            unless($pid) {
                croak "KWallet not available (not installed or not started)\nand attempt to start it failed\nOriginal error:\n$error" . "Attempted command:\n" . $self->{kwalletd_path} . "\nCommand failure: $!\n";
            };
            my $error2;
            my $DEADLINE = time() + $KWALLETD_START_TIMEOUT;
            # while($proc->alive && time() <= $DEADLINE) {
            while(time() <= $DEADLINE) {
                try {
                    $kwallet_svc = $self->{bus}->get_service('org.kde.kwalletd');
                } catch {
                    $error2 = $_;
                    chomp($error2);
                    # warn "Still not available: $@\n";
                };
                last if $kwallet_svc;
                sleep($KWALLETD_CHECK_FREQUENCY);
            }
            unless($kwallet_svc) {
                croak "KWallet not available (not installed or not started),\nand attempt to start it did not help\nFirst error:\n$error\nLast error:\n$error2\nAttempted command: $self->{kwalletd_path}\n";
            }
        } else {
            croak "KWallet not available (not installed or not started),\nand we are forbidden to start it ourselves.\nOriginal error:\n$error\n";
        }
    }

    $self->{kwallet} = $kwallet_svc->get_object(
        '/modules/kwalletd', 'org.kde.KWallet')
      or croak("Kwallet not available (can't find wallet)");
}

sub _open_if_not_open {
    my $self = shift;

    if($self->{handle}) {
        if($self->{kwallet}->isOpen($self->{handle})) {
            return;
        }
    }
    my $net_wallet = $self->{kwallet}->networkWallet()
      or croak("Kwallet not available (can't access network wallet");
    $self->{handle} = $self->{kwallet}->open($net_wallet, 0, $self->{app})
      or croak("Failed to open the KDE wallet");
}

=head2 set_password(username, password, realm)

Sets (stores) password identified by given realm for given user

=cut

sub set_password {
    my ($self, $user_name, $user_password, $realm) = @_;
    $self->_open_if_not_open();
    my $status = $self->{kwallet}->writePassword(
        $self->{handle}, $self->{group}, "$realm || $user_name", $user_password, $self->{app});
    if($status) { # non-zero means failure
        croak("Failed to save the password (status $status, user name $user_name, realm $realm, handle $self->{handle}, group $self->{group})");
    }
}

=head2 get_password($user_name, $realm)

Reads previously stored password for given user in given app.
If such password can not be found, returns undef.

=cut

sub get_password {
    my ($self, $user_name, $realm) = @_;
    $self->_open_if_not_open();
    my $reply = $self->{kwallet}->readPassword(
        $self->{handle}, $self->{group}, "$realm || $user_name", $self->{app});
    # In case of missing passsword we get empty string. I do not know
    # whether it is possible to distinguish missing password from empty password,
    # but empty passwords are exotic enough to ignore.
    return undef if ! defined($reply) or $reply eq '';
    return $reply;
}

=head2 clear_password($user_name, $realm)

Removes given password (if present)

=cut

sub clear_password {
    my ($self, $user_name, $realm) = @_;
    $self->_open_if_not_open();
    my $status = $self->{kwallet}->removeEntry(
        $self->{handle}, $self->{group}, "$realm || $user_name", $self->{app});
    if($status == 0) {
        return 1;
    } else {
        # TODO: classify failures
        return 0;
    }
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

Approach inspired by L<http://www.perlmonks.org/?node_id=869620>.

=head1 BUGS

Please report any bugs or feature requests to
issue tracker at L<https://bitbucket.org/Mekk/perl-keyring-kdewallet>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Passwd::Keyring::KDEWallet

You can also look for information at:

L<http://search.cpan.org/~mekk/Passwd-Keyring-KDEWallet/>

Source code is tracked at:

L<https://bitbucket.org/Mekk/perl-keyring-kdewallet>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Marcin Kasperski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


1; # End of Passwd::Keyring::KDEWallet
