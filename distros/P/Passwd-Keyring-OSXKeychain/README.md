# NAME

Passwd::Keyring::OSXKeychain - Password storage implementation based on OSX/Keychain.

# VERSION

Version 0.4000

# WARNING

I do not have Mac. I wrote the library mimicking actions
of some python libraries and tested using mocks, but help
of somebody able to test it on true Mac is really needed.

# SYNOPSIS

OSXKeychain Keyring based implementation of [Keyring](https://metacpan.org/pod/Keyring). Provide secure
storage for passwords and similar sensitive data.

    use Passwd::Keyring::OSXKeychain;

    my $keyring = Passwd::Keyring::OSXKeychain->new(
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

## new(app=>'app name', group=>'passwords folder')

Initializes the processing. Croaks if osxkeychain keyring does not
seem to be available.

Handled named parameters:

\- app - symbolic application name (not used at the moment, but can be
  used in future as comment and in prompts, so set sensibly)

\- group - name for the password group (will be visible in seahorse so
  can be used by end user to manage passwords, different group means
  different password set, a few apps may share the same group if they
  need to use the same passwords set)

(OSXKeychain-specific)

\- security\_prog - location of security program (/usr/bin/security by
  default, possibility to overwrite is mostly needed for testing)

\- keychain - keychain to use (if not default)

## set\_password(username, password, realm)

Sets (stores) password identified by given realm for given user

## get\_password($user\_name, $realm)

Reads previously stored password for given user in given app.
If such password can not be found, returns undef.

## clear\_password($user\_name, $realm)

Removes given password (if present)

Returns how many passwords actually were removed

## is\_persistent

Returns info, whether this keyring actually saves passwords persistently.

(true in this case)

# AUTHOR

Marcin Kasperski

# BUGS

Please report any bugs or feature requests to
issue tracker at [https://helixteamhub.cloud/mekk/projects/perl/issues](https://helixteamhub.cloud/mekk/projects/perl/issues).

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Passwd::Keyring::OSXKeychain

You can also look for information at:

[http://search.cpan.org/~mekk/Passwd-Keyring-OSXKeychain/](http://search.cpan.org/~mekk/Passwd-Keyring-OSXKeychain/)

Source code is tracked at:

[https://helixteamhub.cloud/mekk/projects/perl/repositories/keyring-osxkeychain](https://helixteamhub.cloud/mekk/projects/perl/repositories/keyring-osxkeychain)

# LICENSE AND COPYRIGHT

Copyright 2012 Marcin Kasperski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
