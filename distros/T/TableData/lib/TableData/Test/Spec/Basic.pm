package TableData::Test::Spec::Basic;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-01'; # DATE
our $DIST = 'TableData'; # DIST
our $VERSION = '0.2.1'; # VERSION

use strict;
use warnings;

use Role::Tiny::With;

with 'TableDataRole::Spec::Basic';

my $rows = [
    {a=>1, b=>2},
    {a=>3, b=>4},
    {a=>"5 2", b=>"6,2"},
];
my $columns = [qw/a b/];

sub new {
    my $class = shift;
    bless {pos=>0}, $class;
}

sub _rows {
    $rows;
}

sub reset_iterator {
    my $self = shift;
    $self->{pos} = 0;
}

sub get_iterator_pos {
    my $self = shift;
    $self->{pos};
}

sub has_next_item {
    my $self = shift;
    $self->{pos} < @$rows;
}

sub get_next_item {
    my $self = shift;
    die "StopIteration" if $self->{pos} >= @$rows;
    my $row_hashref = $rows->[ $self->{pos}++ ];
    [map {$row_hashref->{$_}} @$columns];
}

sub get_next_row_hashref {
    my $self = shift;
    die "StopIteration" if $self->{pos} >= @$rows;
    $rows->[ $self->{pos}++ ];
}

sub get_row_hashref {
    my $self = shift;
    return undef unless $rows->[ $self->{index} ];
    $rows->[ $self->{index}++ ];
}

sub get_column_count {
    my $self = shift;
    scalar(keys %{$rows->[0]});
}

sub get_column_names {
    my $self = shift;
    my @names = sort keys %{$rows->[0]};
    wantarray ? @names : \@names;
}

1;

# ABSTRACT: A test table data

__END__

=pod

=encoding UTF-8

=head1 NAME

TableData::Test::Spec::Basic - A test table data

=head1 VERSION

This document describes version 0.2.1 of TableData::Test::Spec::Basic (from Perl distribution TableData), released on 2021-06-01.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
