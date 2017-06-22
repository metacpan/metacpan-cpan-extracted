# NAME

RT-Extension-RichtextCustomField - CF with wysiwyg editor

# DESCRIPTION

Provide a new type of [custom field](https://metacpan.org/pod/RT::CustomField), similar to Text but with wysiwyg editor when editing value.

# RT VERSION

Works with RT 4.2 or greater

# INSTALLATION

- `perl Makefile.PL`
- `make`
- `make install`

    May need root permissions

- Edit your `/opt/rt4/etc/RT_SiteConfig.pm`

    If you are using RT 4.2 or greater, add this line:

        Plugin('RT::Extension::RichtextCustomField');

    For RT 4.0, add this line:

        Set(@Plugins, qw(RT::Extension::RichtextCustomField));

    or add `RT::Extension::RichtextCustomField` to your existing `@Plugins` line.

- Clear your mason cache

        rm -rf /opt/rt4/var/mason_data/obj

- Restart your webserver

# AUTHOR

Gérald Sédrati-Dinet <gibus@easter-eggs.com>

# REPOSITORY

[https://github.com/gibus/RT-Extension-RichtextCustomField](https://github.com/gibus/RT-Extension-RichtextCustomField)

# BUGS

All bugs should be reported via email to

[bug-RT-Extension-RichtextCustomField@rt.cpan.org](mailto:bug-RT-Extension-RichtextCustomField@rt.cpan.org)

or via the web at

[rt.cpan.org](http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-RichtextCustomField).

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2017 by Gérald Sédrati-Dinet, Easter-Eggs

This is free software, licensed under:

The GNU General Public License, Version 3, June 2007
