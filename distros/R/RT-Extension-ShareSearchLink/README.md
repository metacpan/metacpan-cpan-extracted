# NAME

RT::Extension::ShareSearchLink - Shorter links for ticket searches

# DESCRIPTION

This extension adds a "_Share_" item to the menu on the search results
page, and a "_Share a link_" button to the bottom of the results.

Both of these will show a pop-up box containing a short link to the current
search, with all the search terms and formatting stored in a database entry
in RT.

This is useful when your search URL is very long.

# RT VERSION

Known to work with RT 4.2.16, 4.4.4, and 5.0.1.

# REQUIREMENTS

Requires `Data::GUID`.

# INSTALLATION

- `perl Makefile.PL`
- `make`
- `make install`

    May need root permissions.

- Set up the database

    After running `make install` for the first time, you will need to create
    the database tables for this extension.  Use `etc/schema-mysql.sql` for
    MySQL or MariaDB, or `etc/schema-postgresql.sql` for PostgreSQL.

- Edit your `/opt/rt4/etc/RT_SiteConfig.pm`

    Add this line:

        Plugin('RT::Extension::ShareSearchLink');

- Clear your mason cache

        rm -rf /opt/rt4/var/mason_data/obj

- Restart your web server
- Set up database pruning

    Add a cron job similar to the ones you will already have for other RT
    maintenance jobs like `rt-email-dashboards` to clear down expired shared
    search links, like this:

        4 4 * * * root /opt/rt4/bin/rt-crontool --search RT::Extension::ShareSearchLink --action RT::Extension::ShareSearchLink

    This way, shared search links will expire 90 days after they have last been
    viewed, and will expire within 7 days of creation if they aren't viewed at
    least twice in that time.

# AUTHOR

Andrew Wood

<div>
    <p>All bugs should be reported via email to <a
    href="mailto:bug-RT-Extension-ShareSearchLink@rt.cpan.org">bug-RT-Extension-ShareSearchLink@rt.cpan.org</a>
    or via the web at <a
    href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ShareSearchLink">rt.cpan.org</a>.</p>
</div>

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Andrew Wood

This is free software, licensed under:

    The GNU General Public License, Version 2, June 1991

# Internal package RT::ShareSearchLink::SharedSearchLink

This package provides the shared search link object.

## Create Parameters => { ... }, \[ UUID => 'xxx' \]

Creates a new shared search link for a search with the given parameters, and
returns (_$id_, _$message_).  If a _UUID_ is not supplied, a new one is
generated.

## Load $id|$UUID

Load a shared search link by numeric ID or by string UUID, returning the
numeric ID or undef.

## Delete

Delete this shared search link from the database.

## Parameters

Return a hash of the parameters stored in this shared search link.

## AddView

Increment the view counter for this shared search link, and set its last viewed date.

## \_CoreAccessible

Private method which defines the columns in the database table.

# Internal package RT::ShareSearchLink::SharedSearchLinks

This package provides the group class for shared search links.
