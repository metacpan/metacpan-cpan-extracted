package SQL::Statement::Function::ByName::ARGMINNUM;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use List::Util qw(min);

sub SQL_FUNCTION_ARGMINNUM {
    min(@_[2..$#_]);
}

1;
# ABSTRACT: SQL function to return the (numerically) minimum parameter

__END__

=pod

=encoding UTF-8

=head1 NAME

SQL::Statement::Function::ByName::ARGMINNUM - SQL function to return the (numerically) minimum parameter

=head1 VERSION

This document describes version 0.002 of SQL::Statement::Function::ByName::ARGMINNUM (from Perl distribution SQL-Statement-Functions-ArgMinMax), released on 2017-01-25.

=head1 DESCRIPTION

Uses L<List::Util>'s C<min>.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SQL-Statement-Functions-ArgMinMax>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SQL-Statement-Functions-MinMax>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SQL-Statement-Functions-ArgMinMax>

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
