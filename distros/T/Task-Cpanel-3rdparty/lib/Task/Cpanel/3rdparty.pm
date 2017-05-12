# Copyright (c) 2012, cPanel, Inc.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.
package Task::Cpanel::3rdparty;
{
  $Task::Cpanel::3rdparty::VERSION = '11.36.001';
}

use strict;
use warnings;

=head1 NAME

Task::Cpanel::3rdparty - These modules are used for 3rdparty application development with B<cPanel & WHM>.

=head1 VERSION

version 11.36.001

=head1 SYNOPSIS

    cpan Task::Cpanel::3rdparty

=head1 DESCRIPTION

This package includes all of the needed CPAN modules requested by 3rdparty integrators.

The first two numbers of this version (eg: 11.36) refer to the major version of cPanel which it applies to.

=head2 MODULES NEEDED

=over

=item L<Class::Std::Utils|Class::Std::Utils>

Utility subroutines for building "inside-out" objects

=cut

use Class::Std::Utils;

=item L<CGI::Session|CGI::Session>

persistent session data in CGI applications

=cut

use CGI::Session;

=item L<Config::Crontab|Config::Crontab>

Read/Write Vixie compatible crontab(5) files

=cut

use Config::Crontab;

=item L<Config::General|Config::General>

Generic Config Module

=cut

use Config::General;

=item L<Convert::BinHex|Convert::BinHex>

extract data from Macintosh BinHex files

=cut

use Convert::BinHex;

=item L<Convert::TNEF|Convert::TNEF>

Perl module to read TNEF files

=cut

use Convert::TNEF;

=item L<DBD::SQLite|DBD::SQLite>

Self-contained RDBMS in a DBI Driver

=cut

use DBD::SQLite;

=item L<Date::Format|Date::Format>

Date formating subroutines

=cut

use Date::Format;

=item L<Date::Simple|Date::Simple>

a simple date object

=cut

use Date::Simple;

=item L<File::MimeInfo|File::MimeInfo>

Determine file type

=cut

use File::MimeInfo;

=item L<Gearman::Client|Gearman::Client>

Client for gearman distributed job system

=cut

use Gearman::Client;

=item L<HTML::StripTags|HTML::StripTags>

Strip HTML or XML tags from a string with Perl like PHP's strip_tags() does

=cut

use HTML::StripTags;

=item L<IO::Interactive|IO::Interactive>

Utilities for interactive I/O

=cut

use IO::Interactive;

=item L<IO::Socket::SSL|IO::Socket::SSL>

Nearly transparent SSL encapsulation for IO::Socket::INET.

=cut

use IO::Socket::SSL;

=item L<IO::Stringy|IO::Stringy>

I/O on in-core objects like strings and arrays

=cut

use IO::Stringy;

=item L<JSON|JSON>

JSON (JavaScript Object Notation) encoder/decoder

=cut

use JSON;

=item L<JSON::XS|JSON::XS>

JSON serialising/deserialising, done correctly and fast

=cut

use JSON::XS;

=item L<LWP::UserAgent|LWP::UserAgent>

Web user agent class

=cut

use LWP::UserAgent;

=item L<Mail::Header|Mail::Header>

manipulate MIME headers

=cut

use Mail::Header;

=item L<MIME::Tools|MIME::Tools>

modules for parsing (and creating!) MIME entities

=cut

use MIME::Tools;

=item L<Mozilla::CA|Mozilla::CA>

Mozilla's CA cert bundle in PEM format

=cut

use Mozilla::CA;

=item L<Net::CIDR|Net::CIDR>

Manipulate IPv4/IPv6 netblocks in CIDR notation

=cut

use Net::CIDR;

=item L<Net::DNS::SEC|Net::DNS::Sec>

DNSSEC extensions to Net::DNS

=cut

use Net::DNS::SEC;

=item L<Net::IP|Net::IP>

Perl extension for manipulating IPv4/IPv6 addresses

=cut

use Net::IP;

=item L<Net::Ident|Net::Ident>

lookup the username on the remote end of a TCP/IP connection

=cut

use Net::Ident;

=item L<NetAddr::IP|NetAddr::IP>

Manages IPv4 and IPv6 addresses and subnets

=cut

use NetAddr::IP;

=item L<Pod::Escapes|Pod::Escapes>

for resolving Pod E <...> sequences

=cut

use Pod::Escapes;

=item L<Proc::ProcessTable|Proc::ProcessTable>

Perl extension to access the unix process table

=cut

use Proc::ProcessTable;

=item L<SOAP::Lite|SOAP::Lite>

Perl's Web Services Toolkit

=cut

use SOAP::Lite;

=item L<Smart::Comments|Smart::Comments>

Comments that do more than just sit there

=cut

use Smart::Comments;

=item L<Sys::SigAction|Sys::SigAction>

Perl extension for Consistent Signal Handling

=cut

use Sys::SigAction;

=item L<Test::Pod|Test::Pod>

check for POD errors in files

=cut

use Test::Pod;

=item L<Unix::Syslog|Unix::Syslog>

Perl interface to the UNIX syslog(3) calls

=cut

use Unix::Syslog;

=item L<WWW::FieldValidator|WWW::FieldValidator>

Provides simple validation of user entered input

=cut

use WWW::FieldValidator;

=back

=head1 AUTHOR

cPanel, C<< <cpanel at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-task-cpanel-3rdparty at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Task-Cpanel-3rdparty>.  We will be notified, and then you'll
automatically be notified of progress on your bug as we make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Task::Cpanel::3rdparty


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Task-Cpanel-3rdparty>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Task-Cpanel-3rdparty>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Task-Cpanel-3rdparty>

=item * Meta CPAN

L<http://metapan.org/module/Task-Cpanel-3rdparty/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 cPanel.

All rights reserved

http://cpanel.net

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. See L<perlartistic>.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Task::Cpanel::3rdparty
