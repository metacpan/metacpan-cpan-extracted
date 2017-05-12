package SQL::Statement::Functions::Date;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.04'; # VERSION

1;
# ABSTRACT: More date/time functions

__END__

=pod

=encoding UTF-8

=head1 NAME

SQL::Statement::Functions::Date - More date/time functions

=head1 VERSION

This document describes version 0.04 of SQL::Statement::Functions::Date (from Perl distribution SQL-Statement-Functions-Date), released on 2017-01-25.

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SQL-Statement-Functions-Date>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<SQL::Statement>

L<App::fsql>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
