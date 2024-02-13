# RT::Extension::NewTicketFromCorrespondence

[Request Tracker](https://bestpractical.com/request-tracker) extension to
make new tickets from correspondence.

# DESCRIPTION

This extension adds a \"*Split Off*\" action item to inbound
correspondence items in ticket history, which allows the operator to
create a new ticket, linked to the current one, based on that
transaction.

When a ticket requestor replies to their open ticket with a new issue
instead of creating a new ticket, this \"*Split Off*\" action allows the
ticket owner to create a new ticket on the requestor\'s behalf,
including the correspondence automatically.

Using this action opens the ticket creation form, with the
correspondence already included in the message box and the requestor set
to the sender, and with a "referred to by" link back to the original
ticket. The operator can then adjust the message as necessary before
creating the new ticket.

The action is only available to operators who have *CreateTicket* rights
on the ticket\'s queue and *ModifyTicket* rights on the ticket.

# RT VERSION

Known to work with RT 4.2.16, 4.4.4, and 5.0.1.

# INSTALLATION

- `PREFIX=/opt/rt5/local perl Makefile.PL`

    Adjust _PREFIX_ to point to your RT "local" directory.

- `make`
- `make install`

    May need root permissions.

- Edit your `/opt/rt5/etc/RT_SiteConfig.pm`

    Add this line:

        Plugin('RT::Extension::NewTicketFromCorrespondence');

- Restart your web server

- Clear your mason cache

        rm -rf /opt/rt5/var/mason_data/obj

- Restart your web server

# ISSUES AND CONTRIBUTIONS

The project is held on [Codeberg](https://codeberg.org); its issue tracker
is at [https://codeberg.org/a-j-wood/rt-extension-newticketfromcorrespondence/issues](https://codeberg.org/a-j-wood/rt-extension-newticketfromcorrespondence/issues).

# LICENSE AND COPYRIGHT

Copyright 2023-2024 Andrew Wood.

License GPLv3+: GNU GPL version 3 or later:
https://gnu.org/licenses/gpl.html

This is free software: you are free to change and redistribute it. There
is NO WARRANTY, to the extent permitted by law.
