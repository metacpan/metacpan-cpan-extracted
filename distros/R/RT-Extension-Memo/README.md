# NAME

RT::Extension::Memo - Add a memo widget to tickets

# DESCRIPTION

This module adds a new widget to any [ticket](https://metacpan.org/pod/RT%3A%3ATicket) which allows to add, edit and display information directly on the ticket display page.

In many cases, resolving a ticket involves to collect and store some information which helps the owner of the ticket to find some solution. Such information includes tips and tricks, _todo_ list, etc. The common way to handle such information in RT is to paste it into comments.

To do so has several drawbacks. First, it mixed information which is relevant only to the owner of the ticket with communication between internal actors, that occurs through comments, for instance between the owner of the ticket and some of her colleagues. Second, the owner of the ticket has to search in the history for all comments to keep up with what has been done and what is left to be done, various issues that have arisen, etc. Third, when the owner of the ticket wants to add a new comment, she has to leave the display page of the ticket for the update form, loosing any access to the history of the comments, as well as various information about the ticket, such as its custom fields, dates or people. One solution to have the history at hand when adding a new comment, is to reply to the previous comment each time something has to be added. But the information is then copied in each reply with unneeded and cumbersome redundancy. Fourth, replying to the previous comment implies that this previous comment is folded when displaying the new one, with the consequence that it must be unfolded to read it and that its content cannot be searched until it is unfolded.

The `RT-Extension-Memo` plugin provides a new widget to manage such information. It is displayed on the top of the history in the display page of the ticket, therefore gathering all information at the same place. It can be edited directly on this same display page, with all information about the ticket at hand.

Internally, such a _Memo_ is stored in a single attribute, avoiding too much extra storage space (as it would have been the case if it was stored as a custom field value where all revisions are kept up in the database). The counterpart of this technical implementation is that caution has to be made when editing the _Memo_: any previous revision is overwritten, so if information is deleted when editing the _Memo_, it is actually forever lost.

# CONFIGURATION

These options are set in `etc/Memo_Config.pm` and can be overridden by users in their preferences.

- `$MemoRichText`

    Should "rich text" editing be enabled for memo widget?

- `$MemoHeight`

    Set number of lines of the textarea for editing memo.

- `$MemoRichTextHeight`

    Set height (in number of pixels) of the rich text editor for editing memo.

# RIGHTS

The following new rights can be applied at the global level or at the queue level:

- `SeeMemo`

    Users and groups with this right are able to see the _Memo_ on the display page of a ticket.

- `ModifyMemo`

    Users and groups with this right are able to add a new _Memo_ and to edit existing _Memo_ attached to a ticket.

# STYLING

The CSS properties of the Memo widget can be styled by overwriting defaults set in `static/css/memo.cc`.

# RT VERSION

Works with RT 4.2 or greater.

## RT 6

In RT 6, `Memo` is available as a _widget_, that you can use on `Display Layouts` for Tickets.

Also, in RT 6, a new `Description` field has been added to tickets, which can play the same role as `Memo`. Still there are some differences between these two widgets. `Memo` widget can be used only once in a page layout, while `Description` can be used multiple times in the same page layout. `Memo` widget is supposed to be used only on `Display Layouts` for tickets, while `Description` can also be used in `Create Layouts` and `Update Layouts`. `Description` widget is not available in `SelfService` while `Memo` is. `Description` widget can only be edited with richtext editor (`CKEditor`) while `Memo` can be configured to be edited in plain text.

# INSTALLATION

- `perl Makefile.PL`
- `make`
- `make install`

    May need root permissions

- Edit your `/opt/rt6/etc/RT_SiteConfig.pm`

    If you are using RT 4.2 or greater, add this line:

        Plugin('RT::Extension::Memo');

    For RT 4.0, add this line:

        Set(@Plugins, qw(RT::Extension::Memo));

    or add `RT::Extension::Memo` to your existing `@Plugins` line.

- Clear your mason cache

        rm -rf /opt/rt6/var/mason_data/obj

- Restart your webserver

# TEST SUITE

`Memo` comes with a fairly complete test suite. As for every [RT extention](https://docs.bestpractical.com/rt/6.0.2/writing_extensions.html#Tests), to run it, you will need a installed `RT`, set up in [development mode](https://docs.bestpractical.com/rt/6.0.2/hacking.html#Test-suite). Since `Memo` operates dynamically to show or edit information, some parts of its processing rely on `Javascript`. Therefore, the test suite requires a scriptable headless browser with `Javascript` capabilities. So, to work with [Selenium::Remote::Driver](https://metacpan.org/pod/Selenium%3A%3ARemote%3A%3ADriver), you need to install `Firefox` and `geckodriver`, or alternatively `Chrome` and `chromedriver` (see documentation for [Selenium Tests](https://docs.bestpractical.com/rt/6.0.2/hacking.html#Test-suite)).

It should be noted that _Best Practical_ is planing to implement automated browser testing using `Playwright`, since `Selenium` tests in _RT Core_ have issues with false negatives, often because of `htmx` and issues with implementing correct waiting behavior for pages. `Memo` tests experience the same issues where a test can sometimes fail while the same test pass most of the time. `Memo` tests will be rewritten with `Playwright` to be more robust, when such tests will be available in _RT Core_.

# AUTHOR

Gérald Sédrati <gibus@easter-eggs.com>

# REPOSITORY

[https://github.com/gibus/RT-Extension-Memo](https://github.com/gibus/RT-Extension-Memo)

# BUGS

All bugs should be reported via email to

[bug-RT-Extension-Memo@rt.cpan.org](mailto:bug-RT-Extension-Memo@rt.cpan.org)

or via the web at

[rt.cpan.org](http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-Memo).

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2017-2022 by Gérald Sédrati, Easter-Eggs

This is free software, licensed under:

The GNU General Public License, Version 3, June 2007
