#   Changelog

Version history for RT-Extension-ReferenceIDoitObjects


##  1.00 (2017-01-05)

**Important notice:** This extension requires Request Tracker 4.4.x and i-doit 1.8.2 or higher. It is neither compatible to RT 4.0, 4.2 nor i-doit <= 1.8.1.

*   Fix: Re-named "mandator" to "tenant"
*   Fix: Re-written documentation
*   Fix: Clarify license (AGPLv3)
*   Fix: Broken include of Elements/EditCustomFields
*   Fix: Removed legacy IE hack


##  0.94 (Fri, 19 Sep 2014 11:16:42 +0200)

This is a bugfix-only release.

*   Fix: Improved selecting object type
*   Fix: Fixed missing tab navigation after submitting ticket changes on referenced i-doit objects
*   Fix: Fetching devices related to current requestor doesn't work
*   Fix: Fetching right object type when selecting an object
*   Fix: (Un)selecting all object items in a table
*   Fix: Selecting objects in all tables at the same time
*   Fix: Improved table styling
*   Fix: Broken images
*   Fix: Removed non-relevant columns from devices table
*   Fix: Improved sorting table columns
*   Fix: Avoid CSR error message when reloading "create new ticket" page
*   Fix: Show configured default view when initiated
*   Fix: Creating new logbook entries
*   Fix: Updated dataTables jQuery plugin
*   Fix: Re-factored JavaScript code
*   Fix: Improved code documentation


##  0.93 (Wed, 07 May 2014 14:20:10 +0200)

**Important notice:** This extension requires Request Tracker 4.2.x or higher and a running installation of i-doit 1.3 or higher. It is no longer compatible to RT version 4.0.x and i-doit version 1.2.x or older! Please use version 0.92 instead if you need compatibility to those older versions.

*   Made the code compatible to Request Tracker 4.2.x (breaks with 4.0.x)
*   Switched from username/password authentication to i-doit API key
*   Added view for requestor's linked devices including installed software components
*   Renamed some tabs for better understanding
*   Shared code with OTRS Help Desk extension to be more maintainable
*   Renamed configuration options for default view


##  0.92 (Fri, 07 Jun 2013 14:03:02 +0200)

*   Object browser shows object location
*   Implemented browser in "Jumbo update"
*   Hide custom fields when modifying referenced objects
*   Tree view: mark both hard- and software if software is marked
*   Fixed broken link in page menu for /Ticket/ModifyIDoitObjects.html after update
*   Removed buggy unused code
*   Improved code documentation
*   Updated to Module::Install 1.06 (thanks to Tatsuhiko Miyagawa)
*   Requires i-doit version 1.0.1 or higher


##  0.91 (Fri, 07 Sep 2012 14:02:49 +0200)

*   Removed deprecated Switch.pm (important for newer Perl versions; thanks to Matthias)
*   Described installation via CPAN.


##  0.9 (Mon, 04 Jun 2012 16:50:31 +0200)

*   Include javascript and css only if needed
*   Added checkbox to select/unselect all objects from object view
*   Added link to remove all selected objects from list
*   Show message if no requestor is selected
*   Implemented workaround for JavaScript's JSON object missing in IE < 9


##  0.8 (Fri, 01 Jun 2012 14:12:24 +0200)

*   Show link in the page menu to modify referenced i-doit objects


##  0.7 (Thu, 31 May 2012 10:01:16 +0200)

*   Use default tenant if necessary when modifying referenced i-doit objects
*   Look only for enabled object types (bug fix)


##  0.6 (Fri, 27 Apr 2012 11:49:06 +0200)

*   Write logbook entries within i-doit when objects are added or removed
*   Show loading message when initiating the browser
*   Requires i-doit version 0.9.9-9 or higher


##  0.5 (Mon, 23 Apr 2012 13:22:37 +0200)

*   When creating a ticket assign tenant and objects from HTTP GET
*   Bug fixing


##  0.4 (skipped)


##  0.3 (Mon, 13 Feb 2012 13:28:50 +0100)

*   Performance boost when rendering tables
*   Fixed API call when viewing a ticket created by email
*   Improved error messages
*   Improved meta information


##  0.2 (Fri, 20 Jan 2012 15:45:43 +0100)

*   Bug fixing


##  0.1 (Wed, 14 Dec 2011 09:30:22 +0100)

*   Initial release

