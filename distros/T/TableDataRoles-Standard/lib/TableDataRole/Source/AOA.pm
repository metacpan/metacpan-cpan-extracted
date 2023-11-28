package TableDataRole::Source::AOA;

use 5.010001;
use strict;
use warnings;

use Role::Tiny;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-25'; # DATE
our $DIST = 'TableDataRoles-Standard'; # DIST
our $VERSION = '0.019'; # VERSION

with 'TableDataRole::Spec::Basic';
with 'TableDataRole::Spec::GetRowByPos';

sub new {
    my ($class, %args) = @_;

    my $column_names = delete $args{column_names} or die "Please specify 'column_names' argument";
    my $aoa = delete $args{aoa} or die "Please specify 'aoa' argument";
    die "Unknown argument(s): ". join(", ", sort keys %args)
        if keys %args;

    bless {
        aoa => $aoa,
        pos => 0,
        column_names => $column_names,
        column_idxs  => {map {$column_names->[$_] => $_} 0..$#{$column_names}},
    }, $class;
}

sub get_column_count {
    my $self = shift;
    scalar @{ $self->{column_names} };
}

sub get_column_names {
    my $self = shift;
    wantarray ? @{ $self->{column_names} } : $self->{column_names};
}

sub has_next_item {
    my $self = shift;
    $self->{pos} < @{$self->{aoa}};
}

sub get_next_item {
    my $self = shift;
    my $aoa = $self->{aoa};
    die "StopIteration" unless $self->{pos} < @{$aoa};
    $aoa->[ $self->{pos}++ ];
}

sub get_next_row_hashref {
    my $self = shift;
    my $row_aryref = $self->get_next_item;
    +{ map { $self->{column_names}[$_] => $row_aryref->[$_] } 0..$#{$self->{column_names}} };
}

sub get_row_count {
    my $self = shift;
    scalar(@{ $self->{aoa} });
}

sub reset_iterator {
    my $self = shift;
    $self->{pos} = 0;
}

sub get_iterator_pos {
    my $self = shift;
    $self->{pos};
}

sub get_item_at_pos {
    my ($self, $index) = @_;

    die "OutOfBounds" if
        $index <  0 && -$index >  @{ $self->{aoa} } ||
        $index >= 0 &&  $index >= @{ $self->{aoa} };
    $self->{aoa}->[$index];
}

sub get_row_at_pos_hashref {
    my ($self, $index) = @_;
    my $row_aryref = $self->get_item_at_pos($index);
    +{ map { $self->{column_names}[$_] => $row_aryref->[$_] } 0..$#{$self->{column_names}} };
}

sub has_item_at_pos {
    my ($self, $index) = @_;

    return 0 if
        $index <  0 && -$index >  @{ $self->{aoa} } ||
        $index >= 0 &&  $index >= @{ $self->{aoa} };
    1;
}

1;
# ABSTRACT: Get table data from an array of arrays

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Source::AOA - Get table data from an array of arrays

=head1 VERSION

This document describes version 0.019 of TableDataRole::Source::AOA (from Perl distribution TableDataRoles-Standard), released on 2023-11-25.

=head1 SYNOPSIS

 my $table = TableData::AOA->new(
     column_names => [qw/col1 col2/],
     aoa => [ [1,2], [3,4] ],
 );

=head1 DESCRIPTION

This role retrieves rows from an array of arrayrefs. You also need to supply
C<column_names> containing array of column names.

Notes:

C<get_item_at_pos> does not modify iterator position.

=for Pod::Coverage ^(.+)$

=head1 ROLES MIXED IN

L<TableDataRole::Spec::Basic>

L<TableDataRole::Spec::GetRowByPos>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataRoles-Standard>.

=head1 SEE ALSO

L<TableDataRole::Source::AOH>

L<TableData>

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

This software is copyright (c) 2023, 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
