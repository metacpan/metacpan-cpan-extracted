package SQL::Statement::Functions::ArgMinMax;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

1;
# ABSTRACT: ARGMIN*/ARGMAX* functions

__END__

=pod

=encoding UTF-8

=head1 NAME

SQL::Statement::Functions::ArgMinMax - ARGMIN*/ARGMAX* functions

=head1 VERSION

This document describes version 0.002 of SQL::Statement::Functions::ArgMinMax (from Perl distribution SQL-Statement-Functions-ArgMinMax), released on 2017-01-25.

=head1 DESCRIPTION

This distribution contains several SQL functions to be used with
L<SQL::Statement>:

 ARGMAXNUM()
 ARGMAXSTR()
 ARGMINNUM()
 ARGMINSTR()

These functions are not aggregate functions. They are added due to the lack of
CASE statement as well as IF function in SQL::Statement. For example, this SQL
statement:

 SELECT CASE WHEN a > b THEN a ELSE b END FROM table

can be expressed with:

 SELECT ARGMAXNUM(a, b) FROM table

To use a function from Perl script:

 require SQL::Statement::Function::ByName::ARGMAXNUM;
 $dbh->do(qq{CREATE FUNCTION ARGMAXNUM NAME "SQL::Statement::Function::ByName::ARGMAXNUM::SQL_FUNCTION_ARGMAXNUM"});

To use a function from L<fsql>:

 % fsql -F ARGMAXNUM --add-csv path/to/sometable.csv "SELECT ARGMAXNUM(col1,col2) FROM sometable ..."

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SQL-Statement-Functions-ArgMinMax>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SQL-Statement-Functions-MinMax>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SQL-Statement-Functions-ArgMinMax>

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
