use strict;
use warnings;
package Task::Kensho; # git description: v0.40-29-gb2d78f6
# ABSTRACT: A Glimpse at an Enlightened Perl
# KEYWORDS: EPO enlightened recommendations curated

our $VERSION = '0.41';

__END__

=pod

=encoding UTF-8

=head1 NAME

Task::Kensho - A Glimpse at an Enlightened Perl

=head1 VERSION

version 0.41

=head1 SYNOPSIS

    > cpanm --interactive Task::Kensho

=head1 DESCRIPTION

=for stopwords Buddhism EPO Kenshō nonduality amongst Organisation installable WebSocket

L<Task::Kensho> is a list of recommended, widely used and best-in-class modules
for Enlightened Perl development. CPAN is wonderful, but there are too
many wheels and you have to pick and choose amongst the various
competing technologies.

From L<http://en.wikipedia.org/wiki/Kensho>:

=over 4

Kenshō (見性) (C. Wu) is a Japanese term for enlightenment
experiences - most commonly used within the confines of Zen
Buddhism - literally meaning "seeing one's nature"[1] or "true
self."[2] It generally "refers to the realization of nonduality of
subject and object."[3]

=back

The plan is for L<Task::Kensho> to be a rough testing ground for ideas that
go into among other things the Enlightened Perl Organisation Extended
Core (EPO-EC).

The modules that are bundled by L<Task::Kensho> are broken down into
several categories and are still being considered. They are all taken
from various top 100 most used perl modules lists and from discussions
with various subject matter experts in the Perl Community. That said,
this bundle does I<not> follow the guidelines established for the EPO-EC
for peer review via industry advisers.

Starting in 2011, L<Task::Kensho> split its sub-groups of modules into
individually-installable tasks.  Each L<Task::Kensho> sub-task is listed at the
beginning of its section in this documentation.

When installing L<Task::Kensho> itself, you will be asked to install each
sub-task in turn, or you can install individual tasks separately. These
individual tasks will always install all their modules by default. This
facilitates the ease and simplicity the distribution aims to achieve.

=head1 RECOMMENDED MODULES

=for stopwords Async Minimalistic

=head2 L<Task::Kensho::Async>: Async Programming

=over 4

=item L<Future>

represent an operation awaiting completion

=item L<IO::Async>

Asynchronous event-driven programming

=item L<MCE>

Many-Core Engine for Perl providing parallel processing capabilities

=item L<Mojo::IOLoop>

Minimalistic event loop

=item L<POE>

Multitasking and networking framework for Perl

=item L<Parallel::ForkManager>

A simple parallel processing fork manager

=back

=for stopwords pastebin yay

=head2 L<Task::Kensho::CLI>: Useful Command-line Tools

=over 4

=item L<App::Ack>

A grep-like text finder

=item L<App::Nopaste>

Easy access to any pastebin

=item L<Module::CoreList>

What modules shipped with versions of perl

=item L<Reply>

reply - read, eval, print, loop, yay!

=back

=head2 L<Task::Kensho::Config>: Config Modules

=over 4

=item L<Config::Any>

Load configuration from different file formats, transparently

=item L<Config::General>

Generic Config Module

=item L<JSON::MaybeXS>

wrapper around the most current and fast JSON backends

=back

=head2 L<Task::Kensho::DBDev>: Database Development

=over 4

=item L<DBD::SQLite>

Self Contained RDBMS in a DBI Driver

=item L<DBI>

Database independent interface for Perl

=item L<DBIx::Class>

Extensible and flexible object <-> relational mapper.

=item L<DBIx::Class::Schema::Loader>

Dynamic definition of a DBIx::Class::Schema

=item L<SQL::Translator>

Manipulate structured data definitions (SQL and more)

=back

=head2 L<Task::Kensho::Dates>: Date Modules

=over 4

=item L<DateTime>

A date and time object

=item L<Time::Moment>

A fast immutable object representing a date and time

=item L<Time::ParseDate>

Date parsing both relative and absolute

=item L<Time::Piece>

A date and time object based on localtime or gmtime

=back

=head2 L<Task::Kensho::Email>: Email

=over 4

=item L<Email::MIME::Kit>

The Swiss army chainsaw of assembling email messages

=item L<Email::Sender>

A library for sending email

=item L<Email::Simple>

A B<simple> email object. No, really!

=item L<Email::Stuffer>

A more casual approach to creating and sending Email:: emails

=item L<Email::Valid>

Check validity of Internet email addresses

=back

=for stopwords CSV XLS XLSX

=head2 L<Task::Kensho::ExcelCSV>: Excel/CSV

=over 4

=item L<Excel::Writer::XLSX>

Create spreadsheets in the XLSX format

=item L<Spreadsheet::Read>

Read the data from a spreadsheet

=item L<Spreadsheet::WriteExcel::Simple>

Create XLS documents easily

=item L<Text::CSV_XS>

Manipulate comma-separated values (CSV)

=back

=head2 L<Task::Kensho::Exceptions>: Exception Handling

=over 4

=item L<Syntax::Keyword::Try>

try/catch/finally with full syntax support for control statements

=item L<Try::Tiny>

Lightweight exception handling that handles the vagaries of $@.

=item L<autodie>

Make builtins and other functions die instead of returning undef on failure.

=back

=for stopwords whippitupitude Hackery Mojo

=head2 L<Task::Kensho::Hackery>: Script Hackery

These packages are included less for production work and more for whippitupitude. They reflect packages that people have found incredibly useful for prototyping and debugging before reducing down to a production script.

=over 4

=item L<IO::All>

IO::All combines all of the best Perl IO modules into a single nifty object oriented interface to greatly simplify your everyday Perl IO idioms.

=item L<Smart::Comments>

Comments that do more than just sit there

=item L<Term::ProgressBar::Simple>

Simple progress bars

=item L<ojo>

Fun one-liners with Mojo

=back

=head2 L<Task::Kensho::Logging>: Logging

=over 4

=item L<Log::Any>

Bringing loggers and listeners together.

=item L<Log::Contextual>

Log::Contextual is a simple interface to extensible logging.  It is bundled with a really basic logger, Log::Contextual::SimpleLogger.

=item L<Log::Dispatch>

This module manages a set of Log::Dispatch::* output objects that can be logged to via a unified interface.

=item L<Log::Log4perl>

Log::Log4perl lets you remote-control and fine-tune the logging behaviour of your system from the outside. It implements the widely popular (Java-based) Log4j logging package in pure Perl.

=back

=for stopwords profiler templated tidyall validator

=head2 L<Task::Kensho::ModuleDev>: Module Development

=over 4

=item L<CPAN::Uploader>

Upload things to the CPAN

=item L<Code::TidyAll>

Engine for tidyall, your all-in-one code tidier and validator

=item L<Data::Printer>

Colored pretty-print of Perl data structures and objects

=item L<Devel::Confess>

Include stack traces on all warnings and errors

=item L<Devel::Dwarn>

Combine warns and Data::Dumper::Concise

=item L<Devel::NYTProf>

Powerful feature-rich perl source code profiler

=item L<Dist::Zilla>

Builds distributions of code to be uploaded to the CPAN.

=item L<Modern::Perl>

enable all of the features of Modern Perl with one command

=item L<Module::Build::Tiny>

A simple, lightweight, drop-in replacement for ExtUtils::MakeMaker or Module::Build

=item L<Perl::Critic>

Critique Perl source code for best-practices.

=item L<Perl::Tidy>

Parses and beautifies perl source

=item L<Pod::Readme>

Convert POD to README file

=item L<Software::License>

Packages that provide templated software licenses

=back

=head2 L<Task::Kensho::OOP>: Object Oriented Programming

=over 4

=item L<Moo>

Minimalist Object Orientation (with Moose compatibility)

=item L<Moose>

a postmodern object system for Perl5 (see also Task::Moose for a larger list of Moose extensions)

=item L<MooseX::Aliases>

easy aliasing of methods and attributes in Moose

=item L<MooseX::Getopt>

a Moose role for processing command line options

=item L<MooseX::NonMoose>

easy subclassing of non-Moose classes

=item L<MooseX::Role::Parameterized>

Moose roles with composition parameters

=item L<MooseX::SimpleConfig>

a Moose role for setting attributes from a simple configuration file

=item L<MooseX::StrictConstructor>

a Moose extension that makes your object constructors blow up on unknown attributes

=item L<Package::Variant>

Parameterizable packages

=item L<Type::Tiny>

tiny, yet Moo(se)-compatible type constraints

=item L<namespace::autoclean>

keep imports out of your namespace (Moose-aware)

=back

=for stopwords Redis

=head2 L<Task::Kensho::Scalability>: Scalability

=over 4

=item L<CHI>

A unified cache interface, like DBI

=item L<Redis>

Perl binding for Redis database

=back

=head2 L<Task::Kensho::Testing>: Testing

=over 4

=item L<Devel::Cover>

Code coverage metrics for Perl

=item L<Test2::Suite>

Distribution with a rich set of tools built upon the Test2 framework.

=item L<Test::Deep>

Test deep data structures

=item L<Test::Fatal>

Test exception-based code

=item L<Test::Memory::Cycle>

Check for memory leaks and circular memory references

=item L<Test::Pod>

Check for POD errors in files

=item L<Test::Pod::Coverage>

Check for pod coverage in your distribution.

=item L<Test::Requires>

Make running a test conditional on a particular module being installed

=item L<Test::Simple>

Basic utilities for writing tests.

=item L<Test::Warnings>

Test for warnings and the lack of them

=back

=for stopwords Bundler

=head2 L<Task::Kensho::Toolchain>: Basic Toolchain

=over 4

=item L<App::FatPacker>

Pack your dependencies onto your script file

=item L<App::cpanminus>

Get, unpack, build and install modules from CPAN

=item L<App::cpm>

a fast CPAN module installer

=item L<App::perlbrew>

Manage perl installations in your $HOME

=item L<CPAN::Mini>

Create a minimal mirror of CPAN

=item L<Carton>

Perl module dependency manager (aka Bundler for Perl)

=item L<Pinto>

Curate a repository of Perl modules

=item L<local::lib>

Create and use a local lib/ for perl modules with PERL5LIB

=item L<version>

Perl extension for Version Objects

=back

=for stopwords WebSocket

=head2 L<Task::Kensho::WebCrawling>: Web Crawling

=over 4

=item L<HTTP::Thin>

A Thin Wrapper around HTTP::Tiny to play nice with HTTP::Message

=item L<HTTP::Tiny>

Lightweight HTTP client implementation

=item L<LWP::Simple>

Simple procedural interface to LWP

=item L<LWP::UserAgent>

Full-featured Web client library for Perl

=item L<Mojo::UserAgent>

Non-blocking I/O HTTP and WebSocket user agent

=item L<WWW::Mechanize>

Handy web browsing in a Perl object

=item L<WWW::Mechanize::TreeBuilder>

This module combines WWW::Mechanize and HTML::TreeBuilder.

=item L<WWW::Selenium>

Perl Client for the Selenium Remote Control test tool

=back

=for stopwords configs RSS

=head2 L<Task::Kensho::WebDev>: Web Development

=over 4

=item L<Attean>

A Semantic Web Framework

=item L<CGI::FormBuilder::Source::Perl>

Build CGI::FormBuilder configs from Perl syntax files.

=item L<Dancer2>

the new generation of Dancer, a lightweight yet powerful web application framework

=item L<HTML::FormHandler>

HTML forms using Moose

=item L<HTTP::BrowserDetect>

Determine Web browser, version, and platform from an HTTP user agent string

=item L<MIME::Types>

Definition of MIME types

=item L<Mojolicious>

Real-time web framework

=item L<Plack>

Flexible superglue between Web Servers and Perl Web Frameworks or code.

=item L<Task::Catalyst>

Catalyst is The Elegant MVC Web Application Framework. Task::Catalyst is all you need to start with Catalyst.

=item L<Template>

(Template::Toolkit) Template Processing System

=item L<Web::Simple>

A quick and easy way to build simple web applications

=item L<XML::Atom>

Atom feed and API implementation

=item L<XML::RSS>

Creates and updates RSS files

=back

=for stopwords libxml libxml2 libxslt RDF

=head2 L<Task::Kensho::XML>: XML Development

=over 4

=item L<XML::Generator::PerlData>

Perl extension for generating SAX2 events from nested Perl data structures.

=item L<XML::LibXML>

Perl Binding for libxml2

=item L<XML::LibXSLT>

Interface to the gnome libxslt library

=item L<XML::SAX>

Simple/Streaming API for XML

=item L<XML::SAX::Writer>

Output XML from SAX2 Events

=back

=head1 INSTALLING

Since version 0.34, L<Task::Kensho> has made use of the C<optional_features> field
in distribution metadata. This allows CPAN clients to interact with you
regarding which modules you wish to install.

The C<cpanm> client requires interactive mode to be enabled for this to work:

    cpanm --interactive Task::Kensho

=head1 LIMITATIONS

This list is by no means comprehensive of the "Good" Modules on CPAN.
Nor is this necessarily the correct path for all developers. Each of
these modules has a perfectly acceptable replacement that may work
better for you. This is however a path to good perl practice, and a
starting place on the road to Enlightened Perl programming.

=head1 SEE ALSO

L<http://www.enlightenedperl.org/>,
L<Perl::Dist::Strawberry|Perl::Dist::Strawberry>

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/EnlightenedPerlOrganisation/task-kensho/issues>.

There is also an irc channel available for users of this distribution, at
L<C<#epo> on C<irc.perl.org>|irc://irc.perl.org/#epo>.

=head1 AUTHOR

Chris Prather <chris@prather.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Chris Nehren Leo Lapworth Dan Book Mohammad S Anwar Olaf Alders Rachel Kelly Shawn Sorichetti Andrew Whatson Florian Ragwitz Rick Leir Tina Müller

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Chris Nehren <apeiron@cpan.org>

=item *

Leo Lapworth <leo@cuckoo.org>

=item *

Dan Book <grinnz@grinnz.com>

=item *

Dan Book <grinnz@gmail.com>

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=item *

Olaf Alders <olaf@wundersolutions.com>

=item *

Rachel Kelly <rkellyalso@gmail.com>

=item *

Shawn Sorichetti <shawn@coloredblocks.com>

=item *

Andrew Whatson <whatson@gmail.com>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Rick Leir <rleir@leirtech.com>

=item *

Tina Müller <cpan2@tinita.de>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2008 by Chris Prather.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
