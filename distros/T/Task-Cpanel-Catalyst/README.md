# NAME

Task::Cpanel::Catalyst - Provides a set of Catalyst modules

# SYNOPSIS

    cpan Task::Cpanel::Catalyst

# DESCRIPTION

This module provides a growing set of Catalyst modules useful to cPanel customers
who want to build/use Catalyst apps which run on a __cPanel & WHM__ system.

The first two numbers of this version (eg: 11.36) refer to the major version of
__cPanel & WHM__ it applies to.

We encourage customer feedback if you feel there are modules that would be useful
to you that are not already on this list.

## MODULES REQUIRED

- [Cache::FastMmap](http://search.cpan.org/perldoc?Cache::FastMmap)

Uses an mmap'ed file to act as a shared memory interprocess cache

- [Catalyst](http://search.cpan.org/perldoc?Catalyst)

The Elegant MVC Web Application Framework

- [Catalyst::ActionRole::ACL](http://search.cpan.org/perldoc?Catalyst::ActionRole::ACL)

User role-based authorization action class

- [Catalyst::Authentication::Store::DBIx::Class](http://search.cpan.org/perldoc?Catalyst::Authentication::Store::DBIx::Class)

A storage class for Catalyst Authentication using DBIx::Class

- [Catalyst::Controller::ActionRole](http://search.cpan.org/perldoc?Catalyst::Controller::ActionRole)

Apply roles to action instances

- [Catalyst::Controller::REST](http://search.cpan.org/perldoc?Catalyst::Controller::REST)

A RESTful controller

- [Catalyst::Devel](http://search.cpan.org/perldoc?Catalyst::Devel)

Catalyst Development Tools

- [Catalyst::Log::Log4perl](http://search.cpan.org/perldoc?Catalyst::Log::Log4perl)

DEPRECATED (see Log::Log4perl::Catalyst)

- [Catalyst::Model::DBIC::Schema](http://search.cpan.org/perldoc?Catalyst::Model::DBIC::Schema)

DBIx::Class::Schema Model Class

- [Catalyst::Plugin::Authorization::Roles](http://search.cpan.org/perldoc?Catalyst::Plugin::Authorization::Roles)

Role based authorization for Catalyst based on Catalyst::Plugin::Authentication

- [Catalyst::Plugin::AutoCRUD](http://search.cpan.org/perldoc?Catalyst::Plugin::AutoCRUD)

Instant AJAX web front-end for DBIx::Class

- [Catalyst::Plugin::Browser](http://search.cpan.org/perldoc?Catalyst::Plugin::Browser)

DEPRECATED: Browser Detection

- [Catalyst::Plugin::Cache](http://search.cpan.org/perldoc?Catalyst::Plugin::Cache)

Flexible caching support for Catalyst.

- [Catalyst::Plugin::Cache::FastMmap](http://search.cpan.org/perldoc?Catalyst::Plugin::Cache::FastMmap)

DEPRECATED FastMmap cache

- [Catalyst::Plugin::ConfigLoader](http://search.cpan.org/perldoc?Catalyst::Plugin::ConfigLoader)

Load config files of various types

- [Catalyst::Plugin::HashedCookies](http://search.cpan.org/perldoc?Catalyst::Plugin::HashedCookies)

Tamper-resistant HTTP Cookies

- [Catalyst::Plugin::Redirect](http://search.cpan.org/perldoc?Catalyst::Plugin::Redirect)

Redirect for Catalyst used easily is offered.

- [Catalyst::Plugin::Session::State::Cookie](http://search.cpan.org/perldoc?Catalyst::Plugin::Session::State::Cookie)

Maintain session IDs using cookies.

- [Catalyst::Plugin::Session::Store::FastMmap](http://search.cpan.org/perldoc?Catalyst::Plugin::Session::Store::FastMmap)

FastMmap session storage backend.

- [Catalyst::Plugin::StackTrace](http://search.cpan.org/perldoc?Catalyst::Plugin::StackTrace)

Display a stack trace on the debug screen

- [Catalyst::Plugin::Static::Simple](http://search.cpan.org/perldoc?Catalyst::Plugin::Static::Simple)

Make serving static pages painless.

- [Catalyst::Plugin::UploadProgress](http://search.cpan.org/perldoc?Catalyst::Plugin::UploadProgress)

Realtime file upload information

- [Catalyst::View::TT](http://search.cpan.org/perldoc?Catalyst::View::TT)

Template View Class

- [DBIx::Class](http://search.cpan.org/perldoc?DBIx::Class)

Extensible and flexible object &lt;-&gt; relational mapper.

- [DateTime::Format::Pg](http://search.cpan.org/perldoc?DateTime::Format::Pg)

Parse and format PostgreSQL dates and times

- [FCGI](http://search.cpan.org/perldoc?FCGI)

Fast CGI module

- [Log::Dispatch](http://search.cpan.org/perldoc?Log::Dispatch)

Dispatches messages to one or more outputs

- [Net::OpenSSH](http://search.cpan.org/perldoc?Net::OpenSSH)

Perl SSH client package implemented on top of OpenSSH

- [Net::SFTP::Foreign](http://search.cpan.org/perldoc?Net::SFTP::Foreign)

SSH File Transfer Protocol client

- [Net::Telnet](http://search.cpan.org/perldoc?Net::Telnet)

interact with TELNET port or other TCP ports

- [forks](http://search.cpan.org/perldoc?forks)

drop-in replacement for Perl threads using fork()

# AUTHOR

cPanel, `<cpanel at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-task-cpanel-catalyst at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Task-Cpanel-Catalyst](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Task-Cpanel-Catalyst).  We will be notified, and then you'll
automatically be notified of progress on your bug as we make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Task::Cpanel::Catalyst



You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

[http://rt.cpan.org/NoAuth/Bugs.html?Dist=Task-Cpanel-Catalyst](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Task-Cpanel-Catalyst)

- AnnoCPAN: Annotated CPAN documentation

[http://annocpan.org/dist/Task-Cpanel-Catalyst](http://annocpan.org/dist/Task-Cpanel-Catalyst)

- CPAN Ratings

[http://cpanratings.perl.org/d/Task-Cpanel-Catalyst](http://cpanratings.perl.org/d/Task-Cpanel-Catalyst)

- Search CPAN

[http://search.cpan.org/dist/Task-Cpanel-Catalyst/](http://search.cpan.org/dist/Task-Cpanel-Catalyst/)

# LICENSE AND COPYRIGHT

Copyright 2012 cPanel.

All rights reserved

http://cpanel.net

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. See [perlartistic](http://search.cpan.org/perldoc?perlartistic).

See http://dev.perl.org/licenses/ for more information.


