package ## no critic: Modules::RequireFilenameMatchesPackage
    # hide from PAUSE
    TableDataRole::Size::DisplayResolution;

use 5.010001;
use strict;
use warnings;

use Role::Tiny;
with 'TableDataRole::Source::AOA';

around new => sub {
    require Display::Resolution;

    my $orig = shift;

    my $res = Display::Resolution::list_display_resolution_names();
    #die "Can't list display resolution sizes from Display::Resolution: $res->[0] - $res->[1]"
    #    unless $res->[0] == 200;

    my $aoa = [];
    my $column_names = [qw/
                              name
                              size
                              width
                              height
                          /];
    for my $name (sort keys %{ $res }) {
        my $size = $res->{$name};
        my ($width, $height) = $size =~ /\A(\d+)x(\d+)\z/
            or die "Invalid size syntax for '$name': $size (not in WxH format)";
        push @$aoa, [
            $name,
            $size,
            $width,
            $height,
        ];
    }

    $orig->(@_, aoa => $aoa, column_names=>$column_names);
};

package TableData::Size::DisplayResolution;

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-06-13'; # DATE
our $DIST = 'TableData-Size-DisplayResolution'; # DIST
our $VERSION = '0.001'; # VERSION

with 'TableDataRole::Size::DisplayResolution';

# STATS

1;
# ABSTRACT: Display resolution sizes

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Size::DisplayResolution - Display resolution sizes

=head1 VERSION

This document describes version 0.001 of TableDataRole::Size::DisplayResolution (from Perl distribution TableData-Size-DisplayResolution), released on 2023-06-13.

=head1 SYNOPSIS

To use from Perl code:

 use TableData::Size::DisplayResolution;

 my $td = TableData::Size::DisplayResolution->new;

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
 % tabledata Size::DisplayResolution --page

 # Get number of rows
 % tabledata --action count_rows Size::DisplayResolution

See the L<tabledata> CLI's documentation for other available actions and options.

=head1 DESCRIPTION

This table gets its data dynamically by querying
L<Display::Resolution>, so this is basically just a L<TableData>
interface for C<Display::Resolution>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableData-Size-DisplayResolution>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData-Size-DisplayResolution>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableData-Size-DisplayResolution>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
