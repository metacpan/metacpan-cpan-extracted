## no critic: TestingAndDebugging::RequireUseStrict
package TableData;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-04-19'; # DATE
our $DIST = 'TableData'; # DIST
our $VERSION = '0.2.3'; # VERSION

1;
# ABSTRACT: Specification for TableData::*, modules that contains table data

__END__

=pod

=encoding UTF-8

=head1 NAME

TableData - Specification for TableData::*, modules that contains table data

=head1 SPECIFICATION VERSION

0.2

=head1 VERSION

This document describes version 0.2.3 of TableData (from Perl distribution TableData), released on 2023-04-19.

=head1 SYNOPSIS

Use one of the C<TableData::*> modules.

=head1 DESCRIPTION

B<NOTE: EARLY SPECIFICATION; THINGS WILL STILL CHANGE A LOT>.

C<TableData::*> modules are modules that contain two-dimensional table data. The
table can be accessed via a standard interface (see
L<TableDataRole::Spec::Basic>). An example of table data would be list of
countries along with their names and country code, or a list of CPAN authors
along with their published email addresses.

Why put data in a Perl module, as a Perl distribution? To leverage the Perl/CPAN
toolchain and infrastructure: 1) ease of installation, update, and
uninstallation; 2) allowing dependency expression and version comparison; 3)
ease of packaging further as OS packages, e.g. Debian packages (converted from
Perl distribution); 4) testing by CPAN Testers.

The table data can actually be stored as CSV in the DATA section of a Perl
module, or as a CSV file in a shared directory of a Perl distribution, or a Perl
structure in the module source code, or from other sources.

The standard interface provides a convenient and consistent way to access the
data, from accessing the rows, getting the column names, and dumping to CSV or
Perl structure for other tools to operate on.

To get started, see L<TableDataRole::Spec::Basic> and one of existing
C<TableData::*> module.

=head1 NAMESPACE ORGANIZATION

=head2 TableData

C<TableData> (this module) is the specification.

All the modules under C<TableData::*> are modules with actual table data. The
entity mentioned in the module name should be singular, not plural (e.g.
C<TableData::Person::AcmeInc> instead of C<TableData::Persons::AcmeInc> or
C<TableData::People::AcmeInc>.

More specific subnamespaces for more specific types of table data are described
in entries below.

=head2 TableData::Calendar::*

For calendar-related data.

=head2 TableData::Calendar::Date::*

For table containing calendar dates.

Examples:

C<TableData::Calendar::Date::Holiday::ID> contains holiday dates for Indonesia.

C<TableData::Calendar::Date::Holiday::AU::TAS> contains holiday dates for
Tasmania, Australia.

=head2 TableData::Lingua::*

For human-language-related data.

=head2 TableData::Lingua::Dict::*

For dictionaries.

For monolingual language dictionaries, a 2-letter ISO language code should be
added as subnamespace prefix. For bilingual dictionaries, a
C<LANGCODE1_LANGCODE2> should be added as subnamespace prefix.

All C<TableData::Lingua::Dict::*> modules should contain the columns C<entry>
and C<description>.

Examples: L<TableData::Lingua::Dict::Foldoc>,
L<TableData::Lingua::Dict::ID::KBBI>,
L<TableData::Lingua::Dict::ZH::Proverb::StarDict>,
L<TableData::Lingua::Dict::FR_EN::FreeDict>.

=head2 TableData::Lingua::Word::*

For tables that contain word list. This is now preferred namespace to
L<WordList>, and an alternative for C<ArrayData::Lingua::Word::> namespace.

All C<TableData::Lingua::Word::*> modules should contain the column C<word> so
they are usable from applications like word games.

A 2-letter ISO language code should be added as subnamespace prefix whenever
applicable.

Example: L<TableData::Lingua::Word::EN::Adjective::TalkEnglish> (list of top
adjectives from talkenglish.com website, along with some other data like
frequency).

=head2 TableData::Locale::*

For locale-related data.

Examples: C<TableData::Locale::Country> (list of countries in the world),
L<TableData::Locale::US::State> (list of US states),
C<TableData::Locale::ID::Province> (list of Indonesian provinces).

=head2 TableDataRole::*

The roles.

=head2 TableDataRoles::*

C<TableDataRoles::*> are names for distributions that contains several role
modules.

=head2 TableDataBase::*

For base classes.

=head2 TableDataBases::*

C<TableDataBases::*> are names for distributions that contain several
C<TableDataBase> modules.

=head2 TableDataBundle::*

C<TableDataBundle::*> are names for distributions that contain several
C<TableData> modules. The subnamespaces can follow that of C<TableData>.

Examples: L<TableDataBundle::Perl::CPAN::Release> which contains
L<TableData::Perl::CPAN::Release::Static> and
L<TableData::Perl::CPAN::Release::Static::FromNewest>.
L<TableDataBundle::Software::License> which contains
L<TableData::Software::License::FromRPL> and
L<TableData::Software::License::FromSL>.

=head1 RELATED NAMESPACES

=head2 Data::TableData::*

Modules that contain code to work with table data (not necessarily table data in
C<TableData::> modules).

=head1 FAQ

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData>.

=head1 SEE ALSO

L<ArrayData>, L<HashData> are related projects.

L<WordList> is an older, related project.

Modules and CLIs that manipulate table data: L<Data::TableData::Object>, L<td>
(from L<App::td>).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2021, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
