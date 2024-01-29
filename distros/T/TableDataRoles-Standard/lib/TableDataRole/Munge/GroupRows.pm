package TableDataRole::Munge::GroupRows;

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
with 'TableDataRole::Source::AOA';

sub new {
    require Module::Load::Util;

    my ($class, %args) = @_;

    my $tabledata = delete $args{tabledata}
        or die "Please supply 'tabledata' argument";
    my $key = delete($args{key}) // 'key';
    length($key) > 1 or die "Argument 'key' cannot be empty";
    $key ne 'rows' or die "Argument 'key' cannot have the value of 'rows'";
    my $calc_key = delete $args{calc_key}
        or die "Please supply 'calc_key' argument";
    my $load = delete($args{load}) // 1;
    die "Unknown argument(s): ". join(", ", sort keys %args)
        if keys %args;

    my $td = Module::Load::Util::instantiate_class_with_optional_args(
        {load=>$load, ns_prefix=>"TableData"}, $tabledata);

    # group the rows now into aoa
    my $aoa = [];
    {
        my %rownum; # key=calculated key, val=rownum
        $td->each_row_arrayref(
            sub {
                my $row_arrayref = shift;
                my $row_hashref = $td->convert_row_arrayref_to_hashref($row_arrayref);
                my $key = $calc_key->($row_hashref, $aoa);
                defined $key or die "BUG: calc_key produced undef key!";
                unless (defined $rownum{$key}) {
                    $rownum{$key} = @$aoa;
                    $aoa->[ $rownum{$key} ] //= [$key, []];
                }
                push @{ $aoa->[ $rownum{$key} ][1] }, $row_arrayref;
            });
    }

    bless {
        tabledata => $tabledata,
        _tabledata => $td,
        column_names => [$key, 'rows'],
        column_idxs => {$key=>0, rows=>1},
        aoa => $aoa,
        pos => 0,
    }, $class;
}

1;
# ABSTRACT: Role to group rows from another tabledata

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Munge::GroupRows - Role to group rows from another tabledata

=head1 VERSION

This document describes version 0.021 of TableDataRole::Munge::GroupRows (from Perl distribution TableDataRoles-Standard), released on 2024-01-15.

=head1 SYNOPSIS

To use this role and create a curried constructor:

 package TableDataRole::Perl::CPAN::Release::Static::GroupedDaily;
 use Role::Tiny;
 with 'TableDataRole::Munge::GroupRows';
 around new => sub {
     my $orig = shift;
     $orig->(@_,
         tabledata => 'Perl::CPAN::Release::Static',
         key => 'date',
         calc_key => sub {
             my $row = shift; # hashref
             $row->{date} =~ /\A(\d\d\d\d-\d\d-\d\d)/ or die; # extract YY-MM-DD from ISO8601 datetime
             $1;
         },
     );
 };

 package TableData::;Perl::CPAN::Release::Static::GroupedDaily;
 use Role::Tiny::With;
 with 'TableDataRole::Perl::CPAN::Release::Static::GroupedDaily';
 1;

In code that uses your TableData class:

 use TableData::Perl::CPAN::Release::GroupedDaily;

 my $td = TableData::Perl::CPAN::Release::GroupedDaily->new;
 ...

=head1 DESCRIPTION

This role groups rows from another tabledata and returns a two-column table with
these columns: C<$key>, C<rows>. The name of the key column can be customized
via the constributor argument C<key>, defaults to C<key> if unspecified. The
C<rows> columns will contain the (arrayref of) original rows that are grouped
under the single key value. You also need to provide C<calc_key> to calculate
the key value from a hashref row.

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

Required. Tabledata module name (without the C<TableData::> prefix) with
optional arguments (see L<Module::Load::Util> for more details).

=item * key

Name of key column. Default to C<key>.

=item * calc_key

Required. Coderef to calculate key from hashref row. Codekey will be passed:

 ($row_hashref, $aoa)

where C<$aoa> is the grouped table data structure being constructed. This makes
it possible to insert or delete rows as needed, e.g. when grouping by date, you
can insert empty rows to close date gaps.

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
