# NAME

RT-Extension-GroupSummary - Display a summary of a group

# DESCRIPTION

This module allows RT to display semantic information about any [group](https://metacpan.org/pod/RT::Group), mainly through CustomFields attached to this [group](https://metacpan.org/pod/RT::Group).

It displays information about a [group](https://metacpan.org/pod/RT::Group) on a Group Summary page, similar to what is done about a [user](https://metacpan.org/pod/RT::User). A Group Summary page includes the name, the description and CustomFields of a group. The Group Summary page can be accessed from any tabs of `Admin/Groups` and is linked to any display of a [principal](https://metacpan.org/pod/RT::Principal) which is a [group](https://metacpan.org/pod/RT::Group) (just like any display of a [principal](https://metacpan.org/pod/RT::Principal) which is a [user](https://metacpan.org/pod/RT::User) is linked to the related User Summary page).

This module also provides a Group Summary Search feature and links results to related Group Summary pages.

In a future revision, it is planned to use Portlets in a Group Summary page, just like in a User Summary page.

# CONFIGURATION

Display of results from a Group Summary Search can be configured through the `GroupSearchResultFormat`:

    Set($GroupSearchResultFormat,
         q{'<a href="__WebPath__/Group/Summary.html?id=__id__">__id__</a>/TITLE:#'}
        .q{,'<a href="__WebPath__/Group/Summary.html?id=__id__">__Name__</a>/TITLE:Name'}
        .q{,'__Description__/TITLE:Description'}
    );

# RT VERSION

Works with RT 4.2 or greater

# INSTALLATION

- `perl Makefile.PL`
- `make`
- `make install`

    May need root permissions

- Edit your `/opt/rt4/etc/RT_SiteConfig.pm`

    If you are using RT 4.2 or greater, add this line:

        Plugin('RT::Extension::GroupSummary');

    For RT 4.0, add this line:

        Set(@Plugins, qw(RT::Extension::GroupSummary));

    or add `RT::Extension::GroupSummary` to your existing `@Plugins` line.

- Clear your mason cache

        rm -rf /opt/rt4/var/mason_data/obj

- Restart your webserver

# AUTHOR

Gérald Sédrati-Dinet <gibus@easter-eggs.com>

# REPOSITORY

[https://github.com/gibus/RT-Extension-GroupSummary](https://github.com/gibus/RT-Extension-GroupSummary)

# BUGS

All bugs should be reported via email to

[bug-RT-Extension-GroupSummary@rt.cpan.org](mailto:bug-RT-Extension-GroupSummary@rt.cpan.org)

or via the web at

[rt.cpan.org](http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-GroupSummary).

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2017 by Gérald Sédrati-Dinet, Easter-Eggs

This is free software, licensed under:

The GNU General Public License, Version 3, June 2007
