package ## no critic: Modules::RequireFilenameMatchesPackage
    # hide from PAUSE
    TableDataRole::Size::Mattress;

use 5.010001;
use strict;
use warnings;

use Role::Tiny;
with 'TableDataRole::Munge::MungeColumns';

around new => sub {
    my $orig = shift;
    $orig->(@_,
            tabledata => 'Size::Mattress0',
            load => 0,
            munge_column_names => sub { my $colnames = shift; push @$colnames, 'size'; $colnames },
            munge_hashref => sub { my $row = shift; $row->{size} = "$row->{width}x$row->{length}"; $row },
        );
};

package TableData::Size::Mattress;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-06-14'; # DATE
our $DIST = 'TableData-Size-Mattress'; # DIST
our $VERSION = '0.002'; # VERSION

use Role::Tiny::With;
with 'TableDataRole::Size::Mattress';
with 'TableDataRole::Spec::TableDef';

sub get_table_def {
    return +{
        fields => {
            name    => {pos=>0, schema=>'str*'},
            summary => {pos=>1, schema=>'str*'},
            width   => {pos=>2, summary=>'Width, in cm', schema=>'posfloat*'},
            length  => {pos=>3, summary=>'Length, in cm', schema=>'posfloat*'},
            size    => {pos=>4, summary=>'Width, in cm', schema=>'posfloat*'}, # generated
        },
        pk => 'name',
    };
}

# STATS

package ## no critic: Modules::RequireFilenameMatchesPackage
    # hide from PAUSE
    TableData::Size::Mattress0;

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;
with 'TableDataRole::Source::CSVInDATA';

1;
# ABSTRACT: Mattress sizes

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Size::Mattress - Mattress sizes

=head1 VERSION

This document describes version 0.002 of TableDataRole::Size::Mattress (from Perl distribution TableData-Size-Mattress), released on 2023-06-14.

=head1 SYNOPSIS

To use from Perl code:

 use TableData::Size::Mattress;

 my $td = TableData::Size::Mattress->new;

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
 % tabledata Size::Mattress --page

 # Get number of rows
 % tabledata --action count_rows Size::Mattress

See the L<tabledata> CLI's documentation for other available actions and options.

=head1 DESCRIPTION

Keywords: bed sizes

=for Pod::Coverage ^(get_table_def)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableData-Size-Mattress>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData-Size-Mattress>.

=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/Bed_size>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableData-Size-Mattress>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__DATA__
name,summary,width,length
single_id,Single bed (Indonesia),90,200
double_id,Double/twin bed (Indonesia),120,200
twin_id,Double/twin bed (Indonesia),120,200
queen_id,Queen-size bed (Indonesia),160,200
king_id,King-size bed (Indonesia),180,200
superking_id,Super king-size bed (Indonesia),200,200
single_my,Single bed (Malaysia & Singapore),91,191
supersingle_my,Double/twin bed (Malaysia & Singapore),107,191
queen_my,Queen-size bed (Malaysia & Singapore),152,191
king_my,King-size bed (Malaysia & Singapore),183,191
