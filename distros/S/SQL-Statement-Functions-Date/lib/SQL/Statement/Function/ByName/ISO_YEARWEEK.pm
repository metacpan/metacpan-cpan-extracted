package SQL::Statement::Function::ByName::ISO_YEARWEEK;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;

use Date::Calc qw(Week_of_Year);

sub SQL_FUNCTION_ISO_YEARWEEK {
    my $param = $_[2];
    $param =~ /\A(\d{4})-(\d{2})-(\d{2})/ or return undef;
    my ($woyear, $year) = Week_of_Year($1, $2, $3);
    sprintf "%04dW%02d", $year, $woyear;
}

1;
# ABSTRACT: ISO_YEARWEEK() SQL function

__END__

=pod

=encoding UTF-8

=head1 NAME

SQL::Statement::Function::ByName::ISO_YEARWEEK - ISO_YEARWEEK() SQL function

=head1 VERSION

This document describes version 0.04 of SQL::Statement::Function::ByName::ISO_YEARWEEK (from Perl distribution SQL-Statement-Functions-Date), released on 2017-01-25.

=head1 DESCRIPTION

Given a date in YYYY-mm-dd format, will return the ISO 8601 YYYY-Www format.
Example:

 ISO_YEARWEEK('2016-01-01')  -- 2015W53
 ISO_YEARWEEK('2016-01-04')  -- 2016W01

This can be an alternative to WEEKOFYEAR(), where it can give e.g. 53 even
though the date is in the first week of January.

 WEEKOFYEAR('2016-01-01')  -- 53
 WEEKOFYEAR('2016-01-04')  -- 1

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
