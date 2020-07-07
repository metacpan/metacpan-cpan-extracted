# NAME

Passwd::Keyring::Memory - fallback keyring for environments
where no better keyring is available.

# VERSION

Version 1.0000

# SYNOPSIS

    use Passwd::Keyring::Memory;

    my $keyring = Passwd::Keyring::Memory->new();

    $keyring->set_password("John", "verysecret", "my-realm");

    my $password = $keyring->get_password("John", "my-realm");

    $keyring->clear_password("John", "my-realm");

Note: see [Passwd::Keyring::Auto::KeyringAPI](https://metacpan.org/pod/Passwd%3A%3AKeyring%3A%3AAuto%3A%3AKeyringAPI) for detailed comments on
keyring method semantics (this document is installed with
Passwd::Keyring::Auto package).

# SUBROUTINES/METHODS

## new

Initializes the processing.

## set\_password(username, password, realm)

Sets (stores) password identified by given realm for given user 

## get\_password($user\_name, $realm)

Reads previously stored password for given user in given app.
If such password can not be found, returns undef.

## clear\_password($user\_name, $realm)

Removes given password (if present)

## is\_persistent

Returns info, whether this keyring actually saves passwords persistently.

(false in this case)

# AUTHOR

Marcin Kasperski

# BUGS

Please report any bugs or feature requests to
issue tracker at [https://helixteamhub.cloud/mekk/projects/perl/issues](https://helixteamhub.cloud/mekk/projects/perl/issues).

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Passwd::Keyring::Memory

You can also look for information at:

[http://search.cpan.org/~mekk/Passwd-Keyring-Memory/](http://search.cpan.org/~mekk/Passwd-Keyring-Memory/)

Source code is tracked at:

[https://helixteamhub.cloud/mekk/projects/perl/repositories/keyring-memory](https://helixteamhub.cloud/mekk/projects/perl/repositories/keyring-memory)

# LICENSE AND COPYRIGHT

Copyright 2012-2020 Marcin Kasperski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
