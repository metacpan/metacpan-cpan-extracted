package TableDataRole::Source::CSVInDATA;

use 5.010001;
use strict;
use warnings;

use Role::Tiny;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-29'; # DATE
our $DIST = 'TableDataRoles-Standard'; # DIST
our $VERSION = '0.013'; # VERSION

with 'TableDataRole::Spec::Basic';
with 'TableDataRole::Source::CSVInFile';

around new => sub {
    my $orig = shift;
    my ($class, %args) = @_;
    die "Unknown argument(s): ". join(", ", sort keys %args)
        if keys %args;

    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
    my $fh = \*{"$class\::DATA"};

    my $obj = $orig->(@_, filehandle => $fh);
};

1;
# ABSTRACT: Role to access table data from CSV in DATA section

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Source::CSVInDATA - Role to access table data from CSV in DATA section

=head1 VERSION

This document describes version 0.013 of TableDataRole::Source::CSVInDATA (from Perl distribution TableDataRoles-Standard), released on 2021-09-29.

=head1 DESCRIPTION

This role expects table data in CSV format in the DATA section. First row MUST
contain the column names.

=for Pod::Coverage ^(.+)$

=head1 ROLES MIXED IN

L<TableDataRole::Spec::Basic>

=head1 PROVIDED METHODS

=head2 as_csv

A more efficient version than one provided by L<TableDataRole::Util::CSV>, since
the data is already in CSV form.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataRoles-Standard>.

=head1 SEE ALSO

L<TableDataRole::Source::CSVInFile>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
