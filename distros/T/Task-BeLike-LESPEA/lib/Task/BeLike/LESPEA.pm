use warnings;
use strict;
use utf8;

package Task::BeLike::LESPEA;
$Task::BeLike::LESPEA::VERSION = '2.005000';
BEGIN {
  $Task::BeLike::LESPEA::AUTHORITY = 'cpan:LESPEA';
}

# ABSTRACT: Modules that LESPEA uses on a daily basis


1;

__END__

=pod

=head1 NAME

Task::BeLike::LESPEA - Modules that LESPEA uses on a daily basis

=head1 VERSION

version 2.005000

=encoding utf8

=head1 Modules

=head2 Data Parsing

=over 4

=item L<Excel::Writer::XLSX|Excel::Writer::XLSX>

Modern XLSX writer

=item L<Spreadsheet::ParseExcel|Spreadsheet::ParseExcel>

Read Microsoft xls files

=item L<Spreadsheet::WriteExcel|Spreadsheet::WriteExcel>

Write Microsoft xls files

=item L<Spreadsheet::XLSX|Spreadsheet::XLSX>

Legacy XLSX writer

=item L<Text::CSV_XS|Text::CSV_XS>

Parse CSV files, no matter how borked up they are

=back

=head2 Database

=over 4

=item L<DBD::CSV|DBD::CSV>

Treat a CSV like a database

=item L<DBI|DBI>

Base database handler

=back

=head2 Dates

=over 4

=item L<Date::Calc|Date::Calc>

Perform date calculations

=item L<Date::Manip|Date::Manip>

Work with dates

=item L<DateTime|DateTime>

Base date object

=item L<DateTime::Format::DB2|DateTime::Format::DB2>

Convert various strings to datetime objects

=item L<DateTime::Format::DBI|DateTime::Format::DBI>

Convert various strings to datetime objects

=item L<DateTime::Format::DateManip|DateTime::Format::DateManip>

Convert various strings to datetime objects

=item L<DateTime::Format::DateParse|DateTime::Format::DateParse>

Convert various strings to datetime objects

=item L<DateTime::Format::Duration|DateTime::Format::Duration>

Convert various strings to datetime objects

=item L<DateTime::Format::Duration::DurationString|DateTime::Format::Duration::DurationString>

Convert various strings to datetime objects

=item L<DateTime::Format::Duration::XSD|DateTime::Format::Duration::XSD>

Convert various strings to datetime objects

=item L<DateTime::Format::Epoch|DateTime::Format::Epoch>

Convert various strings to datetime objects

=item L<DateTime::Format::Epoch::ActiveDirectory|DateTime::Format::Epoch::ActiveDirectory>

Convert various strings to datetime objects

=item L<DateTime::Format::Epoch::MacOS|DateTime::Format::Epoch::MacOS>

Convert various strings to datetime objects

=item L<DateTime::Format::Epoch::Unix|DateTime::Format::Epoch::Unix>

Convert various strings to datetime objects

=item L<DateTime::Format::Excel|DateTime::Format::Excel>

Convert various strings to datetime objects

=item L<DateTime::Format::Flexible|DateTime::Format::Flexible>

Convert various strings to datetime objects

=item L<DateTime::Format::HTTP|DateTime::Format::HTTP>

Convert various strings to datetime objects

=item L<DateTime::Format::Human|DateTime::Format::Human>

Convert various strings to datetime objects

=item L<DateTime::Format::Human::Duration|DateTime::Format::Human::Duration>

Convert various strings to datetime objects

=item L<DateTime::Format::ISO8601|DateTime::Format::ISO8601>

Convert various strings to datetime objects

=item L<DateTime::Format::MSSQL|DateTime::Format::MSSQL>

Convert various strings to datetime objects

=item L<DateTime::Format::MySQL|DateTime::Format::MySQL>

Convert various strings to datetime objects

=item L<DateTime::Format::Natural|DateTime::Format::Natural>

Convert various strings to datetime objects

=item L<DateTime::Format::Natural::Calc|DateTime::Format::Natural::Calc>

Convert various strings to datetime objects

=item L<DateTime::Format::Natural::Compat|DateTime::Format::Natural::Compat>

Convert various strings to datetime objects

=item L<DateTime::Format::Natural::Duration|DateTime::Format::Natural::Duration>

Convert various strings to datetime objects

=item L<DateTime::Format::Natural::Duration::Checks|DateTime::Format::Natural::Duration::Checks>

Convert various strings to datetime objects

=item L<DateTime::Format::Natural::Expand|DateTime::Format::Natural::Expand>

Convert various strings to datetime objects

=item L<DateTime::Format::Natural::Extract|DateTime::Format::Natural::Extract>

Convert various strings to datetime objects

=item L<DateTime::Format::Natural::Formatted|DateTime::Format::Natural::Formatted>

Convert various strings to datetime objects

=item L<DateTime::Format::Natural::Helpers|DateTime::Format::Natural::Helpers>

Convert various strings to datetime objects

=item L<DateTime::Format::Natural::Lang::Base|DateTime::Format::Natural::Lang::Base>

Convert various strings to datetime objects

=item L<DateTime::Format::Natural::Lang::EN|DateTime::Format::Natural::Lang::EN>

Convert various strings to datetime objects

=item L<DateTime::Format::Natural::Rewrite|DateTime::Format::Natural::Rewrite>

Convert various strings to datetime objects

=item L<DateTime::Format::Natural::Test|DateTime::Format::Natural::Test>

Convert various strings to datetime objects

=item L<DateTime::Format::Natural::Utils|DateTime::Format::Natural::Utils>

Convert various strings to datetime objects

=item L<DateTime::Format::Natural::Wrappers|DateTime::Format::Natural::Wrappers>

Convert various strings to datetime objects

=item L<DateTime::Format::Oracle|DateTime::Format::Oracle>

Convert various strings to datetime objects

=item L<DateTime::Format::Pg|DateTime::Format::Pg>

Convert various strings to datetime objects

=item L<DateTime::Format::RFC3339|DateTime::Format::RFC3339>

Convert various strings to datetime objects

=item L<DateTime::Format::RFC3501|DateTime::Format::RFC3501>

Convert various strings to datetime objects

=item L<DateTime::Format::RSS|DateTime::Format::RSS>

Convert various strings to datetime objects

=item L<DateTime::Format::Roman|DateTime::Format::Roman>

Convert various strings to datetime objects

=item L<DateTime::Format::SQLite|DateTime::Format::SQLite>

Convert various strings to datetime objects

=item L<DateTime::Format::Strptime|DateTime::Format::Strptime>

Convert various strings to datetime objects

=item L<DateTime::Format::Sybase|DateTime::Format::Sybase>

Convert various strings to datetime objects

=item L<DateTime::Format::WindowsFileTime|DateTime::Format::WindowsFileTime>

Convert various strings to datetime objects

=item L<DateTime::Format::XSD|DateTime::Format::XSD>

Convert various strings to datetime objects

=back

=head2 Development

=over 4

=item L<Data::Dumper::Perltidy|Data::Dumper::Perltidy>

Some nice formatting for Data::Dumper

=item L<Data::Printer|Data::Printer>

Very nice object printer

=item L<Devel::Cover|Devel::Cover>

Make sure we test all our functions

=item L<Devel::NYTProf|Devel::NYTProf>

Best profiler available! (by far)

=item L<Devel::REPL|Devel::REPL>

Nicely interact with perl

=item L<Devel::REPL::Plugin::DataPrinter|Devel::REPL::Plugin::DataPrinter>

Let us use a nice object printer

=item L<Module::Refresh|Module::Refresh>

Reload a module from disk

=item L<Module::Reload|Module::Reload>

Reload a module from disk

=item L<Perl::Critic|Perl::Critic>

Check our files for best practices

=item L<Perl::Tidy|Perl::Tidy>

Generate nice looking perl

=back

=head2 Dist::Zilla

=over 4

=item L<Dist::Zilla|Dist::Zilla>

Base dist module

=item L<Dist::Zilla::App::Command::cover|Dist::Zilla::App::Command::cover>

Lets us easily check the test coverage

=item L<Dist::Zilla::App::Command::perltidy|Dist::Zilla::App::Command::perltidy>

Lets us pretty up our code

=item L<Dist::Zilla::App::Command::shell|Dist::Zilla::App::Command::shell>

Provides an interactive dzil shell

=item L<Dist::Zilla::PluginBundle::Author::LESPEA|Dist::Zilla::PluginBundle::Author::LESPEA>

My dzil config

=item L<Dist::Zilla::Shell|Dist::Zilla::Shell>

Provides an interactive dzil shell

=back

=head2 Error Checking

=over 4

=item L<Try::Tiny|Try::Tiny>

At least some basic error checking

=item L<autodie|autodie>

Smart failures in the event a file/dir read/write fails  -  automagic!

=back

=head2 File handling

=over 4

=item L<File::HomeDir|File::HomeDir>

Makes getting files out of the users' home directory super easy

=item L<File::Next|File::Next>

Iterate over files

=item L<File::ShareDir|File::ShareDir>

Auto store/fetch files in the current modules' "private" folder structure once it's installed

=back

=head2 HTML stuff

=over 4

=item L<Encode|Encode>

Encoding helper

=item L<HTML::Entities|HTML::Entities>

Help us with html entities

=item L<HTML::Tree|HTML::Tree>

Build a huge tree out of the HTML Dom

=item L<HTML::TreeBuilder::XPath|HTML::TreeBuilder::XPath>

Do some xpath lookups for an HTML tree

=item L<LWP|LWP>

Get stuff from the internet

=item L<LWP::Protocol::https|LWP::Protocol::https>

Connecto to https sites

=item L<PPI::HTML|PPI::HTML>

Turn perl into a nice html page

=item L<Template|Template>

Template module for generating files safely

=item L<WWW::Mechanize|WWW::Mechanize>

Automate website crawling

=back

=head2 Installers

=over 4

=item L<Exporter::Easy|Exporter::Easy>

Makes exporting functions a snap

=item L<Module::Build|Module::Build>

Pure perl installer

=item L<Module::Install|Module::Install>

Extension of MakeMaker

=item L<Module::Install::AuthorTests|Module::Install::AuthorTests>

Run author tests

=item L<Module::Install::ExtraTests|Module::Install::ExtraTests>

Run extra tests

=back

=head2 JSON

=over 4

=item L<JSON|JSON>

Basic perl module to parse JSON

=item L<JSON::Any|JSON::Any>

Auto use the best available JSON module

=item L<JSON::XS|JSON::XS>

Fast C module to parse JSON

=back

=head2 Math

=over 4

=item L<Math::Big|Math::Big>

Easily compute math with big ints

=item L<Math::Big::Factors|Math::Big::Factors>

Compute factors of a number

=back

=head2 Moose

=over 4

=item L<Any::Moose|Any::Moose>

Use either moose or mouse

=item L<Getopt::Long::Descriptive|Getopt::Long::Descriptive>

Required for MooseX::App::Cmd

=item L<Moose|Moose>

Base moose module

=item L<Moose::Meta::Attribute::Native|Moose::Meta::Attribute::Native>

Treat attributes like they were native objects

=item L<MooseX::Aliases|MooseX::Aliases>

Make it easier to create objects

=item L<MooseX::App|MooseX::App>

Turn your object(s) into an app

=item L<MooseX::App::Cmd|MooseX::App::Cmd>

Extend your moose object as a script

=item L<MooseX::Log::Log4perl|MooseX::Log::Log4perl>

Easy logging injector

=item L<MooseX::Method::Signatures|MooseX::Method::Signatures>

Adds greate parameter varification to methods (with a performance price)

=item L<MooseX::Singleton|MooseX::Singleton>

Easily create a singleton object (good for caches)

=item L<MooseX::StrictConstructor|MooseX::StrictConstructor>

Ensure passed hash items are valid attributes

=item L<MooseX::Types|MooseX::Types>

Basic moose types

=item L<MooseX::Types::Common|MooseX::Types::Common>

As it sounds, common types for Moose

=item L<MooseX::Types::Common::Numeric|MooseX::Types::Common::Numeric>

As it sounds, common numeric types for Moose

=item L<MooseX::Types::Common::String|MooseX::Types::Common::String>

As it sounds, common string types for Moose

=item L<MooseX::Types::DateTime::ButMaintained|MooseX::Types::DateTime::ButMaintained>

Datetime type

=item L<MooseX::Types::Email|MooseX::Types::Email>

Contains an email address

=item L<MooseX::Types::IPv4|MooseX::Types::IPv4>

IP Address

=item L<MooseX::Types::JSON|MooseX::Types::JSON>

A JSON string

=item L<MooseX::Types::NetAddr::IP|MooseX::Types::NetAddr::IP>

Alternative to IPv4

=item L<MooseX::Types::PortNumber|MooseX::Types::PortNumber>

A valid port number

=item L<MooseX::Types::Structured|MooseX::Types::Structured>

Lets you write enforce structured attributes better than base Moose

=item L<MooseX::Types::URI|MooseX::Types::URI>

A valid URI address string

=item L<MooseX::Types::UUID|MooseX::Types::UUID>

A valid UUID string

=item L<MouseX::Types|MouseX::Types>

Basic mouse types

=back

=head2 Networking

=over 4

=item L<Net::CIDR::Lite|Net::CIDR::Lite>

Great CIDR calculation tool

=item L<Net::DNS|Net::DNS>

Do some DNS lookups

=item L<Net::IP|Net::IP>

Manip IP address

=item L<Net::Netmask|Net::Netmask>

Yet another IP manip tool

=item L<Net::Ping|Net::Ping>

Simple pinger

=item L<NetAddr::MAC|NetAddr::MAC>

Process MAC addresses

=back

=head2 Testing

=over 4

=item L<Test::Fatal|Test::Fatal>

Make sure something dies okay

=item L<Test::File|Test::File>

Test a file for wanted attributes

=item L<Test::LeakTrace|Test::LeakTrace>

Don't leak memory

=item L<Test::Memory::Cycle|Test::Memory::Cycle>

Make sure you don't have any cyclical data structures

=item L<Test::Most|Test::Most>

A whole bunch of tests modules

=item L<Test::Output|Test::Output>

Make sure a script outputs the correct values

=item L<Test::Perl::Critic|Test::Perl::Critic>

Follow best practices

=item L<Test::Pod|Test::Pod>

Ensures your POD compiles ok

=item L<Test::Pod::Coverage|Test::Pod::Coverage>

Make sure you document all of your functions

=item L<Test::Taint|Test::Taint>

Ensure taint handling is done correctly

=back

=head2 Threading

=over 4

=item L<AnyEvent|AnyEvent>

Use whatever event module is best

=item L<Async::Interrupt|Async::Interrupt>

Thread helper

=item L<Coro|Coro>

The best threading module out there

=item L<EV|EV>

Enhanced event handling module

=item L<Event|Event>

Basic event handling module

=item L<Guard|Guard>

Thread helper

=back

=head2 Utils

=over 4

=item L<File::Slurp|File::Slurp>

Read in an entire file all at once

=item L<IO::Scalar|IO::Scalar>

Turn scalars into io objects

=item L<List::AllUtils|List::AllUtils>

For those of us that can't remember which one to use

=item L<List::Gen|List::Gen>

Very good list processing helper

=item L<List::MoreUtils|List::MoreUtils>

Provides some advanced-ish list utilities

=item L<Locale::US|Locale::US>

Some handy locales for America

=item L<Modern::Perl|Modern::Perl>

Turn on new features

=item L<Readonly::XS|Readonly::XS>

Marks variables readonly... better than constant for some things

=item L<Regexp::Common|Regexp::Common>

A ton of precompiled regular expressions

=item L<Scalar::Util|Scalar::Util>

Additional scalar helpers

=item L<Task::Weaken|Task::Weaken>

Let us create weak objects

=item L<Text::Trim|Text::Trim>

Enhanced trimming capabilities

=item L<autovivification|autovivification>

Makes working with hashes easier

=item L<namespace::autoclean|namespace::autoclean>

Cleans up the namespace of your modules

=back

=head2 XML

=over 4

=item L<XML::LibXML|XML::LibXML>

Base XML module

=item L<XML::SAX|XML::SAX>

Stream handling

=item L<XML::Simple|XML::Simple>

Even more simple than twig

=item L<XML::Twig|XML::Twig>

Make XML easy

=back

=head2 YAML

=over 4

=item L<YAML|YAML>

Basic perl module to parse YAML

=item L<YAML::Any|YAML::Any>

Auto use the best available YAML module

=item L<YAML::Syck|YAML::Syck>

Another fast module to parse YAML

=item L<YAML::XS|YAML::XS>

Fast C module to parse JSON

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHOR

Adam Lesperance <lespea@gmail.com>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Task::BeLike::LESPEA

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Task-BeLike-LESPEA>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Task-BeLike-LESPEA>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Task-BeLike-LESPEA>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Task-BeLike-LESPEA>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Task-BeLike-LESPEA>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Task-BeLike-LESPEA>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/Task-BeLike-LESPEA>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Task-BeLike-LESPEA>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Task-BeLike-LESPEA>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Task::BeLike::LESPEA>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-task-belike-lespea at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Task-BeLike-LESPEA>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/lespea/task-belike-lespea>

  git clone git://github.com/lespea/task-belike-lespea.git

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Lesperance.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut
