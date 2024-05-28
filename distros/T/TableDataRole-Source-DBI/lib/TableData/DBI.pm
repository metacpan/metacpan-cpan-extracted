package TableData::DBI;

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-14'; # DATE
our $DIST = 'TableDataRole-Source-DBI'; # DIST
our $VERSION = '0.026'; # VERSION

with 'TableDataRole::Source::DBI';

our %SPEC;

$SPEC{new} = {
    v => 1.1,
    is_meth => 1,
    is_func => 0,
    args => {
        dsn => {
            schema => 'str*',
        },
        dbh => {
            schema => 'obj*',
        },
        sth => {
            schema => 'obj*',
        },

        # only when using dsn
        user => {
            schema => ['any*', of=>['str*', 'code*']],
        },
        password => {
            schema => ['any*', of=>['str*', 'code*']],
        },

        # only when using dsn or dbh
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
        req_one => [qw/dsn dbh sth/],
        choose_one => [qw/query table/],
        'dep_any&' => [
            [user     => [qw/dsn/]],
            [password => [qw/dsn/]],
            [query => [qw/dsn dbh/]],
            [row_count_query => [qw/dsn dbh/]],
            [table => [qw/dsn dbh/]],
            [sth_bind_params => [qw/sth/]],
            [row_count_sth_bind_params => [qw/row_count_sth/]],
        ],
    },
};

1;
# ABSTRACT: Get table data from DBI

__END__

=pod

=encoding UTF-8

=head1 NAME

TableData::DBI - Get table data from DBI

=head1 VERSION

This document describes version 0.026 of TableData::DBI (from Perl distribution TableDataRole-Source-DBI), released on 2024-05-14.

=head1 SYNOPSIS

 use TableData::DBI;

 my $table = TableData::DBI->new(
     sth           => $dbh->prepare("SELECT * FROM mytable"),
     row_count_sth => $dbh->prepare("SELECT COUNT(*) FROM table"),
 );

 # or
 my $table = TableData::DBI->new(
     dsn           => "DBI:mysql:database=mydb",
     user          => "...",
     password      => "...",
     table         => "mytable",
 );

=head1 DESCRIPTION

This is a TableData:: module to table data from a L<DBI> query/table.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataRole-Source-DBI>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataRole-Source-DBI>.

=head1 SEE ALSO

L<TableData::SQLite>

L<DBI>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataRole-Source-DBI>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
