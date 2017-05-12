# Copyright (c) 2012, cPanel, Inc.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.
package Task::Cpanel::Internal;
{
  $Task::Cpanel::Internal::VERSION = '11.36.001';
}

use strict;
use warnings;

=head1 NAME

Task::Cpanel::Internal - These modules are used for internal cPanel development.

=head1 VERSION

version 11.36.001

=head1 SYNOPSIS

    cpan Task::Cpanel::Internal

=head1 DESCRIPTION

This package includes all of the needed CPAN modules for B<cPanel & WHM> development
by cPanel.

They are not necessarily needed for anything on a B<cPanel & WHM> installation, but
you may find them helpful during your own perl development.

The first two numbers of this version (eg: 11.36) refer to the major version of
cPanel which it applies to.

=head2 MODULES REQUIRED

=over

=item L<Acme::Bleach|Acme::Bleach>

For really clean programs

=cut

use Acme::Bleach;

=item L<App::Ack|App::Ack>

A container for functions for the ack program

=cut

use App::Ack;

=item L<Archive::Any|Archive::Any>

Single interface to deal with file archives.

=cut

use Archive::Any;

=item L<Archive::Tar|Archive::Tar>

module for manipulations of tar archives

=cut

use Archive::Tar;

=item L<Archive::Tar::Builder|Archive::Tar::Builder>

Stream tarball data to a file handle

=cut

use Archive::Tar::Builder;

=item L<Authen::Libwrap|Authen::Libwrap>

access to Wietse Venema's TCP Wrappers library

=cut

use Authen::Libwrap;

=item L<B::C|B::C>

Perl compiler's C backend

=cut

use B::C;

=item L<B::Flags|B::Flags>

Friendlier flags for B

=cut

use B::Flags;

=item L<BSD::Resource|BSD::Resource>

BSD process resource limit and priority functions

=cut

use BSD::Resource;

=item L<Business::ISBN|Business::ISBN>

work with International Standard Book Numbers

=cut

use Business::ISBN;

=item L<Capture::Tiny|Capture::Tiny>

Capture STDOUT and STDERR from Perl, XS or external programs

=cut

use Capture::Tiny;

=item L<Class::C3|Class::C3>

A pragma to use the C3 method resolution order algortihm

=cut

use Class::C3;

=item L<Class::Inspector|Class::Inspector>

Get information about a class and its structure

=cut

use Class::Inspector;

=item L<Compress::Zlib|Compress::Zlib>

Interface to zlib compression library

=cut

use Compress::Zlib;

=item L<Crypt::DES_EDE3|Crypt::DES_EDE3>

Triple-DES EDE encryption/decryption

=cut

use Crypt::DES_EDE3;

=item L<Crypt::OpenPGP|Crypt::OpenPGP>

Pure-Perl OpenPGP implementation

=cut

use Crypt::OpenPGP;

=item L<Crypt::Random|Crypt::Random>

Cryptographically Secure, True Random Number Generator.

=cut

use Crypt::Random;

=item L<Cwd|Cwd>

get pathname of current working directory

=cut

use Cwd;

=item L<DBD::Mock|DBD::Mock>

Mock database driver for testing

=cut

use DBD::Mock;

=item L<DBD::Pg|DBD::Pg>

PostgreSQL database driver for the DBI module

=cut

use DBD::Pg;

=item L<DBI|DBI>

Database independent interface for Perl

=cut

use DBI;

=item L<Date::Parse|Date::Parse>

Parse date strings into time values

=cut

use Date::Parse;

=item L<DateTime|DateTime>

A date and time object

=cut

use DateTime;

=item L<Devel::Cover|Devel::Cover>

Code coverage metrics for Perl

=cut

use Devel::Cover;

=item L<Devel::NYTProf|Devel::NYTProf>

Powerful fast feature-rich perl source code profiler

=cut

use Devel::NYTProf;

=item L<Devel::REPL|Devel::REPL>

a modern perl interactive shell

=cut

use Devel::REPL;

=item L<Devel::Size|Devel::Size>

Perl extension for finding the memory usage of Perl variables

=cut

use Devel::Size;

=item L<Diff::LibXDiff|Diff::LibXDiff>

Calculate a diff with LibXDiff (via XS)

=cut

use Diff::LibXDiff;

=item L<Digest::MD5|Digest::MD5>

Perl interface to the MD5 Algorithm

=cut

use Digest::MD5;

=item L<Dist::Zilla::Plugin::Repository|Dist::Zilla::Plugin::Repository>

Publish repo information into META for a dzil distro.

=cut

use Dist::Zilla::Plugin::Repository;

=item L<Dist::Zilla::PluginBundle::Git|Dist::Zilla::PluginBundle::Git>

Git related utilities for building dzil modules.

=cut

use Dist::Zilla::PluginBundle::Git;

=item L<Dist::Zilla::Plugin::GitHub::Meta|Dist::Zilla::Plugin::GitHub::Meta>

Utilities for publishing dzil modules to Github

=cut

use Dist::Zilla::Plugin::GitHub::Meta;

=item L<Email::Address|Email::Address>

RFC 2822 Address Parsing and Creation

=cut

use Email::Address;

=item L<Encode::Detect|Encode::Detect>

An Encode::Encoding subclass that detects the encoding of data

=cut

use Encode::Detect;

=item L<Expect|Expect>

Expect for Perl

=cut

use Expect;

=item L<Error|Error>

Error/exception handling in an OO-ish way

=cut

use Error;

=item L<ExtUtils::CBuilder|ExtUtils::CBuilder>

Compile and link C code for Perl modules

=cut

use ExtUtils::CBuilder;

=item L<ExtUtils::Constant|ExtUtils::Constant>

generate XS code to import C header constants

=cut

use ExtUtils::Constant;

=item L<File::Comments|File::Comments>

Recognizes file formats and extracts format-specific comments

=cut

use File::Comments;

=item L<File::Comments::Plugin::C|File::Comments::Plugin::C>

Plugin to detect comments in C/C++ source code

=cut

use File::Comments::Plugin::C;

=item L<File::Copy::Recursive|File::Copy::Recursive>

Perl extension for recursively copying files and directories

=cut

use File::Copy::Recursive;

=item L<File::Glob|File::Glob>

Perl extension for BSD glob routine

=cut

use File::Glob;

=item L<File::Path::Tiny|File::Path::Tiny>

recursive versions of mkdir() and rmdir() without as much overhead as File::Path

=cut

use File::Path::Tiny;

=item L<File::Which|File::Which>

Portable implementation of the which utility

=cut

use File::Which;

=item L<Filesys::Df|Filesys::Df>

Perl extension for filesystem disk space information.

=cut

use Filesys::Df;

=item L<Filesys::POSIX>

Provide POSIX-like filesystem semantics in pure Perl

=cut

use Filesys::POSIX;

=item L<Filter::Util::Call|Filter::Util::Call>

Perl Source Filter Utility Module

=cut

use Filter::Util::Call;

=item L<GSSAPI|GSSAPI>

Perl extension providing access to the GSSAPIv2 library

=cut

use GSSAPI;

=item L<Getopt::Euclid|Getopt::Euclid>

Executable Uniform Command-Line Interface Descriptions

=cut

use Getopt::Euclid;

=item L<Getopt::Param|Getopt::Param>

param() style opt handling

=cut

use Getopt::Param;

=item L<Git::Repository|Git::Repository>

Perl interface to Git repositories

=cut

use Git::Repository;

=item L<Git::Wrapper|Git::Wrapper>

Wrap git(7) command-line interface

=cut

use Git::Wrapper;

=item L<Graph::Easy::As_svg|Graph::Easy::As_svg>

Output a Graph::Easy as Scalable Vector Graphics (SVG)

=cut

use Graph::Easy::As_svg;

=item L<Graph::Easy::Manual|Graph::Easy::Manual>

HTML manual for Graph::Easy

=cut

use Graph::Easy::Manual;

=item L<IO::AIO|IO::AIO>

Asynchronous Input/Output

=cut

use IO::AIO;

=item L<IO::Interface|IO::Interface>

Perl extension for access to network card configuration information

=cut

use IO::Interface;

=item L<IO::Prompt|IO::Prompt>

Interactively prompt for user input

=cut

use IO::Prompt;

=item L<IO::Tty|IO::Tty>

Low-level allocate a pseudo-Tty, import constants.

=cut

use IO::Tty;

=item L<Image::Xbm|Image::Xbm>

Load, create, manipulate and save xbm image files.

=cut

use Image::Xbm;

=item L<Image::Xpm|Image::Xpm>

Load, create, manipulate and save xpm image files.

=cut

use Image::Xpm;

=item L<JSON::XS|JSON::XS>

JSON serialising/deserialising, done correctly and fast

=cut

use JSON::XS;

=item L<Log::Log4perl|Log::Log4perl>

Log4j implementation for Perl

=cut

use Log::Log4perl;

=item L<Mail::SendEasy|Mail::SendEasy>

Send plain/html e-mails through SMTP servers (platform independent). Supports SMTP authentication and attachments.

=cut

use Mail::SendEasy;

=item L<Mail::Sender::Easy|Mail::Sender::Easy>

Super Easy to use simplified interface to Mail::Sender&#39;s excellentness

=cut

use Mail::Sender::Easy;

=item L<Math::BigInt::GMP|Math::BigInt::GMP>

Use the GMP library for Math::BigInt routines

=cut

use Math::BigInt::GMP;

=item L<Math::BigInt::Pari|Math::BigInt::Pari>

Use Math::Pari for Math::BigInt routines

=cut

use Math::BigInt::Pari;

=item L<Math::Pari|Math::Pari>

Perl interface to PARI.

=cut

use Math::Pari;

=item L<Math::Round|Math::Round>

Perl extension for rounding numbers

=cut

use Math::Round;

=item L<Module::Extract::VERSION|Module::Extract::VERSION>

Extract a module version without running code

=cut

use Module::Extract::VERSION;

=item L<Module::Install|Module::Install>

Standalone, extensible Perl module installer

=cut

use Module::Install;

=item L<Module::Metadata|Module::Metadata>

Gather package and POD information from perl module files

=cut

use Module::Metadata;

=item L<Module::Signature|Module::Signature>

Module signature file manipulation

=cut

use Module::Signature;

=item L<Module::Want|Module::Want>

Check @INC once for modules that you want but may not have

=cut

use Module::Want;

=item L<Moo|Moo>

Minimalist Object Orientation (with Moose compatiblity)

=cut

use Moo;

=item L<Moose|Moose>

A postmodern object system for Perl 5

=cut

use Moose;

=item L<Net::Ident|Net::Ident>

lookup the username on the remote end of a TCP/IP connection

=cut

use Net::Ident;

=item L<Net::Jabber::Bot|Net::Jabber::Bot>

Automated Bot creation with safeties

=cut

use Net::Jabber::Bot;

=item L<Net::OpenSSH|Net::OpenSSH>

Perl SSH client package implemented on top of OpenSSH

=cut

use Net::OpenSSH;

=item L<Net::SSLeay|Net::SSLeay>

Perl extension for using OpenSSL

=cut

use Net::SSLeay;

=item L<Net::TCPwrappers|Net::TCPwrappers>

Perl interface to tcp_wrappers.

=cut

use Net::TCPwrappers;

=item L<Opcodes|Opcodes>

More Opcodes information from opnames.h and opcode.h

=cut

use Opcodes;

=item L<Path::Iter|Path::Iter>

Simple Efficient Path Iteration

=cut

use Path::Iter;

=item L<Perl::Tidy|Perl::Tidy>

Parses and beautifies perl source

=cut

use Perl::Tidy;

=item L<Perlbal|Perlbal>

Reverse-proxy load balancer and webserver

=cut

use Perlbal;

=item L<Pristine::Tar|Pristine::Tar>

regenerate a pristine upstream tarball using only a small binary delta file and a copy of the source

=cut

use Pod::Markdown

=item L<Pod::Markdown|Pod::Markdown>

Converts POD to Markdown in order to generate README.md files on github

=cut

use Pristine::Tar;

=item L<REST::Google::Translate|REST::Google::Translate>

OO interface to Google Translate (aka Languages) API

=cut

use REST::Google::Translate;

=item L<REST::Google::Translate2|REST::Google::Translate2>

OO interface to Google Translate API v2

=cut

use REST::Google::Translate2;

=item L<Readonly::XS|Readonly::XS>

Companion module for Readonly.pm, to speed up read-only scalar variables.

=cut

use Readonly::XS;

=item L<Regexp::Parser|Regexp::Parser>

base class for parsing regexes

=cut

use Regexp::Parser;

=item L<SOAP::Lite|SOAP::Lite>

Perl's Web Services Toolkit

=cut

use SOAP::Lite;

=item L<Storable|Storable>

persistence for Perl data structures

=cut

use Storable;

=item L<String::BOM|String::BOM>

simple utilities to check for a BOM and strip a BOM

=cut

use String::BOM;

=item L<String::CRC32|String::CRC32>

Perl interface for cyclic redundency check generation

=cut

use String::CRC32;

=item L<Sub::Install|Sub::Install>

install subroutines into packages easily

=cut

use Sub::Install;

=item L<Test::Class|Test::Class>

Easily create test classes in an xUnit/JUnit style

=cut

use Test::Class;

=item L<Test::CPAN::Meta|Test::CPAN::Meta>

Validation of the META.yml file in a CPAN distribution.

=cut

use Test::CPAN::Meta;

=item L<Test::Exception|Test::Exception>

Test exception based code

=cut

use Test::Exception;

=item L<Test::File::Contents|Test::File::Contents>

Test routines for examining the contents of files

=cut

use Test::File::Contents;

=item L<Test::Manifest|Test::Manifest>

interact with a t/test_manifest file

=cut

use Test::Manifest;

=item L<Test::MinimumVersion|Test::MinimumVersion>

does your code require newer perl than you think?

=cut

use Test::MinimumVersion;

=item L<Test::Mock::Cmd|Test::Mock::Cmd>

Mock system(), exec(), and qx() for testing

=cut

use Test::Mock::Cmd;

=item L<Test::MockModule|Test::MockModule>

Override subroutines in a module for unit testing

=cut

use Test::MockModule;

=item L<Test::MockObject|Test::MockObject>

Perl extension for emulating troublesome interfaces

=cut

use Test::MockObject;

=item L<Test::NoWarnings|Test::NoWarnings>

Make sure you didn't emit any warnings while testing

=cut

use Test::NoWarnings;

=item L<Test::Object|Test::Object>

Thoroughly testing objects via registered handlers

=cut

use Test::Object;

=item L<Test::Output|Test::Output>

Utilities to test STDOUT and STDERR messages.

=cut

use Test::Output;

=item L<Test::Parallel>

simple object interface to launch unit test in parallel

=cut

use Test::Parallel;

=item L<Test::Pod|Test::Pod>

check for POD errors in files

=cut

use Test::Pod;

=item L<Test::Pod::Coverage|Test::Pod::Coverage>

Check for pod coverage in your distribution.

=cut

use Test::Pod::Coverage;

=item L<Test::Script|Test::Script>

Basic cross-platform tests for scripts

=cut

use Test::Script;

=item L<Test::SubCalls|Test::SubCalls>

Track the number of times subs are called

=cut

use Test::SubCalls;

=item L<Test::Tester|Test::Tester>

Ease testing test modules built with Test::Builder

=cut

use Test::Tester;

=item L<Test::Unit|Test::Unit>

the PerlUnit testing framework

=cut

use Test::Unit;

=item L<Test::Warn|Test::Warn>

Perl extension to test methods for warnings

=cut

use Test::Warn;

=item L<Test::YAML::Meta|Test::YAML::Meta>

Validation of the META.yml file in a distribution.

=cut

use Test::YAML::Meta;

=item L<Test::YAML::Valid|Test::YAML::Valid>

Test for valid YAML

=cut

use Test::YAML::Valid;

=item L<Text::Extract::MaketextCallPhrases|Text::Extract::MaketextCallPhrases>

Extract phrases from maketext--call--looking text

=cut

use Text::Extract::MaketextCallPhrases;

=item L<Text::Fold|Text::Fold>

Turn "unicode" and "byte" string text into lines of a given width, soft-hyphenating broken words 

=cut

use Text::Fold;

=item L<Text::Iconv|Text::Iconv>

Perl interface to iconv() codeset conversion function

=cut

use Text::Iconv;

=item L<Text::Trim|Text::Trim>

remove leading and/or trailing whitespace from strings

=cut

use Text::Trim;

=item L<Time::HiRes|Time::HiRes>

High resolution alarm, sleep, gettimeofday, interval timers

=cut

use Time::HiRes;

=item L<Variable::Magic|Variable::Magic>

Associate user-defined magic to variables from Perl.

=cut

use Variable::Magic;

=item L<WWW::Mechanize|WWW::Mechanize>

Handy web browsing in a Perl object

=cut

use WWW::Mechanize;

=item L<XML::DOM|XML::DOM>

A perl module for building DOM Level 1 compliant document structures

=cut

use XML::DOM;

=item L<XML::SAX|XML::SAX>

Simple API for XML

=cut

use XML::SAX;

=item L<YAML|YAML>

YAML Ain't Markup Language (tm)

=cut

use YAML;

=item L<cPanel::SyncUtil|cPanel::SyncUtil>

Perl extension for creating utilities that work with cpanelsync aware directories

=cut

use cPanel::SyncUtil;

=back

=head1 AUTHOR

cPanel, C<< <cpanel at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-task-cpanel-internal at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Task-Cpanel-Internal>.  We will be notified, and then you'll
automatically be notified of progress on your bug as we make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Task::Cpanel::Internal


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Task-Cpanel-Internal>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Task-Cpanel-Internal>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Task-Cpanel-Internal>

=item * Meta CPAN

L<http://metacpan.org/module/Task-Cpanel-Internal/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2012 cPanel.

All rights reserved.

http://cpanel.net

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. See L<perlartistic>.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Task::Cpanel::Internal
