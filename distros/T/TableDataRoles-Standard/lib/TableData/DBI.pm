package TableData::DBI;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-13'; # DATE
our $DIST = 'TableDataRoles-Standard'; # DIST
our $VERSION = '0.008'; # VERSION

use strict;
use warnings;

use Role::Tiny::With;
with 'TableDataRole::Source::DBI';

1;
# ABSTRACT: Get table data from DBI

__END__

=pod

=encoding UTF-8

=head1 NAME

TableData::DBI - Get table data from DBI

=head1 VERSION

This document describes version 0.008 of TableData::DBI (from Perl distribution TableDataRoles-Standard), released on 2021-04-13.

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

Please visit the project's homepage at L<https://metacpan.org/release/TableDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataRoles-Standard>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-TableDataRoles-Standard/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DBI>

L<TableData>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
