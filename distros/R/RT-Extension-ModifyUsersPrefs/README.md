# NAME

RT::Extension::ModifyUsersPrefs - Allow to modify other users' preferences

# DESCRIPTION

By default, RT only allows authorized users to modify their own preferences. This module adds the ability to modify other users' preferences, by adding a new tab in `Admin/Users` pages.

This implies that `AdminUsers` and ` ShowConfigTab` rights should be granted in order to be authorized to modify other users' preferences.

# RT VERSION

Works with RT 4.2 or greater

# INSTALLATION

- `perl Makefile.PL`
- `make`
- `make install`

    May need root permissions

- Edit your `/opt/rt4/etc/RT_SiteConfig.pm`

    If you are using RT 4.2 or greater, add this line:

        Plugin('RT::Extension::ModifyUsersPrefs');

    For RT 4.0, add this line:

        Set(@Plugins, qw(RT::Extension::ModifyUsersPrefs));

    or add `RT::Extension::ModifyUsersPrefs` to your existing `@Plugins` line.

- Clear your mason cache

        rm -rf /opt/rt4/var/mason_data/obj

- Restart your webserver

# AUTHOR

Gérald Sédrati-Dinet <gibus@easter-eggs.com>

# REPOSITORY

[https://github.com/gibus/RT-Extension-ModifyUsersPrefs](https://github.com/gibus/RT-Extension-ModifyUsersPrefs)

# BUGS

All bugs should be reported via email to

[bug-RT-Extension-ModifyUsersPrefs@rt.cpan.org](mailto:bug-RT-Extension-ModifyUsersPrefs@rt.cpan.org)

or via the web at

[rt.cpan.org](http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ModifyUsersPrefs).

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2017 by Gérald Sédrati-Dinet, Easter-Eggs

This is free software, licensed under:

The GNU General Public License, Version 3, June 2007

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 21:

    &#x3d;back without =over
