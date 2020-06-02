package TablesRole::Source::CSVDATA;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-01'; # DATE
our $DIST = 'TablesRoles-Standard'; # DIST
our $VERSION = '0.003'; # VERSION

use Role::Tiny;
use Role::Tiny::With;
with 'TablesRole::Spec::Basic';

sub new {
    no strict 'refs';
    require Text::CSV_XS;

    my $class = shift;

    my $fh = \*{"$class\::DATA"};
    my $fhpos_data_begin = tell $fh;

    my $csv_parser = Text::CSV_XS->new({binary=>1});

    my $columns = $csv_parser->getline($fh)
        or die "Can't read columns from first row of CSV";
    my $fhpos_datarow_begin = tell $fh;

    bless {
        fh => $fh,
        fhpos_data_begin => $fhpos_data_begin,
        fhpos_datarow_begin => $fhpos_datarow_begin,
        csv_parser => $csv_parser,
        columns => $columns,
        i => 0, # iterator
    }, $class;
}

sub as_csv {
    my $self = shift;

    my $fh = $self->{fh};
    my $oldpos = tell $fh;
    seek $fh, $self->{fhpos_data_begin}, 0;
    $self->{i} = -1;
    local $/;
    scalar <$fh>;
}

sub get_column_count {
    my $self = shift;

    scalar @{ $self->{columns} };
}

sub get_column_names {
    my $self = shift;
    wantarray ? @{ $self->{columns} } : $self->{columns};
}

sub get_row_arrayref {
    my $self = shift;
    my $fh = $self->{fh};
    my $row = $self->{csv_parser}->getline($fh);
    return unless $row;
    $self->{i}++;
    $row;
}

sub get_row_count {
    my $self = shift;

    1 while my $row = $self->get_row_arrayref;
    $self->{i};
}

sub get_row_hashref {
    my $self = shift;
    my $row_arrayref = $self->get_row_arrayref;
    return unless $row_arrayref;

    # convert to hashref
    my $row_hashref = {};
    my $columns = $self->{columns};
    for my $i (0 .. $#{$columns}) {
        $row_hashref->{ $columns->[$i] } = $row_arrayref->[$i];
    }
    $row_hashref;
}

sub reset_iterator {
    my $self = shift;
    my $fh = $self->{fh};
    seek $fh, $self->{fhpos_datarow_begin}, 0;
    $self->{i} = 0;
}

1;
# ABSTRACT: Role to access table data from CSV in DATA section

__END__

=pod

=encoding UTF-8

=head1 NAME

TablesRole::Source::CSVDATA - Role to access table data from CSV in DATA section

=head1 VERSION

This document describes version 0.003 of TablesRole::Source::CSVDATA (from Perl distribution TablesRoles-Standard), released on 2020-06-01.

=head1 DESCRIPTION

This role expects table data in CSV format in the DATA section. First row MUST
contain the column names.

=for Pod::Coverage ^(.+)$

=head1 ROLES MIXED IN

L<TablesRole::Spec::Basic>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TablesRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TablesRoles-Standard>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TablesRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<TablesRole::Source::CSVFile>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
