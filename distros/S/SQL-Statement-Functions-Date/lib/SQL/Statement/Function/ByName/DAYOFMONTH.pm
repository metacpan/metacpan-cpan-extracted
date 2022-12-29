package SQL::Statement::Function::ByName::DAYOFMONTH;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-12-12'; # DATE
our $DIST = 'SQL-Statement-Functions-Date'; # DIST
our $VERSION = '0.050'; # VERSION

sub SQL_FUNCTION_DAYOFMONTH {
    my $param = $_[2];

    $param =~ /^\d{4}-\d{2}-(\d{2})/ or return undef; ## no critic: TestingAndDebugging::ProhibitExplicitReturnUndef
    $1+0;
}

1;
# ABSTRACT: Return day of month of a date/datetime expression

__END__

=pod

=encoding UTF-8

=head1 NAME

SQL::Statement::Function::ByName::DAYOFMONTH - Return day of month of a date/datetime expression

=head1 VERSION

This document describes version 0.050 of SQL::Statement::Function::ByName::DAYOFMONTH (from Perl distribution SQL-Statement-Functions-Date), released on 2022-12-12.

=head1 DESCRIPTION

Implements DAYOFMONTH() SQL function. Syntax:

 DAYOFMONTH(date)

Returns 1-31, or undef if argument is not detected as date.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SQL-Statement-Functions-Date>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SQL-Statement-Functions-Date>.

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

This software is copyright (c) 2022, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SQL-Statement-Functions-Date>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
