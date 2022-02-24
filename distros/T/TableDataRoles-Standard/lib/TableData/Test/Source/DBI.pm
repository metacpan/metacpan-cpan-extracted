# no code
## no critic: TestingAndDebugging::RequireUseStrict
package TableData::Test::Source::DBI;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-20'; # DATE
our $DIST = 'TableDataRoles-Standard'; # DIST
our $VERSION = '0.014'; # VERSION

use alias::module 'TableData::DBI';

1;
# ABSTRACT: Alias package for TableData::DBI

__END__

=pod

=encoding UTF-8

=head1 NAME

TableData::Test::Source::DBI - Alias package for TableData::DBI

=head1 VERSION

This document describes version 0.014 of TableData::Test::Source::DBI (from Perl distribution TableDataRoles-Standard), released on 2022-02-20.

=head1 METHODS


=head2 new

Usage:

 new(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dbh> => I<obj>

=item * B<dsn> => I<str>

=item * B<password> => I<str|code>

=item * B<query> => I<str>

=item * B<row_count_query> => I<obj>

=item * B<row_count_sth> => I<obj>

=item * B<row_count_sth_bind_params> => I<array>

=item * B<sth> => I<obj>

=item * B<sth_bind_params> => I<array>

=item * B<table> => I<str>

=item * B<user> => I<str|code>


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

Please visit the project's homepage at L<https://metacpan.org/release/TableDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataRoles-Standard>.

=head1 SEE ALSO

L<TableData::DBI>

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

This software is copyright (c) 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
