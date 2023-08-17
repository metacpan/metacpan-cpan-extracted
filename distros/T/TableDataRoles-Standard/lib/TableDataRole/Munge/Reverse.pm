package TableDataRole::Munge::Reverse;

use 5.010001;
use strict;
use warnings;

use Role::Tiny;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-06-14'; # DATE
our $DIST = 'TableDataRoles-Standard'; # DIST
our $VERSION = '0.016'; # VERSION

with 'TableDataRole::Spec::Basic';
with 'TableDataRole::Source::AOA';

sub new {
    require Module::Load::Util;

    my ($class, %args) = @_;

    my $tabledata = delete $args{tabledata} or die "Please specify 'tabledata' argument";
    my $load = delete($args{load}) // 1;
    die "Unknown argument(s): ". join(", ", sort keys %args)
        if keys %args;
    my $td = Module::Load::Util::instantiate_class_with_optional_args(
        {load=>$load, ns_prefix=>"TableData"}, $tabledata);
    my @rows = reverse $td->get_all_rows_arrayref;
    my $column_names = $td->get_column_names;
    TableDataRole::Source::AOA->new(
        aoa => \@rows,
        column_names => $column_names,
    );
}

1;
# ABSTRACT: Reverse the rows of another tabledata

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Munge::Reverse - Reverse the rows of another tabledata

=head1 VERSION

This document describes version 0.016 of TableDataRole::Munge::Reverse (from Perl distribution TableDataRoles-Standard), released on 2023-06-14.

=head1 SYNOPSIS

To use this role and create a curried constructor:

 package TableDataRole::MyTable;
 use Role::Tiny;
 with 'TableDataRole::Munge::Reverse';
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

This role returns rows from another tabledata module in reverse order.

Implementation notes: this role first loads all the rows into memory, then serve
from it.

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

This software is copyright (c) 2023, 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
