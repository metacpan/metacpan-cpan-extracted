package Passwd::Keyring::Auto;

use warnings;
use strict;
use base 'Exporter';
our @EXPORT = qw(get_keyring);
use Carp;
use Passwd::Keyring::Auto::Chooser;

=head1 NAME

Passwd::Keyring::Auto - interface to secure password storage(s)

=head1 VERSION

Version 0.7201


=cut

our $VERSION = '0.7201';

=head1 SYNOPSIS

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
variables and/or additional parameters, see L</BACKEND SELECTION CRITERIA>.

One can skip this module and be explicit if he or she knows which
keyring is to be used:

    use Passwd::Keyring::Gnome;
    my $keyring = Passwd::Keyring::Gnome->new();
    # ... from there as above

=head1 SUBROUTINES/METHODS

=head2 get_keyring

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
croaks if there is none). See L</BACKEND SELECTION CRITERIA> for
info about criteria used.

All parameters are optional, but it is strongly recommended to set
C<app> and C<group>.

General parameters:

=over 4

=item app => 'App Name'

Symbolic application name, which - depending on backend - may appear
in interactive prompts (like dialog box "Application APP-NAME wants
to access secure data..." popped up by KDE Wallet) and may be
preserved as comment ("Created by ...") in secure storage (so may be
seen in GUI password management apps like seahorse). Also, if config
file is in use, it can override some settings on per-application basis.

=item group => 'PasswordFolder'

The name of the passwords folder. Can be visualised as folder or group
by some GUIs (seahorse, pwsafe3) but it's most important role is to
let one separate passwords used for different purposes. A few
apps/scripts will share passwords if they use the same group name, but
will use different and unrelated passwords if they specify different
group.

=item config => "/some/where/passwd_keyring.cfg"

Config file location.

=back

Parameters impacting backend selection (usually not recommended as
they limit user choice, but hardcode choices if you like):

=over 4

=item force => 'Backend'

Try only given backend and nothing else. Expects short backend name.
For example C<force=>'Gnome'> means L<Passwd::Keyring::Gnome> is to be
used and nothing else.

=item prefer=>'Backend'    or    prefer => ['Backend1', 'Backend2', ...]

Try this/those backends first, and in the specified order (and try them
even if by default they are not considered suitable for OS in use).

For example C<prefer=>['OSXKeychain', 'KDEWallet']> asks module to try
L<Passwd::Keyring::OSXKeychain> first, then
L<Passwd::Keyring::KDEWallet>, then other options (if any) in module
own preference.

=item forbid=>'Backend'     or    forbid => ['Backend1', 'Backend2', ...]

Never use specified backend(s).

For example C<forbid=>['Gnome', 'KDEWallet']> will cause method not to
consider those GUI keyrings even if we run on Linux and have Gnome or
KDE session active.

=back

Backend-specific parameters:

=over 4

=item other parameters

All other parameters are passed as such to actual keyring backend.
To check whether/which may be used, consult backends documentation.
Backends ignore params they do not understand, so some superset
of possibly useful params is OK.

It is recommended to use configuration file instead.

=back

The function in it's simplest form should not fail (it falls back to
L<Passwd::Keyring::Memory> if everything else fails), but it may croak
if some keyring is enforced or if Memory is forbidden or uninstalled.

=head1 KEYRING METHODS

See L<Passwd::Keyring::Auto::KeyringAPI> for operations available on
keyring objects.

=head1 CONFIGURATION FILE

The recommended way to impact backend selection on per-system (and
user) basis is to use configuration file, which let the user set
default keyring selection rules, and per-application overrides.

It's initial version can be created by L<passwd_keyring> script:

    passwd_keyring config_create

and edited afterwards.

See L</BACKEND SELECTION CRITERIA> for info how configuration settings
relate to other backend selection methods.

=head2 CONFIGURATION FILE LOCATION

By default, config file is looked in C<~/.passwd-keyring.cfg> on
Linux/Unix and C<~/Local Settings/Application Data/.passwd-keyring.cfg> 
on Windows (more exactly: C<.passwd-keyring.cfg> in directory reported by
C<my_data> function from L<File::HomeDir>).

Environment variable C<PASSWD_KEYRING_CONFIG> can be used to
override this setting (and should contain path of the configuration
file). Also, C<config> parameter can be used in C<get_keyring> method
(and takes precedence even over env variable).

Note that while it is OK not to have config file at all, but it is an
error (and causes exception) to have non-existing or inaccessible file
pointed by parameter or environment variable.

=head2 CONFIGURATION FILE SYNTAX

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

C<prefer>, C<forbid> and C<force> define appropriate steering values,
as documented in L<Passwd::Keyring::Auto>. Space is used to separate
multiple values.

C<;> can be used to start line comments.

=head1 ENVIRONMENT VARIABLES

The following environment variables can be used to impact the module
behaviour.

General configuration variables:

=over 4

=item C<PASSWD_KEYRING_CONFIG>

Defines location of the config file.

=item C<PASSWD_KEYRING_DEBUG>

Log on stderr details about tried and selected backends (and errors
faced while they are tried).

=back

Backend-selection variables (see L</BACKEND SELECTION CRITERIA> for
info how they relate to other methods and note that using
configuration file is usually recommended over setting those
variables):

=over 4

=item C<PASSWD_KEYRING_FORCE> 

Use given backend and nothing else. For example, by setting
C<PASSWD_KEYRING_FORCE=KDEWallet> user may enforce use of
L<Passwd::Keyring::KDEWallet>.

This variable is completely ignored if C<force> parameter was
specified, and causes runtime error if specified backend is not
present, not working, or present on the C<forbid> list.

=item C<PASSWD_KEYRING_FORBID>

Space separated list of backends to forbid, for example
C<PASSWD_KEYRING_FORBID="Gnome KDEWallet">.

Ignored if C<force> parameter was specified, otherwise works as this
param.

=item C<PASSWD_KEYRING_PREFER> 

Space separated names of backends to prefer.

Ignored if C<prefer> parameter was specified, otherwise works as this
param.

=back

=head1 BACKEND SELECTION CRITERIA

Backend selection is organized around 3 steering parameters: C<force>,
C<forbid>, and C<prefer>.  For each of those, the value is looked in
the following places (first found is returned):

=over 4

=item hardcoded value (C<get_keyring> param),

=item environment variable (C<PASSWD_KEYRING_...>)

=item configuration file per-application setting 

=item configuration file default setting

=item library default

=back

Each param is calculated separately, so one can have C<prefer>
initialized from hardcoded value, C<forbid> taken from the config file
and C<force> defined by C<PASSWD_KEYRING_FORCE> environment
variable. This may sometimes be confusing so use sparingly (and limit
to config file unless you really have reason to do otherwise).

Once calculated, those params are used in the following way:

=over 4

=item if C<force> is set, this is just used and remaining params are ignored - module tries to load this backend and either returns it, or (if it failed) raises an exception;

=item elsewhere, all known backends are enumerated, and filtered by C<forbid> (so only those not forbidden remain)

=item the remaining list is sorted according to position on C<prefer> 

=item those modules are tried in order, first which succesfully loaded and initialized is returned

=item if nothing was found, module raises exception.

=back

The following library defaults are used:

=over 4

=item there is no default for C<force>;

=item C<forbid> is calculated according to the operating system (so L<Passwd::Keyring::OSXKeychain> is forbidden everywhere except Mac OS/X, L<Passwd::Keyring::Gnome> is forbidden on Windows and Mac, etc);

=item C<prefer> is calculated according to operating system and detected session characteristics (so, if Gnome or Ubuntu session is detected, L<Passwd::Keyring::Gnome> is preferred, and if we have KDE, we prefer L<Passwd::Keyring:KDEWallet>, etc).

=back

=cut

sub get_keyring {
    my $chooser = Passwd::Keyring::Auto::Chooser->new(@_);
    return $chooser->get_keyring();
}

=head1 FURTHER INFORMATION

L<Passwd::Keyring::Auto::KeyringAPI> describes methods available on keyring objects
and provides some additional detail on keyring construction.

=head1 AUTHOR

Marcin Kasperski

=head1 BUGS

Please report any bugs or feature requests to
issue tracker at L<https://bitbucket.org/Mekk/perl-keyring-auto>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Passwd::Keyring::Auto

You can also look for information at:

L<http://search.cpan.org/~mekk/Passwd-Keyring-Auto/>

Source code is tracked at:

L<https://bitbucket.org/Mekk/perl-keyring-auto>

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2015 Marcin Kasperski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Passwd::Keyring::Auto
