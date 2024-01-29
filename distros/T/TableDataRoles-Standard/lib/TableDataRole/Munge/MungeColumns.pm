package TableDataRole::Munge::MungeColumns;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Role::Tiny;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-15'; # DATE
our $DIST = 'TableDataRoles-Standard'; # DIST
our $VERSION = '0.021'; # VERSION

with 'TableDataRole::Spec::Basic';

sub new {
    require Module::Load::Util;

    my ($class, %args) = @_;

    my $tabledata = delete $args{tabledata}
        or die "Please supply 'tabledata' argument";
    my $munge_column_names = delete $args{munge_column_names}
        or die "Please supply 'munge_column_names' argument";
    my $munge = delete $args{munge};
    my $munge_hashref = delete $args{munge_hashref};
    ($munge || $munge_hashref)
        or die "Please supply 'munge' or 'munge_hashref' argument";
    for ($munge_column_names, $munge, $munge_hashref) {
        next unless defined;
        unless (ref $_ eq 'CODE') {
            my $code = "package main; sub { no strict; no warnings; $_ }";
            log_trace "Eval-ing: $code";
            $_ = eval $code; ## no critic: BuiltinFunctions::ProhibitStringyEval
            die if $@;
        }
    }
    my $load = delete($args{load}) // 1;
    die "Unknown argument(s): ". join(", ", sort keys %args)
        if keys %args;

    $tabledata = Module::Load::Util::instantiate_class_with_optional_args({load=>$load, ns_prefix=>"TableData"}, $tabledata);
    my $column_names = $munge_column_names->(scalar $tabledata->get_column_names);

    bless {
        tabledata => $tabledata,
        column_names => $column_names,
        column_idxs => {map {$column_names->[$_] => $_} 0..$#{$column_names}},
        munge_column_names => $munge_column_names,
        munge => $munge,
        munge_hashref => $munge_hashref,
        pos => 0, # iterator
        # buffer => undef,
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

sub _fill_buffer {
    my $self = shift;
    return if $self->{buffer};
    while (1) {
        return unless $self->{tabledata}->has_next_item;
        if ($self->{munge}) {
            my $row = $self->{tabledata}->get_next_row_arrayref;
            my $munged_row = $self->{munge}->($row);
            $self->{buffer} = $munged_row;
            return;
        } else {
            my $row = $self->{tabledata}->get_next_item;
            my $row_hashref = { map {$self->{column_names}[$_] => $row->[$_]} 0..$#{$row} };
            my $munged_row_hashref = $self->{munge_hashref}->($row_hashref);
            my $munged_row = [];
            $munged_row->[ $self->{column_idxs}{$_} ] = $munged_row_hashref->{$_} for keys %$munged_row_hashref;
            $self->{buffer} = $munged_row;
            return;
        }
    }
}

sub has_next_item {
    my $self = shift;
    return 1 if $self->{buffer};
    $self->_fill_buffer;
    return $self->{buffer} ? 1:0;
}

sub get_next_item {
    my $self = shift;
    $self->_fill_buffer;
    die "StopIteration" unless $self->{buffer};
    $self->{pos}++;
    return delete $self->{buffer};
}

sub get_next_row_hashref {
    my $self = shift;
    my $row = $self->get_next_item;
    +{ map {($self->{column_names}->[$_] => $row->[$_])} 0..$#{$row} };
}

sub get_iterator_pos {
    my $self = shift;
    $self->{pos};
}

sub reset_iterator {
    my $self = shift;
    $self->{tabledata}->reset_iterator;
    $self->{pos} = 0;
}

1;
# ABSTRACT: Role to munge (add, remove, rename, reorder) columns of each row from another tabledata

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Munge::MungeColumns - Role to munge (add, remove, rename, reorder) columns of each row from another tabledata

=head1 VERSION

This document describes version 0.021 of TableDataRole::Munge::MungeColumns (from Perl distribution TableDataRoles-Standard), released on 2024-01-15.

=head1 SYNOPSIS

To use this role and create a curried constructor:

 package TableDataRole::Size::DisplayResolutionWithArea;
 use Role::Tiny;
 with 'TableDataRole::Munge::MungeColumns';
 around new => sub {
     my $orig = shift;
     $orig->(@_,
         tabledata => 'Size::DisplayResolution',
         munge_column_names => sub { my $colnames = shift; push @$colnames, 'area'; $colnames },
         munge_hashref => sub { my $row = shift; $row->{area} = $row->{width} * $row->{height}; $row },
     );
 };

 package TableData::Size::DisplayResolutionWithArea;
 use Role::Tiny::With;
 with 'TableDataRole::Size::DisplayResolutionWithArea';
 1;

In code that uses your TableData class:

 use TableData::Size::DisplayResolutionWithArea;

 my $td = TableData::Size::DisplayResolutionWithArea->new;
 ...

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 ROLES MIXED IN

L<TableDataRole::Spec::Basic>

=head1 PROVIDED METHODS

=head2 new

Usage:

 my $obj = $class->new(%args);

Constructor. Known arguments (C<*> marks required arguments):

=over

=item * tabledata*

Required. Tabledata module name (without the C<TableData::> prefix) with
optional arguments (see L<Module::Load::Util>'s
C<instantiate_class_with_optional_args> for more details).

=item * munge_column_names*

Required. A coderef to munge column names. Will be passed an arrayref containing
column names. Must return an arrayref containing the munged column names.

=item * munge

A coderef to munge columns of each data row. Will be passed an arrayref which is
the row to munge. Must return arrayref containing the munged row.

Either C<munge> B<or> C<munge_hashref> must be specified.

=item * filter_hashref

A coderef to munge columns of each data row. Will be passed a hashref which is
the row to munge. Must return hashref containing the munged row.

Either C<munge> B<or> C<munge_hashref> must be specified.

=item * load

Passed to L<Module::Load::Util>'s C<instantiate_class_with_optional_args>.

=back

Note that if your class wants to wrap this constructor in its own, you need to
create another role first, as shown in the example in Synopsis.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataRoles-Standard>.

=head1 SEE ALSO

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

This software is copyright (c) 2024, 2023, 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
