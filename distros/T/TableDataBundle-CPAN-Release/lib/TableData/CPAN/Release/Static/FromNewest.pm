package TableData::CPAN::Release::Static::FromNewest;

use 5.010001;
use strict;
use warnings;

use parent 'TableData::Munge::Concat';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-28'; # DATE
our $DIST = 'TableDataBundle-CPAN-Release'; # DIST
our $VERSION = '0.003'; # VERSION

sub new {
    my $self = shift;
    my @tabledatalist;
    for my $year (reverse 1995..2021) {
        push @tabledatalist, "Munge::Reverse=tabledata,CPAN::Release::Static::$year";
    }
    $self->SUPER::new(tabledatalist => \@tabledatalist);
}

our %STATS = ("num_rows",350795,"num_columns",9); # STATS

1;
# ABSTRACT: CPAN releases (from newest to oldest)

__END__

=pod

=encoding UTF-8

=head1 NAME

TableData::CPAN::Release::Static::FromNewest - CPAN releases (from newest to oldest)

=head1 VERSION

This document describes version 0.003 of TableData::CPAN::Release::Static::FromNewest (from Perl distribution TableDataBundle-CPAN-Release), released on 2021-09-28.

=head1 SYNOPSIS

To use from Perl code:

 use TableData::CPAN::Release::Static::FromNewest;

 my $td = TableData::CPAN::Release::Static::FromNewest->new;

 # Iterate rows of the table
 $td->each_row_arrayref(sub { my $row = shift; ... });
 $td->each_row_hashref (sub { my $row = shift; ... });

 # Get the list of column names
 my @columns = $td->get_column_names;

 # Get the number of rows
 my $row_count = $td->get_row_count;

See also L<TableDataRole::Spec::Basic> for other methods.

To use from command-line (using L<tabledata> CLI):

 # Display as ASCII table and view with pager
 % tabledata CPAN::Release::Static::FromNewest --page

 # Get number of rows
 % tabledata --action count_rows CPAN::Release::Static::FromNewest

See the L<tabledata> CLI's documentation for other available actions and options.

=for Pod::Coverage ^(.+)$

=head1 TABLEDATA NOTES

The data was retrieved from MetaCPAN.

The C<status> column is the status of the release when the row was retrieved
from MetaCPAN. It is probably not current, so do not use it.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataBundle-CPAN-Release>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataBundle-CPAN-Release>.

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

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataBundle-CPAN-Release>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
