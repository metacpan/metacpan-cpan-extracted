package SQL::Statement::Functions::Logic;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.001'; # VERSION

1;
# ABSTRACT: Logic functions

__END__

=pod

=encoding UTF-8

=head1 NAME

SQL::Statement::Functions::Logic - Logic functions

=head1 VERSION

This document describes version 0.001 of SQL::Statement::Functions::Logic (from Perl distribution SQL-Statement-Functions-Logic), released on 2017-01-25.

=head1 DESCRIPTION

This distribution contains several SQL functions to be used with
L<SQL::Statement>:

 IF()

To use a function from Perl script:

 require SQL::Statement::Function::ByName::IF;
 $dbh->do(qq{CREATE FUNCTION IF NAME "SQL::Statement::Function::ByName::MAXNUM::SQL_FUNCTION_IF"});

To use a function from L<fsql>:

 % fsql -F IF --add-csv path/to/sometable.csv "SELECT IF(a > b,c,d) FROM sometable ..."

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SQL-Statement-Functions-Logic>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SQL-Statement-Functions-Logic>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SQL-Statement-Functions-Logic>

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
