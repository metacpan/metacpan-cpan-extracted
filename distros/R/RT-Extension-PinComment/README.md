# RT::Extension::PinComment

[Request Tracker](https://bestpractical.com/request-tracker) extension to
allow a comment to be pinned, so it is always shown first in the ticket
history and is highlighted.

# DESCRIPTION

This extension adds the facility to pin a comment on a ticket, so it is
highlighted and always comes first in the transaction history.

As well as adding a "_Pin_" action to ticket transactions, this extension
also provides a format field "_PinComment_" in the query builder for
showing the contents of a ticket's pinned comment, and a search option
"_Has a pinned comment_" to find tickets with pinned comments.

An operator requires the _ModifyTicket_ right on a ticket to change which
comment is pinned on it.

# RT VERSION

Known to work with RT 4.2.16, 4.4.4, and 5.0.1.

# INSTALLATION

- `perl Makefile.PL`
- `make`
- `make install`

    May need root permissions.

- Edit your `/opt/rt4/etc/RT_SiteConfig.pm`

    Add this line:

        Plugin('RT::Extension::PinComment');

- Restart your web server

# ISSUES AND CONTRIBUTIONS

The project is held on [Codeberg](https://codeberg.org); its issue tracker
is at [https://codeberg.org/a-j-wood/rt-extension-pincomment/issues](https://codeberg.org/a-j-wood/rt-extension-pincomment/issues).

# LICENSE AND COPYRIGHT

Copyright 2023 Andrew Wood.

License GPLv3+: GNU GPL version 3 or later: [https://gnu.org/licenses/gpl.html](https://gnu.org/licenses/gpl.html)

This is free software: you are free to change and redistribute it.  There is
NO WARRANTY, to the extent permitted by law.
