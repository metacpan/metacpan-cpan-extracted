# NAME

Passwd::Keyring::Secret - Password storage implementation using the GObject-based Secret library.

# VERSION

Version 1.01

# SYNOPSIS

`Passwd::Keyring` compliant implementation that is using the
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

**Note:** see [Passwd::Keyring::Auto::KeyringAPI](https://metacpan.org/pod/Passwd%3A%3AKeyring%3A%3AAuto%3A%3AKeyringAPI) for detailed comments
on keyring method semantics (this document is installed with the
[Passwd::Keyring::Auto](https://metacpan.org/pod/Passwd%3A%3AKeyring%3A%3AAuto) package).

# METHODS

## new(app => 'app name', group => 'passwords folder', ...)

Initializes the processing. Croaks if keyring for a given alias name
or the Secret service itself does not seem to be available.

Handled named parameters:

\- app - symbolic application name (not used at the moment, but may be
  used as comment and in prompts in the future, so set sensibly)

\- group - name for the password group (will be visible in Seahorse, so
  can be used by the user to manage passwords; different group means
  different password set; a few apps may share the same group if they
  need to use the same password set)

\- alias (_optional_) - alias name of the keyring (the default keyring
  will be used if undefined; use `"session"` to store passwords in the
  session keyring which doesn't get stored across login sessions)

## set\_password($username, $password, $realm)

Stores password identified by given realm for given user.

## get\_password($username, $realm)

Looks up previously stored password for given user and given realm.
Returns `undef` if such a password could not be found.

## clear\_password($username, $realm)

Removes password matching given user and given realm (if present).
Returns whether a password was removed.

## is\_persistent()

Returns whether this keyring actually saves passwords persistently
(true unless initial parameter `alias` was set to `"session"`).

# INSTALLATION

Run the following commands to install this module:

    ./Build.PL
    ./Build
    ./Build test
    ./Build install

# SUPPORT

After installation, you can find the documentation for this module
using the perldoc command:

    perldoc Passwd::Keyring::Secret

You can also look for information at

[https://search.cpan.org/~uhle/Passwd-Keyring-Secret/](https://search.cpan.org/~uhle/Passwd-Keyring-Secret/).

The source code is tracked at

[https://gitlab.com/uhle/Passwd-Keyring-Secret](https://gitlab.com/uhle/Passwd-Keyring-Secret).

# BUGS

Please report any bugs or feature requests to the issue tracker at
[https://gitlab.com/uhle/Passwd-Keyring-Secret/-/issues](https://gitlab.com/uhle/Passwd-Keyring-Secret/-/issues).

# AUTHOR

Thomas Uhle <uhle@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (c) 2020-2021 Thomas Uhle. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0 as published by the Perl
Foundation.

See [https://www.perlfoundation.org/artistic-license-20.html](https://www.perlfoundation.org/artistic-license-20.html) for more
information.
