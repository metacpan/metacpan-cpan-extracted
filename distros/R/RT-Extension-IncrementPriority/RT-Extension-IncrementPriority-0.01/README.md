NAME
----
`RT-Extension-IncrementPriority` - adds action `RT::Action::IncrementPriority` 
to increment a ticket's priority by one each time it is run.

DESCRIPTION
-----------
This extension adds a new Action called `RT::Action::IncrementPriority`
which ignores ticket due dates and simply increments `Priority` by one
(unless the ticket has already reached or exceeded `FinalPriority` in
which case it does nothing). This is in contrast to
`RT::Action::LinearEscalate` and `RT::Action::EscalatePriority` which both
update priority based on due date.

This is useful when tickets do not have due dates but for which it is
nonetheless desirable to periodically increment the priority, especially
when updates are based on some search criteria (which can be specified
in a call to `rt-crontool`).

For example, one could increment the priority of all 'new' or 'open'
(but not 'stalled') ticket by running `rt-crontool` on an hourly basis:
```bash
    rt-crontool --search RT::Search::FromSQL \
    --search-arg "(Status='new' OR Status='open')" \
    --action RT::Action::IncrementPriority
```

Like `RT::Action::LinearEscalate`, `RT::Action::IncrementPriority` can also
be run silently (i.e. without creating a transaction or updating the
LastUpdated timestamp). 

This can be accomplished by adding the argument `UpdateLastUpdated` set to 0: 
```bash
    rt-crontool --search RT::Search::FromSQL \
    --search-arg "(Status='new' OR Status='open')" \
    --action RT::Action::IncrementPriority \
    --action-arg "UpdateLastUpdated: 0"
```

There is also an option `RecordTransaction` which when set to 1 will cause the 
priority incrementing to be recorded as a transaction on the ticket:
```bash
    rt-crontool --search RT::Search::FromSQL \
    --search-arg "(Status='new' OR Status='open')" \
    --action RT::Action::IncrementPriority \
    --action-arg "RecordTransaction: 1"
```

RT VERSION
----------
Tested with RT 4.2. Should work with 4.0 as well.

INSTALLATION
------------
1. Install the RT::Extension::IncrementPriority module from CPAN or manually:
```bash
    perl Makefile.PL
    make
    make install
```

2. Edit your /opt/rt4/etc/RT_SiteConfig.pm
    - If you are using RT 4.2 or greater, add the line: `Plugin('RT::Extension::IncrementPriority');`.
    - For RT 4.0, add the line: `Set(@Plugins, qw(RT::Extension::IncrementPriority));`
(or add RT::Extension::IncrementPriority to your existing @Plugins line).

3. Restart the RT webserver.

AUTHORS
-------
- Joshua C. Randall <jcrandall@alum.mit.edu>
- Kevin Riggle <kevinr@bestpractical.com>
- Ruslan Zakirov <ruz@bestpractical.com>

BUGS
----
All bugs should be reported either:
- via email to: [bug-RT-Extension-IncrementPriority@rt.cpan.org](mailto:bug-RT-Extension-IncrementPriority@rt.cpan.org)
- or via the web at: [rt.cpan.org](http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-IncrementPriority).

LICENSE AND COPYRIGHT
---------------------
    Copyright (c) 2015 Genome Research Ltd.

    Copyright (c) 1996-2014 Best Practical Solutions, LLC
    <sales@bestpractical.com>

    This work is made available to you under the terms of Version 2 of the
    GNU General Public License. A copy of that license should have been
    provided with this software, but in any event can be snarfed from
    www.gnu.org.

    This work is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
    FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
    more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 or visit their
    web page on the internet at
    http://www.gnu.org/licenses/old-licenses/gpl-2.0.html.

