# NAME

RT::Extension::RichtextCustomField - CF with wysiwyg editor

# DESCRIPTION

Provide a new type of [custom field](https://docs.bestpractical.com/rt/4.4.4/RT/CustomField.html), similar to Text but with wysiwyg editor when editing value.

# RT VERSION

Works with RT 4.2 or greater

# INSTALLATION

- `perl Makefile.PL`
- `make`
- `make install`

    May need root permissions

- Patch your RT

    `RichtextCustomField` requires a small patch to allow  [custom fields](https://docs.bestpractical.com/rt/4.4.4/RT/CustomField.html) with `Richtext` type to be chosen as recipient for extracting from a [ticket](https://docs.bestpractical.com/rt/4.4.4/RT/Ticket.html) into an [article](https://docs.bestpractical.com/rt/4.4.4/RT/Article.pm). _You have to apply this patch if you need this feature, and only in this case._

    For RT 4.4 or lower, apply the included patch:

        cd /opt/rt4 # Your location may be different
        patch -p1 < /download/dir/RT-Extension-RichtextCustomField/patches/4.4-add-Richtext-CFs-ExtractArticleFromTicket.patch

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
