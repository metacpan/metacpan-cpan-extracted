package TableDataRole::Munge::Concat;

use 5.010001;
use strict;
use warnings;

use Role::Tiny;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-14'; # DATE
our $DIST = 'TableDataRoles-Standard'; # DIST
our $VERSION = '0.025'; # VERSION

with 'TableDataRole::Spec::Basic';

sub new {
    my ($class, %args) = @_;

    my $tabledatalist = delete $args{tabledatalist}
        or die "Please supply 'tabledatalist' argument";
    my $load = delete($args{load}) // 1;
    die "Please supply at least one tabledata in tabledatalist"
        unless @$tabledatalist;
    die "Unknown argument(s): ". join(", ", sort keys %args)
        if keys %args;

    bless {
        tabledatalist => [@$tabledatalist],
        load => $load,
        td_pos => 0, # which tabledata are we at
        pos => 0, # iterator
    }, $class;
}

# to lazily instantiate tabledata
sub _tabledatalist {
    require Module::Load::Util;

    my ($self, $idx) = @_;
    my $td = $self->{tabledatalist}[$idx];
    unless (ref $td) {
        $td = Module::Load::Util::instantiate_class_with_optional_args(
            {load=>$self->{load}, ns_prefix=>"TableData"}, $td);
        $self->{tabledatalist}[$idx] = $td;
    }
    $td;
}

sub get_column_count {
    my $self = shift;

    $self->_tabledatalist(0)->get_column_count;
}

sub get_column_names {
    my $self = shift;
    $self->_tabledatalist(0)->get_column_names;
}

sub has_next_item {
    my $self = shift;
    while (1) {
        my $td = $self->_tabledatalist($self->{td_pos});
        return 1 if $td->has_next_item;
        return 0 if $self->{td_pos} >= $#{$self->{tabledatalist}};
        $self->{td_pos}++;
    }
}

sub get_next_item {
    my $self = shift;
    while (1) {
        my $td = $self->_tabledatalist($self->{td_pos});
        do { $self->{pos}++; return $td->get_next_item } if $td->has_next_item;
        die "StopIteration" if $self->{td_pos} >= $#{$self->{tabledatalist}};
        $self->{td_pos}++;
    }
}

sub get_next_row_hashref {
    my $self = shift;
    my $row = $self->get_next_item;
    my $columns = $self->get_column_names; # cache?
    +{ map {($columns->[$_] => $row->[$_])} 0..$#{$columns} };
}

sub get_iterator_pos {
    my $self = shift;
    $self->{pos};
}

sub reset_iterator {
    my $self = shift;
    for (@{ $self->{tabledatalist} }) { $_->reset_iterator if ref $_ }
    $self->{td_pos} = 0;
    $self->{pos} = 0;
}

1;
# ABSTRACT: Role to access a series of other tabledata instances

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Munge::Concat - Role to access a series of other tabledata instances

=head1 VERSION

This document describes version 0.025 of TableDataRole::Munge::Concat (from Perl distribution TableDataRoles-Standard), released on 2024-05-14.

=head1 SYNOPSIS

To use this role and create a curried constructor:

 package TableDataRole::MyTable;
 use Role::Tiny;
 with 'TableDataRole::Munge::Concat';
 around new => sub {
     my $orig = shift;
     $orig->(@_, tabledatalist => ['CPAN::Release::Static::2020', 'CPAN::Release::Static::2020']);
 };

 package TableData::MyTable;
 use Role::Tiny::With;
 with 'TableDataRole::MyTable';
 1;

In code that uses your TableData class:

 use TableData::MyTable;

 my $td = TableData::MyTable->new;
 ...

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 ROLES MIXED IN

L<TableDataRole::Spec::Basic>

=head1 PROVIDED METHODS

=head2 new

Usage:

 my $obj = $class->new(%args);

Constructor. Known arguments:

=over

=item * tabledatalist

Required. Array of tabledata module names (without the C<TableData::> prefix)
with optional arguments (see L<Module::Load::Util> for more details).

At least one tabledata module is required.

All tabledata must have identical columns.

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
