package TableData::SQLite;

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-14'; # DATE
our $DIST = 'TableDataRole-Source-SQLite'; # DIST
our $VERSION = '0.001'; # VERSION

with 'TableDataRole::Source::SQLite';

our %SPEC;

$SPEC{new} = {
    v => 1.1,
    is_meth => 1,
    is_func => 0,
    args => {
        # either supply filename, dbh, or sth
        filename => {
            schema => 'filename*',
        },
        dbh => {
            schema => 'obj*',
        },
        sth => {
            schema => 'obj*',
        },

        # only when using filename or dbh
        query => {
            schema => 'str*',
        },
        table => {
            schema => 'str*',
        },

        # only when using sth
        sth_bind_params => {
            schema => 'array*',
        },

        row_count_sth => {
            schema => 'obj*',
        },
        row_count_query => {
            schema => 'obj*',
        },

        # only when using row_count_sth
        row_count_sth_bind_params => {
            schema => 'array*',
        },
    },
    args_rels => {
        req_one => [qw/filename dbh sth/],
        choose_one => [qw/query table/],
        'dep_any&' => [
            [query => [qw/dsn dbh/]],
            [row_count_query => [qw/dsn dbh/]],
            [table => [qw/dsn dbh/]],
            [sth_bind_params => [qw/sth/]],
            [row_count_sth_bind_params => [qw/row_count_sth/]],
        ],
    },
};

1;
# ABSTRACT: Get table data from SQLite database

__END__

=pod

=encoding UTF-8

=head1 NAME

TableData::SQLite - Get table data from SQLite database

=head1 VERSION

This document describes version 0.001 of TableData::SQLite (from Perl distribution TableDataRole-Source-SQLite), released on 2024-05-14.

=head1 SYNOPSIS

 use TableData::SQLite;

 my $table = TableData::SQLite->new(
     sth           => $dbh->prepare("SELECT * FROM mytable"),
     row_count_sth => $dbh->prepare("SELECT COUNT(*) FROM table"),
 );

 # or
 my $table = TableData::DBI->new(
     filename      => "/home/ujang/albums.db",
     table         => "mytable",
 );

=head1 DESCRIPTION

This is a TableData:: module to table data from a SQLite query/table.

=head1 METHODS


=head2 new

Usage:

 new(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dbh> => I<obj>

(No description)

=item * B<filename> => I<filename>

(No description)

=item * B<query> => I<str>

(No description)

=item * B<row_count_query> => I<obj>

(No description)

=item * B<row_count_sth> => I<obj>

(No description)

=item * B<row_count_sth_bind_params> => I<array>

(No description)

=item * B<sth> => I<obj>

(No description)

=item * B<sth_bind_params> => I<array>

(No description)

=item * B<table> => I<str>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataRole-Source-SQLite>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataRole-Source-SQLite>.

=head1 SEE ALSO

More general module: L<TableData::DBI>

L<DBD::SQLite>

L<TableData>

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataRole-Source-SQLite>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
