# Copyright (c) 2012, cPanel, Inc.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.
package Task::Cpanel::Catalyst;
{
  $Task::Cpanel::Catalyst::VERSION = '11.36.001';
}

use strict;
use warnings;

=head1 NAME

Task::Cpanel::Catalyst - Provides a set of Catalyst modules

=head1 VERSION

version 11.36.001

=head1 SYNOPSIS

    cpan Task::Cpanel::Catalyst

=head1 DESCRIPTION

This module provides a growing set of Catalyst modules useful to cPanel customers
who want to build/use Catalyst apps which run on a B<cPanel & WHM> system.

The first two numbers of this version (eg: 11.36) refer to the major version of
B<cPanel & WHM> it applies to.

We encourage customer feedback if you feel there are modules that would be useful
to you that are not already on this list.

=head2 MODULES REQUIRED

=over

=item L<Cache::FastMmap|Cache::FastMmap>

Uses an mmap'ed file to act as a shared memory interprocess cache

=cut

use Cache::FastMmap;

=item L<Catalyst|Catalyst>

The Elegant MVC Web Application Framework

=cut

use Catalyst;

=item L<Catalyst::ActionRole::ACL|Catalyst::ActionRole::ACL>

User role-based authorization action class

=cut

use Catalyst::ActionRole::ACL;

=item L<Catalyst::Authentication::Store::DBIx::Class|Catalyst::Authentication::Store::DBIx::Class>

A storage class for Catalyst Authentication using DBIx::Class

=cut

use Catalyst::Authentication::Store::DBIx::Class;

=item L<Catalyst::Controller::ActionRole|Catalyst::Controller::ActionRole>

Apply roles to action instances

=cut

use Catalyst::Controller::ActionRole;

=item L<Catalyst::Controller::REST|Catalyst::Controller::REST>

A RESTful controller

=cut

use Catalyst::Controller::REST;

=item L<Catalyst::Devel|Catalyst::Devel>

Catalyst Development Tools

=cut

use Catalyst::Devel;

=item L<Catalyst::Log::Log4perl|Catalyst::Log::Log4perl>

DEPRECATED (see Log::Log4perl::Catalyst)

=cut

use Catalyst::Log::Log4perl;

=item L<Catalyst::Model::DBIC::Schema|Catalyst::Model::DBIC::Schema>

DBIx::Class::Schema Model Class

=cut

use Catalyst::Model::DBIC::Schema;

=item L<Catalyst::Plugin::Authorization::Roles|Catalyst::Plugin::Authorization::Roles>

Role based authorization for Catalyst based on Catalyst::Plugin::Authentication

=cut

use Catalyst::Plugin::Authorization::Roles;

=item L<Catalyst::Plugin::AutoCRUD|Catalyst::Plugin::AutoCRUD>

Instant AJAX web front-end for DBIx::Class

=cut

use Catalyst::Plugin::AutoCRUD;

=item L<Catalyst::Plugin::Browser|Catalyst::Plugin::Browser>

DEPRECATED: Browser Detection

=cut

use Catalyst::Plugin::Browser;

=item L<Catalyst::Plugin::Cache|Catalyst::Plugin::Cache>

Flexible caching support for Catalyst.

=cut

use Catalyst::Plugin::Cache;

=item L<Catalyst::Plugin::Cache::FastMmap|Catalyst::Plugin::Cache::FastMmap>

DEPRECATED FastMmap cache

=cut

use Catalyst::Plugin::Cache::FastMmap;

=item L<Catalyst::Plugin::ConfigLoader|Catalyst::Plugin::ConfigLoader>

Load config files of various types

=cut

use Catalyst::Plugin::ConfigLoader;

=item L<Catalyst::Plugin::HashedCookies|Catalyst::Plugin::HashedCookies>

Tamper-resistant HTTP Cookies

=cut

use Catalyst::Plugin::HashedCookies;

=item L<Catalyst::Plugin::Redirect|Catalyst::Plugin::Redirect>

Redirect for Catalyst used easily is offered.

=cut

use Catalyst::Plugin::Redirect;

=item L<Catalyst::Plugin::Session::State::Cookie|Catalyst::Plugin::Session::State::Cookie>

Maintain session IDs using cookies.

=cut

use Catalyst::Plugin::Session::State::Cookie;

=item L<Catalyst::Plugin::Session::Store::FastMmap|Catalyst::Plugin::Session::Store::FastMmap>

FastMmap session storage backend.

=cut

use Catalyst::Plugin::Session::Store::FastMmap;

=item L<Catalyst::Plugin::StackTrace|Catalyst::Plugin::StackTrace>

Display a stack trace on the debug screen

=cut

use Catalyst::Plugin::StackTrace;

=item L<Catalyst::Plugin::Static::Simple|Catalyst::Plugin::Static::Simple>

Make serving static pages painless.

=cut

use Catalyst::Plugin::Static::Simple;

=item L<Catalyst::Plugin::UploadProgress|Catalyst::Plugin::UploadProgress>

Realtime file upload information

=cut

use Catalyst::Plugin::UploadProgress;

=item L<Catalyst::View::TT|Catalyst::View::TT>

Template View Class

=cut

use Catalyst::View::TT;

=item L<DBIx::Class|DBIx::Class>

Extensible and flexible object &lt;-&gt; relational mapper.

=cut

use DBIx::Class;

=item L<DateTime::Format::Pg|DateTime::Format::Pg>

Parse and format PostgreSQL dates and times

=cut

use DateTime::Format::Pg;

=item L<FCGI|FCGI>

Fast CGI module

=cut

use FCGI;

=item L<Log::Dispatch|Log::Dispatch>

Dispatches messages to one or more outputs

=cut

use Log::Dispatch;

=item L<Net::OpenSSH|Net::OpenSSH>

Perl SSH client package implemented on top of OpenSSH

=cut

use Net::OpenSSH;

=item L<Net::SFTP::Foreign|Net::SFTP::Foreign>

SSH File Transfer Protocol client

=cut

use Net::SFTP::Foreign;

=item L<Net::Telnet|Net::Telnet>

interact with TELNET port or other TCP ports

=cut

use Net::Telnet;

=item L<forks|forks>

drop-in replacement for Perl threads using fork()

=cut

use forks;

=back

=head1 AUTHOR

cPanel, C<< <cpanel at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-task-cpanel-catalyst at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Task-Cpanel-Catalyst>.  We will be notified, and then you'll
automatically be notified of progress on your bug as we make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Task::Cpanel::Catalyst


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Task-Cpanel-Catalyst>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Task-Cpanel-Catalyst>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Task-Cpanel-Catalyst>

=item * Search CPAN

L<http://search.cpan.org/dist/Task-Cpanel-Catalyst/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 cPanel.

All rights reserved

http://cpanel.net

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. See L<perlartistic>.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Task::Cpanel::Catalyst
