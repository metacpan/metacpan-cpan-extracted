package SQL::Statement::Functions::Date;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-12-12'; # DATE
our $DIST = 'SQL-Statement-Functions-Date'; # DIST
our $VERSION = '0.050'; # VERSION

1;
# ABSTRACT: More date/time functions

__END__

=pod

=encoding UTF-8

=head1 NAME

SQL::Statement::Functions::Date - More date/time functions

=head1 VERSION

This document describes version 0.050 of SQL::Statement::Functions::Date (from Perl distribution SQL-Statement-Functions-Date), released on 2022-12-12.

=head1 DESCRIPTION

This distribution contains several SQL functions to be used with
L<SQL::Statement>:

 YEAR()
 MONTH()
 DAYOFYEAR()
 DAYOFMONTH()
 DAY()
 WEEKOFYEAR()
 WEEKDAY()

They are based on MySQL's version. More functions wil be added as needed.

To use a function from Perl script:

 require SQL::Statement::Function::ByName::YEAR;
 $dbh->do(qq{CREATE FUNCTION YEAR NAME "SQL::Statement::Function::ByName::YEAR::SQL_FUNCTION_YEAR"});

To use a function from L<fsql>:

 % fsql -F YEAR --add-csv path/to/sometable.csv "SELECT col1, YEAR(col2) FROM sometable ..."

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SQL-Statement-Functions-Date>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SQL-Statement-Functions-Date>.

=head1 SEE ALSO

L<SQL::Statement>

L<App::fsql>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

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

This software is copyright (c) 2022, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SQL-Statement-Functions-Date>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
