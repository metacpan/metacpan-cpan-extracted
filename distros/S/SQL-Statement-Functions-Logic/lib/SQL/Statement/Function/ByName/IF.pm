package SQL::Statement::Function::ByName::IF;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

sub SQL_FUNCTION_IF {
    $_[2] ? $_[3] : $_[4];
}

1;
# ABSTRACT: SQL function to return a value or the other depending on condition

__END__

=pod

=encoding UTF-8

=head1 NAME

SQL::Statement::Function::ByName::IF - SQL function to return a value or the other depending on condition

=head1 VERSION

This document describes version 0.001 of SQL::Statement::Function::ByName::IF (from Perl distribution SQL-Statement-Functions-Logic), released on 2017-01-25.

=head1 SYNOPSIS

In your SQL:

 SELECT IF(cond, a, b) FROM table

=head1 DESCRIPTION

Caveat: the notion of true and false follows Perl's notion.

Caveat: due to the current limitation of SQL::Parser, this function is not as
useful as it should be, e.g. SQL::Parser cannot parse this correctly:

 SELECT IF(col > 10, a, b) FROM table

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SQL-Statement-Functions-Logic>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SQL-Statement-Functions-Logic>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SQL-Statement-Functions-Logic>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
