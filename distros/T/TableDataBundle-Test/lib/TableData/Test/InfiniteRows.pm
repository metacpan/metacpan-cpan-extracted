package TableData::Test::InfiniteRows;

use 5.010001;
use strict;
use warnings;

use Lingua::EN::Nums2Words;

use Role::Tiny;
with 'TableDataRole::Spec::Basic';

sub new {
    my $class = shift;
    bless {pos=>0}, $class;
}

sub get_column_count { 1 }

sub get_column_names { wantarray ? ("num","word") : ["num","word"] }

sub has_next_item { 1 }

sub get_next_item {
    my $self = shift;
    $self->{pos}++;
    [$self->{pos}, Lingua::EN::Nums2Words::num2word($self->{pos})];
}

sub get_next_row_hashref {
    my $self = shift;
    $self->{pos}++;
    +{
        num => $self->{pos},
        word => Lingua::EN::Nums2Words::num2word($self->{pos}),
    };
}

sub get_row_count { -1 }

sub reset_iterator {
    my $self = shift;
    $self->{pos} = 0;
}

sub get_iterator_pos {
    my $self = shift;
    $self->{pos};
}

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-10'; # DATE
our $DIST = 'TableDataBundle-Test'; # DIST
our $VERSION = '0.001'; # VERSION

our %STATS = ("num_columns",1,"num_rows",-1); # STATS

1;
# ABSTRACT: An example of table data with infinite rows

__END__

=pod

=encoding UTF-8

=head1 NAME

TableData::Test::InfiniteRows - An example of table data with infinite rows

=head1 VERSION

This document describes version 0.001 of TableData::Test::InfiniteRows (from Perl distribution TableDataBundle-Test), released on 2023-02-10.

=head1 SYNOPSIS

To use from Perl code:

 use TableData::Test::InfiniteRows;

 my $td = TableData::Test::InfiniteRows->new;

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
 % tabledata Test::InfiniteRows --page

 # Get number of rows
 % tabledata --action count_rows Test::InfiniteRows

See the L<tabledata> CLI's documentation for other available actions and options.

=head1 TABLEDATA STATISTICS

 +-------------+-------+
 | key         | value |
 +-------------+-------+
 | num_columns | 1     |
 | num_rows    | -1    |
 +-------------+-------+

The statistics is available in the C<%STATS> package variable.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataBundle-Test>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataBundle-Test>.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataBundle-Test>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
