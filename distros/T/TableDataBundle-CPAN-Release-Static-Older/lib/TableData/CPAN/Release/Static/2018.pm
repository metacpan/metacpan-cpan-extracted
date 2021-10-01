package ## no critic: Modules::RequireFilenameMatchesPackage
    # hide from PAUSE
    TableDataRole::CPAN::Release::Static::2018;

use 5.010001;
use strict;
use warnings;

use Role::Tiny;
with 'TableDataRole::Source::CSVInFile';

around new => sub {
    my $orig = shift;

    require File::Basename;
    my $filename = File::Basename::dirname(__FILE__) . '/../../../../../share/2018.csv';
    unless (-f $filename) {
        require File::ShareDir;
        $filename = File::ShareDir::dist_file('TableDataBundle-CPAN-Release-Static-Older', '2018.csv');
    }
    $orig->(@_, filename=>$filename);
};

package TableData::CPAN::Release::Static::2018;

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-27'; # DATE
our $DIST = 'TableDataBundle-CPAN-Release-Static-Older'; # DIST
our $VERSION = '20210927.0'; # VERSION

with 'TableDataRole::CPAN::Release::Static::2018';

our %STATS = ("num_rows",15484,"num_columns",9); # STATS

1;
# ABSTRACT: CPAN releases for the year 2018

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::CPAN::Release::Static::2018 - CPAN releases for the year 2018

=head1 VERSION

This document describes version 20210927.0 of TableDataRole::CPAN::Release::Static::2018 (from Perl distribution TableDataBundle-CPAN-Release-Static-Older), released on 2021-09-27.

=head1 SYNOPSIS

 use TableData::CPAN::Release::Static::2018;

 my $td = TableData::CPAN::Release::Static::2018->new;

 # Iterate rows of the table
 $td->each_row_arrayref(sub { my $row = shift; ... });
 $td->each_row_hashref (sub { my $row = shift; ... });

 # Get the list of column names
 my @columns = $td->get_column_names;

 # Get the number of rows
 my $row_count = $td->get_row_count;

See also L<TableDataRole::Spec::Basic> for other methods.

=head1 TABLEDATA NOTES

The data is retrieved from MetaCPAN.

The C<status> column is the status of the release when the row is retrieved from
MetaCPAN. It is probably not current, so do not use it.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataBundle-CPAN-Release-Static-Older>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataBundle-CPAN-Release-Static-Older>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataBundle-CPAN-Release-Static-Older>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
