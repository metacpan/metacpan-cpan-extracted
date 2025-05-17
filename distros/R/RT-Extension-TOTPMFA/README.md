# RT::Extension::TOTPMFA

[Request Tracker](https://bestpractical.com/request-tracker) extension
implementing multi-factor authentication (MFA) with time-dependent one-time
passcodes (TOTP).

# Description

This extension allows users to add multi-factor authentication to their
account.

A secret token is stored for each user, and used for time-based one-time
passcodes (TOTP).

To enable MFA, the "about me" page is extended with a new section alongside
identity and password, for TOTP token management.  In this section, the user
may scan a QR code based on this token into their mobile device's
TOTP-compatible app, such as FreeOTP+ or Google Authenticator.  Or, they can
enrol the key for their Yubikey device on this page instead.

When an account has MFA enabled, the RT login page works as usual, but the
user is then prompted to enter a one-time passcode before they can proceed
any further.

The MFA prompt will be repeated after a configurable duration, or when a new
session begins.

If a user loses their MFA token, an administrator can switch off MFA in
their account settings on their behalf, on the user basics modification
page.

# Requirements

Requires at least RT 5.0.1.

These Perl modules are also required:

 * Authen::OATH (Debian package: libauthen-oath-perl)
 * Convert::Base32 (Debian package: libconvert-base32-perl)
 * Imager::QRCode (Debian package: libimager-qrcode-perl)
 * Crypt::CBC (Debian package: libcrypt-cbc-perl)
 * LWP::UserAgent (Debian package: libwww-perl)

# Installation

For installation to work, you will need **Module::Install::RTx**.

- `RTHOME=/usr/share/request-tracker5/lib perl Makefile.PL`

    Adjust _RTHOME_ to point to the directory containing **RT.pm**.

- `make`
- `make install`

    May need root permissions.

    If this does not work because you don't have the relevant
    **Module::Install** or **Module::Install::RTx** modules, you can
    instead just copy all of the files to the local plugins directory.

    On Debian for instance this _README.md_ file should end up at
    _/usr/local/share/request-tracker5/plugins/RT-Extension-TOTPMFA/README.md_.

- Edit your `/opt/rt5/etc/RT_SiteConfig.pm`

    Add these lines:

        Set($TOTPMFA_Issuer, 'Request Tracker');
        Set($TOTPMFA_Period, 30);
        Set($TOTPMFA_Digits, 6);
        Plugin('RT::Extension::TOTPMFA');

    See below for configuration details.

- Restart your web server

# Configuration

**$TOTPMFA_Issuer**

:   The issuer name used in the QR code when a user registers their secret.
    This is what is shown next to the username in the user's authenticator app.
    The default is "Request Tracker".

**$TOTPMFA_Period**

:   How many seconds a one-time passcode is valid for.  The default is 30.

**$TOTPMFA_Digits**

:   How many digits to use in the one-time passcodes.  The default is 6.

# Issues and contributions

The project is held on [Codeberg](https://codeberg.org); its issue tracker
is at [https://codeberg.org/ivarch/rt-extension-totpmfa/issues](https://codeberg.org/ivarch/rt-extension-totpmfa/issues).

# License and copyright

Copyright 2025 Andrew Wood.

Contributors include:

 * [elacour](https://codeberg.org/elacour) - localisation support, French
   translation, inline QR code display, bugfix in secret reset, and
   packaging improvements.

License GPLv3+: GNU GPL version 3 or later: [https://gnu.org/licenses/gpl.html](https://gnu.org/licenses/gpl.html)

This is free software: you are free to change and redistribute it.  There is
NO WARRANTY, to the extent permitted by law.
