# NAME

Passwd::Keyring::Auto - interface to secure password storage(s)

# VERSION

Version 1.0000

# SYNOPSIS

Passwd::Keyring is about securely preserving passwords and other
sensitive data (for example API keys, OAuth tokens etc) in backends
like Gnome Keyring, KDE Wallet, OSX/Keychain etc.

While modules like Passwd::Keyring::Gnome handle specific backends,
Passwd::Keyring::Auto tries to pick the best backend available,
considering the current desktop environment, program options, and user
configuration.

    use Passwd::Keyring::Auto;  # get_keyring

    my $keyring = get_keyring(app=>"My super scraper", group=>"Social passwords");

    my $username = "someuser";
    my $password = $keyring->get_password($username, "mylostspace.com");
    unless($password) {
        # ... somehow interactively prompt for password
        $keyring->set_password($username, $password, "mylostspace.com");
    }
    login_somewhere_using($username, $password);
    if( password_was_wrong ) {
        $keyring->clear_password($username, "mylostspace.com");
    }

If any secure backend is available, password is preserved
for successive runs, and user need not be prompted again.

The choice can be impacted by configuration file, some environment
variables and/or additional parameters, see ["BACKEND SELECTION CRITERIA"](#backend-selection-criteria).

One can skip this module and be explicit if he or she knows which
keyring is to be used:

    use Passwd::Keyring::Gnome;
    my $keyring = Passwd::Keyring::Gnome->new();
    # ... from there as above

# SUBROUTINES/METHODS

## get\_keyring

    my $ring = get_keyring()

    my $ring = get_keyring(app=>'MyApp', group=>'SyncPasswords');

    my $ring = get_keyring(app=>'MyApp', group=>'Uploads',
                           config=>"$ENV{HOME}/.passwd-keyring-business.cfg");

    my $ring = get_keyring(app=>'MyApp', group=>'Scrappers',
                           prefer=>['Gnome', 'PWSafe3'],
                           forbid=>['KDEWallet']);

    my $ring = get_keyring(app=>'MyApp', group=>'Scrappers',
                           force=>['KDEWallet']);

    my $ring = get_keyring(app=>'MyApp', group=>'SyncPasswords',
                           %backend_specific_options);

Returns the keyring object most appropriate for the current system
(and matching specified criteria, and applying user configuration) and
initiates it.

The function inspects context the application runs in (operating
system, presence of GUI sessions etc), decides which backends seem
suitable and in what order of preference, then tries all suitable
backends and returns first succesfully loaded and initialized (or
croaks if there is none). See ["BACKEND SELECTION CRITERIA"](#backend-selection-criteria) for
info about criteria used.

All parameters are optional, but it is strongly recommended to set
`app` and `group`.

General parameters:

- app => 'App Name'

    Symbolic application name, which - depending on backend - may appear
    in interactive prompts (like dialog box "Application APP-NAME wants
    to access secure data..." popped up by KDE Wallet) and may be
    preserved as comment ("Created by ...") in secure storage (so may be
    seen in GUI password management apps like seahorse). Also, if config
    file is in use, it can override some settings on per-application basis.

- group => 'PasswordFolder'

    The name of the passwords folder. Can be visualised as folder or group
    by some GUIs (seahorse, pwsafe3) but it's most important role is to
    let one separate passwords used for different purposes. A few
    apps/scripts will share passwords if they use the same group name, but
    will use different and unrelated passwords if they specify different
    group.

- config => "/some/where/passwd\_keyring.cfg"

    Config file location.

Parameters impacting backend selection (usually not recommended as
they limit user choice, but hardcode choices if you like):

- force => 'Backend'

    Try only given backend and nothing else. Expects short backend name.
    For example `force=`'Gnome'> means [Passwd::Keyring::Gnome](https://metacpan.org/pod/Passwd%3A%3AKeyring%3A%3AGnome) is to be
    used and nothing else.

- prefer=>'Backend'    or    prefer => \['Backend1', 'Backend2', ...\]

    Try this/those backends first, and in the specified order (and try them
    even if by default they are not considered suitable for OS in use).

    For example `prefer=`\['OSXKeychain', 'KDEWallet'\]> asks module to try
    [Passwd::Keyring::OSXKeychain](https://metacpan.org/pod/Passwd%3A%3AKeyring%3A%3AOSXKeychain) first, then
    [Passwd::Keyring::KDEWallet](https://metacpan.org/pod/Passwd%3A%3AKeyring%3A%3AKDEWallet), then other options (if any) in module
    own preference.

- forbid=>'Backend'     or    forbid => \['Backend1', 'Backend2', ...\]

    Never use specified backend(s).

    For example `forbid=`\['Gnome', 'KDEWallet'\]> will cause method not to
    consider those GUI keyrings even if we run on Linux and have Gnome or
    KDE session active.

Backend-specific parameters:

- other parameters

    All other parameters are passed as such to actual keyring backend.
    To check whether/which may be used, consult backends documentation.
    Backends ignore params they do not understand, so some superset
    of possibly useful params is OK.

    It is recommended to use configuration file instead.

The function in it's simplest form should not fail (it falls back to
[Passwd::Keyring::Memory](https://metacpan.org/pod/Passwd%3A%3AKeyring%3A%3AMemory) if everything else fails), but it may croak
if some keyring is enforced or if Memory is forbidden or uninstalled.

# KEYRING METHODS

See [Passwd::Keyring::Auto::KeyringAPI](https://metacpan.org/pod/Passwd%3A%3AKeyring%3A%3AAuto%3A%3AKeyringAPI) for operations available on
keyring objects.

# CONFIGURATION FILE

The recommended way to impact backend selection on per-system (and
user) basis is to use configuration file, which let the user set
default keyring selection rules, and per-application overrides.

It's initial version can be created by [passwd\_keyring](https://metacpan.org/pod/passwd_keyring) script:

    passwd_keyring config_create

and edited afterwards.

See ["BACKEND SELECTION CRITERIA"](#backend-selection-criteria) for info how configuration settings
relate to other backend selection methods.

## CONFIGURATION FILE LOCATION

By default, config file is looked in `~/.passwd-keyring.cfg` on
Linux/Unix and `~/Local Settings/Application Data/.passwd-keyring.cfg` 
on Windows (more exactly: `.passwd-keyring.cfg` in directory reported by
`my_data` function from [File::HomeDir](https://metacpan.org/pod/File%3A%3AHomeDir)).

Environment variable `PASSWD_KEYRING_CONFIG` can be used to
override this setting (and should contain path of the configuration
file). Also, `config` parameter can be used in `get_keyring` method
(and takes precedence even over env variable).

Note that while it is OK not to have config file at all, but it is an
error (and causes exception) to have non-existing or inaccessible file
pointed by parameter or environment variable.

## CONFIGURATION FILE SYNTAX

Example:

    ; Default settings
    prefer=KDEWallet PWSafe3 Memory
    forbid=Gnome
    PWSafe3.file=~/passwd-keyring.pwsafe3

    ; Overrides for app named WebScrapers
    [WebScrapers]
    force=Gnome

    ; Overrides for app named XYZTests
    [XYZTests]
    force=PWSafe3
    PWSafe3.file=~/tests/xyz/passwd-keyring-tokens.pwsafe3

`prefer`, `forbid` and `force` define appropriate steering values,
as documented in [Passwd::Keyring::Auto](https://metacpan.org/pod/Passwd%3A%3AKeyring%3A%3AAuto). Space is used to separate
multiple values.

`;` can be used to start line comments.

# ENVIRONMENT VARIABLES

The following environment variables can be used to impact the module
behaviour.

General configuration variables:

- `PASSWD_KEYRING_CONFIG`

    Defines location of the config file.

- `PASSWD_KEYRING_DEBUG`

    Log on stderr details about tried and selected backends (and errors
    faced while they are tried).

Backend-selection variables (see ["BACKEND SELECTION CRITERIA"](#backend-selection-criteria) for
info how they relate to other methods and note that using
configuration file is usually recommended over setting those
variables):

- `PASSWD_KEYRING_FORCE` 

    Use given backend and nothing else. For example, by setting
    `PASSWD_KEYRING_FORCE=KDEWallet` user may enforce use of
    [Passwd::Keyring::KDEWallet](https://metacpan.org/pod/Passwd%3A%3AKeyring%3A%3AKDEWallet).

    This variable is completely ignored if `force` parameter was
    specified, and causes runtime error if specified backend is not
    present, not working, or present on the `forbid` list.

- `PASSWD_KEYRING_FORBID`

    Space separated list of backends to forbid, for example
    `PASSWD_KEYRING_FORBID="Gnome KDEWallet"`.

    Ignored if `force` parameter was specified, otherwise works as this
    param.

- `PASSWD_KEYRING_PREFER` 

    Space separated names of backends to prefer.

    Ignored if `prefer` parameter was specified, otherwise works as this
    param.

# BACKEND SELECTION CRITERIA

Backend selection is organized around 3 steering parameters: `force`,
`forbid`, and `prefer`.  For each of those, the value is looked in
the following places (first found is returned):

- hardcoded value (`get_keyring` param),
- environment variable (`PASSWD_KEYRING_...`)
- configuration file per-application setting 
- configuration file default setting
- library default

Each param is calculated separately, so one can have `prefer`
initialized from hardcoded value, `forbid` taken from the config file
and `force` defined by `PASSWD_KEYRING_FORCE` environment
variable. This may sometimes be confusing so use sparingly (and limit
to config file unless you really have reason to do otherwise).

Once calculated, those params are used in the following way:

- if `force` is set, this is just used and remaining params are ignored - module tries to load this backend and either returns it, or (if it failed) raises an exception;
- elsewhere, all known backends are enumerated, and filtered by `forbid` (so only those not forbidden remain)
- the remaining list is sorted according to position on `prefer` 
- those modules are tried in order, first which succesfully loaded and initialized is returned
- if nothing was found, module raises exception.

The following library defaults are used:

- there is no default for `force`;
- `forbid` is calculated according to the operating system (so [Passwd::Keyring::OSXKeychain](https://metacpan.org/pod/Passwd%3A%3AKeyring%3A%3AOSXKeychain) is forbidden everywhere except Mac OS/X, [Passwd::Keyring::Gnome](https://metacpan.org/pod/Passwd%3A%3AKeyring%3A%3AGnome) is forbidden on Windows and Mac, etc);
- `prefer` is calculated according to operating system and detected session characteristics (so, if Gnome or Ubuntu session is detected, [Passwd::Keyring::Gnome](https://metacpan.org/pod/Passwd%3A%3AKeyring%3A%3AGnome) is preferred, and if we have KDE, we prefer [Passwd::Keyring:KDEWallet](https://metacpan.org/pod/Passwd%3A%3AKeyring%3AKDEWallet), etc).

# FURTHER INFORMATION

[Passwd::Keyring::Auto::KeyringAPI](https://metacpan.org/pod/Passwd%3A%3AKeyring%3A%3AAuto%3A%3AKeyringAPI) describes methods available on keyring objects
and provides some additional detail on keyring construction.

# AUTHOR

Marcin Kasperski

# BUGS

Please report any bugs or feature requests to
issue tracker at [https://helixteamhub.cloud/mekk/projects/perl/issues](https://helixteamhub.cloud/mekk/projects/perl/issues).

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Passwd::Keyring::Auto

You can also look for information at:

[http://search.cpan.org/~mekk/Passwd-Keyring-Auto/](http://search.cpan.org/~mekk/Passwd-Keyring-Auto/)

Source code is tracked at:

[https://helixteamhub.cloud/mekk/projects/perl/repositories/keyring-auto](https://helixteamhub.cloud/mekk/projects/perl/repositories/keyring-auto)

# LICENSE AND COPYRIGHT

Copyright 2012-2015 Marcin Kasperski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
