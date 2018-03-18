# RT-Extension-BecomeUser - Become another user

## DESCRIPTION

Extra functionality to become another user. This is reserved for 
people with "SuperUser" or the newly introduced "BecomeUser" right.

Users cannot become SuperUsers.

This module adds a column to the user table in Admin->Users called "become user".
Clicking on the "become" link leads to an ugly page from where you can go to the homepage of the target user.

The title bar in a "sudo session" is overwritten with "back to original account". This serves as a reminder of being a different user and clicking on it leads back to the original account.

Do not become yet another user after having impersonated a different user..

Use this module with care, you really are the other user. Also, be careful with granting the "BecomeUser" right. E.g. granted to an otherwise unprivileged user, it enables this user to become any arbitrarily privileged user (unless SuperUsers).

## IMPROVEMENTS

This module is ugly on purpose in the hope to avoid inadvertent manipulations.
The code is rather straighforward and simple.

It should be easy to make it beautiful if that is what you need.
If you do so, please get back with me before submitting a pull request. It might be better to start a new module like "BecomeUserBeautiful" or "BecomeUserUnobtrusive", in which case you are invited to use this module as a starting point.

## INSTALLATION

### Manual Installation

    cd (root dir of your rt install)
    cd local/
    mkdir -p RT-Extension-BecomeUser
    cd RT-Extension-BecomeUser

unzip the tar, here

Make sure the module gets loaded by including 

    Plugin('RT::Extension::BecomeUser');

into your etc/RT_SiteConfig.pm or a file in etc/RT_SiteConfig.d/

### Automated Install

    perl Makefile.PL

    make

    make install

Pull requests welcome!

## COPYRIGHT

Copyright (c) 2018 by Matthias Bloch. All rights reserved.

## LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

## AUTHOR

Matthias Bloch <matthias.bloch@puffin.ch>

=cut
