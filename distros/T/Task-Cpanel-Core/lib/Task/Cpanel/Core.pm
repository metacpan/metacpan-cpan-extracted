# Copyright (c) 2012, cPanel, Inc.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package Task::Cpanel::Core;
{
  $Task::Cpanel::Core::VERSION = '11.36.004';
}

use strict;
use warnings;

=head1 NAME

Task::Cpanel::Core - This module provides a spec of packages needed to operate a B<cPanel & WHM> system.

=head1 VERSION

version 11.36.004

=head1 SYNOPSIS

    cpan Task::Cpanel::Core

=head1 DESCRIPTION

This package includes all of the needed CPAN to run a B<cPanel & WHM> system.

The first two numbers of this version (eg: 11.36) refer to the major version of B<cPanel & WHM> system.  which it applies to.

=head2 MODULES REQUIRED

=over

=item L<Acme::Spork|Acme::Spork>

Perl extension for spork()ing in your script

=cut

use Acme::Spork;

=item L<Archive::Tar|Archive::Tar>

module for manipulations of tar archives

=cut

use Archive::Tar;

=item L<Archive::Tar::Streamed|Archive::Tar::Streamed>

Tar archives, non memory resident

=cut

use Archive::Tar::Streamed;

=item L<Archive::Zip|Archive::Zip>

Provide an interface to ZIP archive files.

=cut

use Archive::Zip;

=item L<Authen::Libwrap|Authen::Libwrap>

access to Wietse Venema's TCP Wrappers library

=cut

use Authen::Libwrap;

=item L<BSD::Resource|BSD::Resource>

BSD process resource limit and priority functions

=cut

use BSD::Resource;

=item L<Business::OnlinePayment::AuthorizeNet|Business::OnlinePayment::AuthorizeNet>

AuthorizeNet backend for Business::OnlinePayment

=cut

use Business::OnlinePayment::AuthorizeNet;

=item L<Business::UPS|Business::UPS>

A UPS Interface Module

=cut

use Business::UPS;

=item L<CDB_File|CDB_File>

Perl extension for access to cdb databases

=cut

use CDB_File;

=item L<CGI|CGI>

Handle Common Gateway Interface requests and responses

=cut

use CGI;

=item L<CPAN|CPAN>

query, download and build perl modules from CPAN sites

=cut

use CPAN;

=item L<CPAN::SQLite|CPAN::SQLite>

maintain and search a minimal CPAN database

=cut

use CPAN::SQLite;

=item L<Class::Accessor::Fast|Class::Accessor::Fast>

Faster, but less expandable, accessors

=cut

use Class::Accessor::Fast;

=item L<Class::Std|Class::Std>

Support for creating standard "inside-out" classes

=cut

use Class::Std;

=item L<Compress::Bzip2|Compress::Bzip2>

Interface to Bzip2 compression library

=cut

use Compress::Bzip2;

=item L<Compress::Raw::Zlib|Compress::Raw::Zlib>

Low-Level Interface to zlib compression library

=cut

use Compress::Raw::Zlib;

=item L<Compress::Zlib|Compress::Zlib>

Interface to zlib compression library

=cut

use Compress::Zlib;

=item L<Crypt::GPG|Crypt::GPG>

An Object Oriented Interface to GnuPG.

=cut

use Crypt::GPG;

=item L<Crypt::Passwd::XS|Crypt::Passwd::XS>

Full XS implementation of common crypt() algorithms

=cut

use Crypt::Passwd::XS;

=item L<Crypt::SSLeay|Crypt::SSLeay>

OpenSSL support for LWP

=cut

use Crypt::SSLeay;

=item L<Curses|Curses>

terminal screen handling and optimization

=cut

use Curses;

=item L<Curses::UI|Curses::UI>

A curses based OO user interface framework

=cut

use Curses::UI;

=item L<Cwd|Cwd>

get pathname of current working directory

=cut

use Cwd;

=item L<Data::MessagePack|Data::MessagePack>

MessagePack serialising/deserialising

=cut

use Data::MessagePack;

=item L<DBD::SQLite2|DBD::SQLite2>

Self Contained RDBMS in a DBI Driver (sqlite 2.x)

=cut

use DBD::SQLite2;

=item L<DBD::mysql|DBD::mysql>

MySQL driver for the Perl5 Database Interface (DBI)

=cut

use DBD::mysql;

=item L<DBI|DBI>

Database independent interface for Perl

=cut

use DBI;

=item L<DBIx::MyParsePP|DBIx::MyParsePP>

Pure-perl SQL parser based on MySQL grammar and lexer

=cut

use DBIx::MyParsePP;

=item L<Data::Dump|Data::Dump>

Pretty printing of data structures

=cut

use Data::Dump;

=item L<Data::Dumper|Data::Dumper>

stringified perl data structures, suitable for both printing and eval

=cut

use Data::Dumper;

=item L<Date::Parse|Date::Parse>

Parse date strings into time values

=cut

use Date::Parse;

=item L<DateTime|DateTime>

A date and time object

=cut

use DateTime;

=item L<DateTime::Locale|DateTime::Locale>

Localization support for DateTime.pm

=cut

use DateTime::Locale;

=item L<DateTime::TimeZone|DateTime::TimeZone>

Time zone object base class and factory

=cut

use DateTime::TimeZone;

=item L<Devel::PPPort|Devel::PPPort>

Perl/Pollution/Portability

=cut

use Devel::PPPort;

=item L<Digest::MD5|Digest::MD5>

Perl interface to the MD5 Algorithm

=cut

use Digest::MD5;

=item L<Digest::MD5::File|Digest::MD5::File>

Perl extension for getting MD5 sums for files and urls.

=cut

use Digest::MD5::File;

=item L<Digest::SHA1|Digest::SHA1>

Perl interface to the SHA-1 algorithm

=cut

use Digest::SHA1;

=item L<Email::Valid|Email::Valid>

Check validity of Internet email addresses

=cut

use Email::Valid;

=item L<Encode|Encode>

character encodings in Perl

=cut

use Encode;

=item L<Encode::Detect::Detector|Encode::Detect::Detector>

Detects the encoding of data

=cut

use Encode::Detect::Detector;

=item L<Errno|Errno>

System errno constants

=cut

use Errno;

=item L<ExtUtils::Constant|ExtUtils::Constant>

generate XS code to import C header constants

=cut

use ExtUtils::Constant;

=item L<ExtUtils::Install|ExtUtils::Install>

install files from here to there

=cut

use ExtUtils::Install;

=item L<ExtUtils::MakeMaker|ExtUtils::MakeMaker>

Create a module Makefile

=cut

use ExtUtils::MakeMaker;

=item L<ExtUtils::ParseXS|ExtUtils::ParseXS>

converts Perl XS code into C code

=cut

use ExtUtils::ParseXS;

=item L<File::Copy::Recursive|File::Copy::Recursive>

Perl extension for recursively copying files and directories

=cut

use File::Copy::Recursive;

=item L<File::Find::Rule|File::Find::Rule>

Alternative interface to File::Find

=cut

use File::Find::Rule;

=item L<File::MMagic::XS|File::MMagic::XS>

Guess File Type With XS (a la mod_mime_magic)

=cut

use File::MMagic::XS;

=item L<File::Tail|File::Tail>

Perl extension for reading from continously updated files

=cut

use File::Tail;

=item L<File::Touch|File::Touch>

update access and modification timestamps, creating nonexistent files where necessary.

=cut

use File::Touch;

=item L<File::Which|File::Which>

Portable implementation of the `which&#39; utility

=cut

use File::Which;

=item L<Filesys::Df|Filesys::Df>

Perl extension for filesystem disk space information.

=cut

use Filesys::Df;

=item L<Filesys::Statvfs|Filesys::Statvfs>

Perl extension for statvfs() and fstatvfs()

=cut

use Filesys::Statvfs;

=item L<Filesys::Virtual|Filesys::Virtual>

Perl extension to provide a framework for a virtual filesystem

=cut

use Filesys::Virtual;

=item L<Filter::Util::Call|Filter::Util::Call>

Perl Source Filter Utility Module

=cut

use Filter::Util::Call;

=item L<GD::Graph|GD::Graph>

Graph Plotting Module for Perl 5

=cut

use GD::Graph;

=item L<GD::Text::Align|GD::Text::Align>

Draw aligned strings

=cut

use GD::Text::Align;

=item L<Geo::IPfree|Geo::IPfree>

Look up the country of an IPv4 address

=cut

use Geo::IPfree;

=item L<Getopt::Long|Getopt::Long>

Extended processing of command line options

=cut

use Getopt::Long;

=item L<Getopt::Param::Tiny|Getopt::Param::Tiny>

Subset of Getopt::Param functionality with smaller memory footprint

=cut

use Getopt::Param::Tiny;

=item L<Graph::Easy|Graph::Easy>

Convert or render graphs (as ASCII, HTML, SVG or via Graphviz)

=cut

use Graph::Easy;

=item L<Graph::Flowchart|Graph::Flowchart>

Generate easily flowcharts as Graph::Easy objects

=cut

use Graph::Flowchart;

=item L<HTML::Parser|HTML::Parser>

HTML parser class

=cut

use HTML::Parser;

=item L<HTML::Tagset|HTML::Tagset>

data tables useful in parsing HTML

=cut

use HTML::Tagset;

=item L<HTML::Template|HTML::Template>

Perl module to use HTML-like templating language

=cut

use HTML::Template;

=item L<HTTP::Daemon::App|HTTP::Daemon::App>

Create 2 or 3 line, fully functional (SSL) HTTP server(s)

=cut

use HTTP::Daemon::App;

=item L<HTTP::Date|HTTP::Date>

date conversion routines

=cut

use HTTP::Date;

=item L<IO::Compress::Gzip|IO::Compress::Gzip>

Write RFC 1952 files/buffers

=cut

use IO::Compress::Gzip;

=item L<IO::Interactive::Tiny|IO::Interactive::Tiny>

is_interactive() without large deps

=cut

use IO::Interactive::Tiny;

=item L<IO::Scalar|IO::Scalar>

IO:: interface for reading/writing a scalar

=cut

use IO::Scalar;

=item L<IO::Socket::ByteCounter|IO::Socket::ByteCounter>

Perl extension to track the byte sizes of data in and out of a socket

=cut

use IO::Socket::ByteCounter;

=item L<IO::Socket::INET6|IO::Socket::INET6>

Object interface for AF_INET|AF_INET6 domain sockets

=cut

use IO::Socket::INET6;

=item L<IO::Tty|IO::Tty>

Low-level allocate a pseudo-Tty, import constants.

=cut

use IO::Tty;

=item L<IO::Uncompress::Gunzip|IO::Uncompress::Gunzip>

Read RFC 1952 files/buffers

=cut

use IO::Uncompress::Gunzip;

=item L<IP::Country|IP::Country>

fast lookup of country codes from IP addresses

=cut

use IP::Country;

=item L<IPC::Pipeline|IPC::Pipeline>

Create a shell-like pipeline of many running commands

=cut

use IPC::Pipeline;

=item L<Image::Size|Image::Size>

read the dimensions of an image in several popular formats

=cut

use Image::Size;

=item L<JSON::Syck|JSON::Syck>

JSON is YAML (but consider using JSON::XS instead!)

=cut

use JSON::Syck;

=item L<LWP::Protocol::https|LWP::Protocol::https>

Provide https support for LWP::UserAgent

=cut

use LWP::Protocol::https;

=item L<Lchown|Lchown>

Use the lchown(2) system call from Perl

=cut

use Lchown;

=item L<Linux::Inotify2|Linux::Inotify2>

scalable directory/file change notification

=cut

use Linux::Inotify2;

=item L<List::MoreUtils|List::MoreUtils>

Provide the stuff missing in List::Util

=cut

use List::MoreUtils;

=item L<List::Util|List::Util>

A selection of general-utility list subroutines

=cut

use List::Util;

=item L<Locale::Maketext::Utils|Locale::Maketext::Utils>

Adds some utility functionality and failure handling to Local::Maketext handles

=cut

use Locale::Maketext::Utils;

=item L<Locales|Locales>

Methods for getting localized CLDR language/territory names (and a subset of other data)

=cut

use Locales;

=item L<Log::Log4perl|Log::Log4perl>

Log4j implementation for Perl

=cut

use Log::Log4perl;

=item L<MD5|MD5>

Perl interface to the MD5 Message-Digest Algorithm

=cut

use MD5;

=item L<MIME::Base64|MIME::Base64>

Encoding and decoding of base64 strings

=cut

use MIME::Base64;

=item L<MIME::Lite|MIME::Lite>

low-calorie MIME generator

=cut

use MIME::Lite;

=item L<Mail::Alias::Reader|Mail::Alias::Reader>

Read aliases(5) and ~/.forward declarations

=cut

use Mail::Alias::Reader;

=item L<Mail::DKIM|Mail::DKIM>

Signs/verifies Internet mail with DKIM/DomainKey signatures

=cut

use Mail::DKIM;

=item L<Mail::DomainKeys|Mail::DomainKeys>

A perl implementation of DomainKeys

=cut

use Mail::DomainKeys;

=item L<Mail::SPF|Mail::SPF>

An object-oriented implementation of Sender Policy Framework

=cut

use Mail::SPF;

=item L<Mail::SRS|Mail::SRS>

Interface to Sender Rewriting Scheme

=cut

use Mail::SRS;

=item L<Mail::SpamAssassin|Mail::SpamAssassin>

Spam detector and markup engine

=cut

use Mail::SpamAssassin;

=item L<Math::Base85|Math::Base85>

Perl extension for base 85 numbers, as referenced by RFC 1924

=cut

use Math::Base85;

=item L<Math::BigFloat|Math::BigFloat>

Arbitrary size floating point math package

=cut

use Math::BigFloat;

=item L<Math::BigInt|Math::BigInt>

Arbitrary size integer/float math package

=cut

use Math::BigInt;

=item L<Memoize|Memoize>

Make functions faster by trading space for time

=cut

use Memoize;

=item L<Module::Build|Module::Build>

Build and install Perl modules

=cut

use Module::Build;

=item L<MySQL::Diff|MySQL::Diff>

Generates a database upgrade instruction set

=cut

use MySQL::Diff;

=item L<Net::AIM|Net::AIM>

Perl extension for AOL Instant Messenger TOC protocol

=cut

use Net::AIM;

=item L<NetAddr::IP|NetAddr::IP>

Manages IPv4 and IPv6 addresses and subnets

=cut

use NetAddr::IP;

=item L<Net::DAV::Server|Net::DAV::Server>

Provide a DAV Server

=cut

use Net::DAV::Server;

=item L<Net::DNS|Net::DNS>

Perl interface to the Domain Name System

=cut

use Net::DNS;

=item L<Net::Daemon::SSL|Net::Daemon::SSL>

perl extensions for portable ssl daemons

=cut

use Net::Daemon::SSL;

=item L<Net::FTP|Net::FTP>

FTP Client class

=cut

use Net::FTP;

=item L<Net::FTPSSL|Net::FTPSSL>

A FTP over SSL/TLS class

=cut

use Net::FTPSSL;

=item L<Net::IP::Match::Regexp|Net::IP::Match::Regexp>

Efficiently match IP addresses against ranges

=cut

use Net::IP::Match::Regexp;

=item L<Net::IPv4Addr|Net::IPv4Addr>

Perl extension for manipulating IPv4 addresses.

=cut

use Net::IPv4Addr;

=item L<Net::LDAP|Net::LDAP>

Lightweight Directory Access Protocol

=cut

use Net::LDAP;

=item L<Net::LDAP::Schema|Net::LDAP::Schema>

Load and manipulate an LDAP v3 Schema

=cut

use Net::LDAP::Schema;

=item L<Net::LDAP::Server|Net::LDAP::Server>

LDAP server side protocol handling

=cut

use Net::LDAP::Server;

=item L<Net::LibIDN|Net::LibIDN>

Perl bindings for GNU Libidn

=cut

use Net::LibIDN;

=item L<Net::OSCAR|Net::OSCAR>

Implementation of AOL's OSCAR protocol for instant messaging (for interacting with AIM a.k.a. AOL IM a.k.a. AOL Instant Messenger - and ICQ, too!)

=cut

use Net::OSCAR;

=item L<Net::SNMP|Net::SNMP>

Object oriented interface to SNMP

=cut

use Net::SNMP;

=item L<Net::SSL|Net::SSL>

support for Secure Sockets Layer

=cut

use Net::SSL;

=item L<Net::SSLeay|Net::SSLeay>

Perl extension for using OpenSSL

=cut

use Net::SSLeay;

=item L<Net::Server|Net::Server>

Extensible, general Perl server engine

=cut

use Net::Server;

=item L<Net::Server::Fork|Net::Server::Fork>

Net::Server personality

=cut

use Net::Server::Fork;

=item L<OLE::Storage_Lite|OLE::Storage_Lite>

Simple Class for OLE document interface.

=cut

use OLE::Storage_Lite;

=item L<Parse::RecDescent|Parse::RecDescent>

Generate Recursive-Descent Parsers

=cut

use Parse::RecDescent;

=item L<Pod::Perldoc|Pod::Perldoc>

Look up Perl documentation in Pod format.

=cut

use Pod::Perldoc;

=item L<Quota|Quota>

Perl interface to file system quotas

=cut

use Quota;

=item L<SQL::Statement|SQL::Statement>

SQL parsing and processing engine

=cut

use SQL::Statement;

=item L<SVG::TT::Graph|SVG::TT::Graph>

Base object for generating SVG Graphs

=cut

use SVG::TT::Graph;

=item L<Safe::Hole|Safe::Hole>

make a hole to the original main compartment in the Safe compartment

=cut

use Safe::Hole;

=item L<Scalar::Util|Scalar::Util>

A selection of general-utility scalar subroutines

=cut

use Scalar::Util;

=item L<Set::Crontab|Set::Crontab>

Expand crontab(5)-style integer lists

=cut

use Set::Crontab;

=item L<Socket6|Socket6>

IPv6 related part of the C socket.h defines and structure manipulators

=cut

use Socket6;

=item L<Spreadsheet::ParseExcel|Spreadsheet::ParseExcel>

Read information from an Excel file.

=cut

use Spreadsheet::ParseExcel;

=item L<Spreadsheet::WriteExcel|Spreadsheet::WriteExcel>

Write to a cross-platform Excel binary file.

=cut

use Spreadsheet::WriteExcel;

=item L<Storable|Storable>

persistence for Perl data structures

=cut

use Storable;

=item L<String::CRC32|String::CRC32>

Perl interface for cyclic redundency check generation

=cut

use String::CRC32;

=item L<Sys::Hostname::Long|Sys::Hostname::Long>

Try every conceivable way to get full hostname

=cut

use Sys::Hostname::Long;

=item L<Sys::Mmap|Sys::Mmap>

uses mmap to map in a file as a Perl variable

=cut

use Sys::Mmap;

=item L<Sys::Syslog|Sys::Syslog>

Perl interface to the UNIX syslog(3) calls

=cut

use Sys::Syslog;

=item L<Term::ReadKey|Term::ReadKey>

A perl module for simple terminal control

=cut

use Term::ReadKey;

=item L<TAP::Harness|TAP::Harness>

Run test scripts with statistics

=cut

use TAP::Harness;

=item L<Template|Template>

Template Toolkit Processing System

=cut

use Template;

=item L<Text::CSV|Text::CSV>

comma-separated values manipulator (using XS or PurePerl)

=cut

use Text::CSV;

=item L<Text::Query|Text::Query>

Query processing framework

=cut

=item L<Tie::DBI|Tie::DBI>

Tie hashes to DBI relational databases

=cut

use Tie::DBI;

=item L<Tie::IxHash|Tie::IxHash>

ordered associative arrays for Perl

=cut

use Tie::IxHash;

=item L<Tie::ShadowHash|Tie::ShadowHash>

Merge multiple data sources into a hash

=cut

use Tie::ShadowHash;

=item L<Time::HiRes|Time::HiRes>

High resolution alarm, sleep, gettimeofday, interval timers

=cut

use Time::HiRes;

=item L<Tree::MultiNode|Tree::MultiNode>

A multi-node tree object. Most useful for modeling hierarchical data structures.

=cut

use Tree::MultiNode;

=item L<URI|URI>

Uniform Resource Identifiers (absolute and relative)

=cut

use URI;

=item L<URI::Escape|URI::Escape>

Percent-encode and percent-decode unsafe characters

=cut

use URI::Escape;

=item L<URI::URL|URI::URL>

Uniform Resource Locators

=cut

use URI::URL;

=item L<Unix::PID|Unix::PID>

Perl extension for getting PID info.

=cut

use Unix::PID;

=item L<Unix::PID::Tiny|Unix::PID::Tiny>

Subset of Unix::PID functionality with smaller memory footprint

=cut

use Unix::PID::Tiny;

=item L<XML::LibXML|XML::LibXML>

Perl Binding for libxml2

=cut

use XML::LibXML;

=item L<XML::LibXML::Common|XML::LibXML::Common>

Constants and Character Encoding Routines

=cut

use XML::LibXML::Common;

=item L<XML::LibXML::Error|XML::LibXML::Error>

Structured Errors

=cut

use XML::LibXML::Error;

=item L<XML::Parser|XML::Parser>

A perl module for parsing XML documents

=cut

use XML::Parser;

=item L<XML::SAX|XML::SAX>

Simple API for XML

=cut

use XML::SAX;

=item L<XML::SAX::Expat|XML::SAX::Expat>

SAX2 Driver for Expat (XML::Parser)

=cut

use XML::SAX::Expat;

=item L<XML::Simple|XML::Simple>

Easy API to maintain XML (esp config files)

=cut

use XML::Simple;

=item L<YAML::Syck|YAML::Syck>

Fast, lightweight YAML loader and dumper

=cut

use YAML::Syck;

=item L<cPanel::MemTest|cPanel::MemTest>

Test Memory Allocation

=cut

use cPanel::MemTest;

=item L<lib::restrict|lib::restrict>

Perl extension for restricting what goes into @INC

=cut

use lib::restrict;

=item L<local::lib|local::lib>

create and use a local lib/ for perl modules with PERL5LIB

=cut

use local::lib;

=back

=head1 AUTHOR

cPanel, C<< <cpanel at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-task-cpanel-core at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Task-Cpanel-Core>.  We will be notified, and then you'll
automatically be notified of progress on your bug as we make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Task::Cpanel::Core


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Task-Cpanel-Core>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Task-Cpanel-Core>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Task-Cpanel-Core>

=item * Meta CPAN

L<http://metacpan.org/module/Task-Cpanel-Core/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2012 cPanel.

All rights reserved

http://cpanel.net

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. See L<perlartistic>.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Task::Cpanel::Core
