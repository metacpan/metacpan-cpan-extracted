# $File: //depot/RT/osf/lib/RTx/Foundry.pm $ $Author: autrijus $
# $Revision: #15 $ $Change: 10088 $ $DateTime: 2004/02/18 00:22:05 $

package RTx::Foundry;
$RTx::Foundry::VERSION = '0.01';

1;

=head1 NAME

RTx::Foundry - Base classes for the RT Foundry system

=head1 VERSION

This document describes version 0.01 of RTx::Foundry, released
March 28, 2004.

=head1 SYNOPSIS

Not at the moment.  See L<http://rt.openfoundry.org/> for a demo.

Currently, the only way to install RT Foundry is from the ports files in
L<http://rt.openfoundry.org/Foundry/Project/Download/?Queue=OpenFoundry>,
which requires a FreeBSD system to run on.

=head1 DESCRIPTION

The B<RT Foundry> project is the code behind Taiwan's B<OSSF> initiative,
as part of the Free Software Promotion Project, executed by the Institute of
Information Science, Academia Sinica (IIS).

=head1 DESIGN

This is a very rough outline.  More information will be translated from
Chinese in due time.

=head2 Overview

What is "RT Foundry"?

 - Decentralized development environment
 - Modular services
  - VCS, tracker, listserv...
 - Multi-modal workspaces
  - Web, email, irc...
 - Loosely connected
  - REST, multi-host, cross-foundry support...
 - Like sf.net/collab.net, but *not* monolithic

Monolithic design - Why not?

 - Hard to maintain
 - No reusable parts
 - Single method of access
 - Single point of failure
 - Difficult to integrate with existing process

Neat things about RT Foundry

 - Free software under GPL / Artistic license
 - Based on mature projects
  - Perl, Apache, OpenSSH, PAM, RT, Sympa, CVS, Mason...
 - ...and "emerging technologies"
  - Subversion, Kwiki, VCP, Mech, REST, RDF...
 - Easy to hook up other services
  - even across machines

=head2 Services

Metadata

 - Based on DBIx::SearchBuilder
  - Supports MySQL, PostgresSQL, Oracle, Sybase...
 - Users
  - Contact info
  - Privacy settings
 - Projects
  - Planned and actual releases
  - DSLIP: maturity/support/license/interface/language...
 - Groups
  - Project admin and members
  - Object admin and watchers

Revision control

 - Based on SVN/Perl
 - Public CVS interfaces
 - Import vendor sources
  - CVS
  - Subversion
  - Perforce
  - SourceSafe (untested)
 - Smoke tests and snapshots
 - Cross-repository support with SVK 

Issue tracking

 - Based on RT3
  - Owner, Requestor, Cc, AdminCc...
 - Types 
  - Defect, Patch, Task, Feature, Enhancement...
 - Global custom-fields
  - Status, Resolution, Priority...
 - Project-specific fields
  - Component, Version, UserDefined...

Forum and mailing list

 - Based on Sympa
 - Customizable TT2 templates
 - PGP and attachments support
 - Web interfaces also serve as forums
  - Web-post support
  - Shared folders and files

Documentation and news

 - Based on Kwiki
 - Page-specific read/write policy
 - Revision-controlled pages
  - Track modification times and diffs
  - Allow imports from remote text documents
  - May be checked-out as SVN/CVS repositories
 - Generate "project blogs" automatically

Statistic reports

 - Based on RTx::Report and DBIx::ReportBuilder
 - Supports all major GD::Graph flavours
 - Flexible Join, Limit and OrderBy support
 - Handles multiple metadata sources
 - Exports XML, HTML, SXW, PDF, MSWord

=head2 Workspaces

Web

 - Based on RTx::Foundry and RTx::TabbedUI
 - Unified interface to remote services
 - Internationalized and multilingual
 - Tabbed look and feel derived from GForge
 - Accessible and friendly to text-only browsers

Email

 - Based on RT's mailgate and scrips
 - All transactions can send notifications
 - Users can sign up as project/issue watchers
 - Add correspondence and comments via email
 - Eventually allow PGP-signed commands

Command line

 - Based on RT's bin/rt tool
 - Just another REST client
 - Soon will become Net::RT::Shell
 - Full manipulation of all core objects

IRC

 - Newsbot: report new events and issues
 - Blogbot: add news posts for users
 - Logbot: record meetings into Wiki pages
 - Infobot: find people, leave message, display RSS feeds

Other possible interfaces

 - Separate views in individual services
 - Curses/Tk/Gtk/Qt/XUL based frontends
 - BBS gateway via OurNet::BBS
 - NNTP gateway

=head2 Connectivity


Authentication

 - Based on PAM and RT::ACL
 - Role-based rights
  - Each object has its own ACL table
  - Delegable rights for users and groups
 - REST API for permission query
  - Single sign-on
  - e.g. for authenticating CVS commits

Web "scwrapping"

 - Based on WWW::Mechanize and Template::Extract
 - Use persistent "agents" to proxy for users
 - Incorporate remote pages into local display
 - An easy way to add new services
 - Example: repository viewer backends
  - SVN::Web
  - CVSWeb
  - P4Web

RDF resources

 - RSS feeds with parameters
  - "new tickets in the past 5 days for project foo"
  - "3 most recent CVS/SVN commits"
 - Fetch and aggregate remote RDF resources
  - Remote project metadata
  - Remote member profiles
 - All objects and transactions should become URNs

REST interface

 - Web objects will have equivalent REST endpoints:
     /REST/1.0/ticket/10/attachment/1

 - Accessible with command line utility:
     rt ls tickets -i "Priority > 5" | rt edit - set status=resolved

 - Published WSDL definition
  - Easily manipulatable with scripting languages
  - .NET and J2EE compatible

=head2 Conclusion

Current status

 - Alpha testing on rt.openfoundry.org
 - Self-hosting with 10+ project members
 - Separate components released on CPAN
  - RTx::Foundry
  - RTx::TabbedUI
  - RTx::Report
 - FreeBSD port (www/rtfoundry/) imminent

Future Plans

 - Offline operation with RT3.2 and SVK
 - GUID-based RDF interfaces
 - Decentralized file distribution mechanisms
 - Integration with rt.cpan.org and other CPAN services
 - Web UIs should be in XHTML and skinnable via CSS
 - Patches welcome!

=head1 SEE ALSO

RTx::Foundry Demo: L<http://rt.openfoundry.org/>

OSSF Website: L<http://www.openfoundry.org/en/>

RT: L<http://www.bestpractical.com/rt/>

Subversion: L<http://subversion.tigris.org/>

SVK: L<http://svk.elixus.org/>

Kwiki: L<http://www.kwiki.org/>

Sympa: L<http://www.sympa.org/>

=head1 ACKNOWLEDGMENTS

This project is sponsored by:
    Institute of Information Science,
    Academia Sinica, Taiwan.

Implemented by:
    OurInternet, Inc.

Based on works contributed by:
    104 Technology, Inc.

In collaboration with:
    Best Practical Solutions, LLC.

=head1 COPYRIGHT

Copyright 2004 by Academia Sinica, Taiwan.

(Except where explicitly superseded by other copyright notices)

This work is made available to you under the terms of Version 2 of
the GNU General Public License. A copy of that license should have
been provided with this software, but in any event can be snarfed
from www.gnu.org.

This work is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

=cut
