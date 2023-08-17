package TableDataRole::Source::AOH;

use 5.010001;
use strict;
use warnings;

use Role::Tiny;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-06-14'; # DATE
our $DIST = 'TableDataRoles-Standard'; # DIST
our $VERSION = '0.016'; # VERSION

with 'TableDataRole::Spec::Basic';

sub new {
    my ($class, %args) = @_;

    my $aoh = delete $args{aoh} or die "Please specify 'aoh' argument";
    die "Unknown argument(s): ". join(", ", sort keys %args)
        if keys %args;

    bless {
        aoh => $aoh,
        pos => 0,
        # buffer => undef,
        # column_names => undef,
        # column_idxs  => undef,
    }, $class;
}

sub get_column_count {
    my $self = shift;
    my $aoh = $self->{aoh};
    unless (@$aoh) {
        return 0;
    }
    scalar keys(%{ $aoh->[0] });
}

sub get_column_names {
    my $self = shift;
    unless ($self->{column_names}) {
        my $aoh = $self->{aoh};
        $self->{column_names} = [];
        $self->{column_idxs} = {};
        if (@$aoh) {
            my $row = $aoh->[0];
            my $i = -1;
            for (sort keys %$row) {
                push @{ $self->{column_names} }, $_;
                $self->{column_idxs}{$_} = ++$i;
            }
        }
    }
    wantarray ? @{ $self->{column_names} } : $self->{column_names};
}

sub has_next_item {
    my $self = shift;
    $self->{pos} < @{$self->{aoh}};
}

sub get_next_item {
    my $self = shift;
    my $aoh = $self->{aoh};
    die "StopIteration" unless $self->{pos} < @{$aoh};
    my $row_hashref = $aoh->[ $self->{pos}++ ];
    my $row_aryref = [];
    for (keys %$row_hashref) {
        my $idx = $self->{column_idxs}{$_};
        next unless defined $idx;
        $row_aryref->[$idx] = $row_hashref->{$_};
    }
    $row_aryref;
}

sub get_next_row_hashref {
    my $self = shift;
    my $aoh = $self->{aoh};
    die "StopIteration" unless $self->{pos} < @{$aoh};
    $aoh->[ $self->{pos}++ ];
}

sub get_row_count {
    my $self = shift;
    scalar(@{ $self->{aoh} });
}

sub reset_iterator {
    my $self = shift;
    $self->{pos} = 0;
}

sub get_iterator_pos {
    my $self = shift;
    $self->{pos};
}

1;
# ABSTRACT: Get table data from an array of hashes

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Source::AOH - Get table data from an array of hashes

=head1 VERSION

This document describes version 0.016 of TableDataRole::Source::AOH (from Perl distribution TableDataRoles-Standard), released on 2023-06-14.

=head1 SYNOPSIS

 my $table = TableData::AOH->new(aoh => [{col1=>1,col2=>2}, {col1=>3,col2=>4}]);

=head1 DESCRIPTION

This role retrieves rows from an array of hashrefs.

=for Pod::Coverage ^(.+)$

=head1 ROLES MIXED IN

L<TableDataRole::Spec::Basic>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataRoles-Standard>.

=head1 SEE ALSO

L<TableDataRole::Source::AOA>

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
