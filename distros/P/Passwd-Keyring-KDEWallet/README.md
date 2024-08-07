# NAME

Passwd::Keyring::KDEWallet - Password storage implementation based on KDE Wallet.

# VERSION

Version 1.0001

# SYNOPSIS

KDE Wallet based implementation of [Passwd::Keyring](https://metacpan.org/pod/Passwd%3A%3AKeyring).

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

Note: see [Passwd::Keyring::Auto::KeyringAPI](https://metacpan.org/pod/Passwd%3A%3AKeyring%3A%3AAuto%3A%3AKeyringAPI) for detailed comments
on keyring method semantics (this document is installed with
`Passwd::Keyring::Auto` package).

# SUBROUTINES/METHODS

## new

    Passwd::Keyring::KDEWallet->new(
        app=>'app name', group=>'passwords folder');

    Passwd::Keyring::KDEWallet->new(
        app=>'app name', group=>'passwords folder',
        start_kwalletd_if_missing=>1);

Initializes the processing. Croaks if kwallet (or d-bus, or anything
needed) does not seem to be available.

Handled named parameters:

- app

    symbolic application name (used in "Application .... is asking
    to open the wallet" KDE Wallet prompt)

- group

    name for the password group (used as KDE Wallet folder name)

- dont\_start\_daemon

    by default, in case kwalletd service is missing, we try to start
    it, this option disables this behaviour

- kwalletd\_path

    path to kwalletd binary, used in case we try starting it. Default:
    `kwalletd` (relative path means searching in `PATH`).

## set\_password(username, password, realm)

Sets (stores) password identified by given realm for given user

## get\_password($user\_name, $realm)

Reads previously stored password for given user in given app.
If such password can not be found, returns undef.

## clear\_password($user\_name, $realm)

Removes given password (if present)

## is\_persistent

Returns info, whether this keyring actually saves passwords persistently.

(true in this case)

# AUTHOR

Marcin Kasperski

Approach inspired by [http://www.perlmonks.org/?node\_id=869620](http://www.perlmonks.org/?node_id=869620).

# BUGS

Please report any bugs or feature requests to
issue tracker at [https://helixteamhub.cloud/mekk/projects/perl/issues](https://helixteamhub.cloud/mekk/projects/perl/issues).

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Passwd::Keyring::KDEWallet

You can also look for information at:

[http://search.cpan.org/~mekk/Passwd-Keyring-KDEWallet/](http://search.cpan.org/~mekk/Passwd-Keyring-KDEWallet/)

Source code is tracked at:

[https://helixteamhub.cloud/mekk/projects/perl/repositories/keyring-kdewallet](https://helixteamhub.cloud/mekk/projects/perl/repositories/keyring-kdewallet)

# LICENSE AND COPYRIGHT

Copyright 2012-2020 Marcin Kasperski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
