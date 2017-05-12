package SQL::Statement::Function::ByName::YEAR;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;

sub SQL_FUNCTION_YEAR {
    my $param = $_[2];

    $param =~ /^(\d{4})-/ or return undef;
    $1;
}

1;
# ABSTRACT: YEAR() SQL function

__END__

=pod

=encoding UTF-8

=head1 NAME

SQL::Statement::Function::ByName::YEAR - YEAR() SQL function

=head1 VERSION

This document describes version 0.04 of SQL::Statement::Function::ByName::YEAR (from Perl distribution SQL-Statement-Functions-Date), released on 2017-01-25.

=head1 DESCRIPTION

Implements YEAR() SQL function. Syntax:

 YEAR(date)

Return integer (e.g. 2015), or undef if argument is not detected as date.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SQL-Statement-Functions-Date>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SQL-Statement-Functions-Date>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SQL-Statement-Functions-Date>

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
