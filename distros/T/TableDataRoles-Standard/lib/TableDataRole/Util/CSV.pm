package TableDataRole::Util::CSV;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-01'; # DATE
our $DIST = 'TableDataRoles-Standard'; # DIST
our $VERSION = '0.009'; # VERSION

use 5.010001;
use Role::Tiny;
requires 'get_column_names';
requires 'has_next_item';
requires 'get_next_item';
requires 'reset_iterator';

sub as_csv {
    require Text::CSV_XS;
    my $self = shift;

    $self->{csv_parser} //= Text::CSV_XS->new({binary=>1});
    my $csv = $self->{csv_parser};

    $self->reset_iterator;

    my $res = "";
    $csv->combine($self->get_column_names);
    $res .= $csv->string . "\n";
    while ($self->has_next_item) {
        my $row = $self->get_next_item;
        $csv->combine(@$row);
        $res .= $csv->string . "\n";
    }
    $res;
}

1;
# ABSTRACT: Provide as_csv() and other CSV-related methods

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Util::CSV - Provide as_csv() and other CSV-related methods

=head1 VERSION

This document describes version 0.009 of TableDataRole::Util::CSV (from Perl distribution TableDataRoles-Standard), released on 2021-06-01.

=head1 PROVIDED METHODS

=head2 as_csv

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataRoles-Standard>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
