package TableData;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-01'; # DATE
our $DIST = 'TableData'; # DIST
our $VERSION = '0.2.1'; # VERSION

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

This document describes version 0.2.1 of TableData (from Perl distribution TableData), released on 2021-06-01.

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

C<TableData> (this module) is the specification.

All the modules under C<TableData::*> are modules with actual table data. The
entity mentioned in the module name should be singular, not plural (e.g.
C<TableData::Person::AcmeInc> instead of C<TableData::Persons::AcmeInc> or
C<TableData::People::AcmeInc>.

More specific subnamespaces for more specific types of table data:

=over

=item * C<TableData::Locale::*> for locale-related data

Examples: C<TableData::Locale::Country> (list of countries in the world),
L<TableData::Locale::US::State> (list of US states),
C<TableData::Locale::ID::Province> (list of Indonesian provinces).

=item * C<TableData::Lingua::*> for human-language-related data

Examples: L<TableData::Lingua::Word::EN::Adjective::TalkEnglish> (list of top
adjectives from talkenglish.com website, along with some other data like
frequency). All C<TableData::Lingua::Word::*> modules should contain the column
C<word> so they are usable from applications like word games.

=back

C<TableDataRole::*> the roles.

C<TableDataRoles::*> is the name for distribution that contain several role
modules.

C<TableDataBase::*> for base classes.

C<TableDataBases::*> is the name for distribution that contain several
C<TableDataBase> modules.

C<TableDataBundle-*> name for distribution that contains several C<TableData>
modules.

=head1 FAQ

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<ArrayData>, L<HashData> are related projects.

L<WordList> is an older, related project.

Modules and CLIs that manipulate table data: L<Data::TableData::Object>, L<td>
(from L<App::td>).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
