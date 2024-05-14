package TableDataRole::Munge::SerializeRef;

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
    require Module::Load::Util;

    my ($class, %args) = @_;

    my $tabledata = delete $args{tabledata} or die "Please specify 'tabledata' argument";
    my $load = delete($args{load}) // 1;
    my $serializer = delete($args{serializer}) // 'json';
    die "Unknown argument(s): ". join(", ", sort keys %args)
        if keys %args;

    my $td = Module::Load::Util::instantiate_class_with_optional_args(
        {load=>$load, ns_prefix=>"TableData"}, $tabledata);

    if ($serializer eq 'json') {
        require JSON::MaybeXS;
        $serializer = sub {
            JSON::MaybeXS::encode_json($_[0]);
        };
    } elsif (ref($serializer) ne 'CODE') {
        die "Invalid value for serializer '$serializer': please supply a coderef or 'json'";
    }

    bless {
        tabledata => $tabledata,
        td => $td,
        pos => 0,
        serializer => $serializer,
    }, $class;
}

sub get_column_count {
    my $self = shift;
    $self->{td}->get_column_count;
}

sub get_column_names {
    my $self = shift;
    $self->{td}->get_column_names;
}

sub has_next_item {
    my $self = shift;
    $self->{td}->has_next_item;
}

sub get_next_item {
    my $self = shift;
    my $row = $self->{td}->get_next_item;
    for (@$row) {
        if (ref $_) { $_ = $self->{serializer}->($_) }
    }
    $row;
}

sub get_next_row_hashref {
    my $self = shift;
    my $row = $self->get_next_item;
    unless ($self->{_column_names}) {
        $self->{_column_names} = $self->{td}->get_column_names;
    }
    +{ map {($self->{_column_names}->[$_] => $row->[$_])} 0..$#{$row} };
}

sub get_iterator_pos {
    my $self = shift;
    $self->{td}->get_iterator_pos;
}

sub reset_iterator {
    my $self = shift;
    $self->{td}->reset_iterator;
}

1;
# ABSTRACT: Serialize references in columns

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Munge::SerializeRef - Serialize references in columns

=head1 VERSION

This document describes version 0.025 of TableDataRole::Munge::SerializeRef (from Perl distribution TableDataRoles-Standard), released on 2024-05-14.

=head1 SYNOPSIS

To use this role and create a curried constructor:

 package TableDataRole::MyTable;
 use Role::Tiny;
 with 'TableDataRole::Munge::SerializeRef';
 use TableDataRole::MyOtherTable;
 around new => sub {
     my $orig = shift;
     $orig->(@_, tabledata => "MyOtherTable");
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

This role serializes reference values in columns, by default using JSON.

=for Pod::Coverage ^(.+)$

=head1 ROLES MIXED IN

L<TableDataRole::Spec::Basic>

=head1 PROVIDED METHODS

=head2 new

Usage:

 my $obj = $class->new(%args);

Constructor. Known arguments:

=over

=item * tabledata

Required. Name of tabledata module (without the C<TableData::> prefix), with
optional arguments. See
L<Module::Load::Util/instantiate_class_with_optional_args> for more details.

=item * load

Passed to L<Module::Load::Util>'s C<instantiate_class_with_optional_args>.

=item * serializer

A coderef, or one of: C<json>. Default: C<json>.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataRoles-Standard>.

=head1 SEE ALSO

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

This software is copyright (c) 2024, 2023, 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
