package TableDataRole::Source::CSVInFile;

use 5.010001;
use strict;
use warnings;

use Role::Tiny;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-15'; # DATE
our $DIST = 'TableDataRoles-Standard'; # DIST
our $VERSION = '0.023'; # VERSION

with 'TableDataRole::Spec::Basic';

sub new {
    require Text::CSV_XS;

    my ($class, %args) = @_;

    my $fh;
    if (defined(my $filename = delete $args{filename})) {
        open $fh, "<", $filename
            or die "Can't open file '$filename': $!";
    } elsif (defined($fh = delete $args{filehandle})) {
    } else {
        die "Please specify 'filename' or 'filehandle'";
    }
    die "Unknown argument(s): ". join(", ", sort keys %args)
        if keys %args;

    my $csv_parser = Text::CSV_XS->new({binary=>1, auto_diag=>9, diag_verbose=>1});

    my $fhpos_data_begin = tell $fh;
    my $columns = $csv_parser->getline($fh)
        or die "Can't read columns from first row of CSV file";
    my $fhpos_datarow_begin = tell $fh;

    bless {
        fh => $fh,
        fhpos_data_begin => $fhpos_data_begin,
        fhpos_datarow_begin => $fhpos_datarow_begin,
        csv_parser => $csv_parser,
        columns => $columns,
        pos => 0, # iterator
    }, $class;
}

sub as_csv {
    my $self = shift;

    my $fh = $self->{fh};
    my $oldpos = tell $fh;
    seek $fh, $self->{fhpos_data_begin}, 0;
    $self->{pos} = 0;
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

sub has_next_item {
    my $self = shift;
    my $fh = $self->{fh};
    !eof($fh);
}

sub get_next_item {
    my $self = shift;
    my $fh = $self->{fh};
    die "StopIteration" if eof($fh);
    my $row = $self->{csv_parser}->getline($fh);
    $self->{pos}++;
    $row;
}

sub get_next_row_hashref {
    my $self = shift;
    my $fh = $self->{fh};
    die "StopIteration" if eof($fh);
    my $row = $self->{csv_parser}->getline($fh);
    $self->{pos}++;
    +{ map {($self->{columns}[$_] => $row->[$_])} 0..$#{$self->{columns}} };
}

sub get_iterator_pos {
    my $self = shift;
    $self->{pos};
}

sub reset_iterator {
    my $self = shift;
    my $fh = $self->{fh};
    seek $fh, $self->{fhpos_datarow_begin}, 0;
    $self->{pos} = 0;
}

sub DESTROY {
    my $self = shift;
    my $fh = $self->{fh};
    seek $fh, $self->{fhpos_data_begin}, 0;
}

1;
# ABSTRACT: Role to access table data from CSV in a file/filehandle

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Source::CSVInFile - Role to access table data from CSV in a file/filehandle

=head1 VERSION

This document describes version 0.023 of TableDataRole::Source::CSVInFile (from Perl distribution TableDataRoles-Standard), released on 2024-01-15.

=head1 SYNOPSIS

To use this role and create a curried constructor:

 package TableDataRole::MyTable;
 use Role::Tiny;
 with 'TableDataRole::Source::CSVInFile';
 around new => sub {
     my $orig = shift;
     $orig->(@_, filename => '/path/to/some.csv'); # you can also pass 'filehandle', alternatively
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

This role expects table data in CSV format in a specified file/filehandle. First
row MUST contain the column names.

=for Pod::Coverage ^(.+)$

=head1 ROLES MIXED IN

L<TableDataRole::Spec::Basic>

=head1 PROVIDED METHODS

=head2 new

Usage:

 my $obj = $class->new(%args);

Constructor. Known arguments:

=over

=item * filename

Supply path to the CSV file. Alternatively, you can also pass C<filehandle>
instead. Either C<filename> or C<filehandle> is required.

=item * filehandle

Supply handle to the CSV file. Alternatively, you can also pass C<filename>
instead. Either C<filename> or C<filehandle> is required.

=back

Note that if your class wants to wrap this constructor in its own, you need to
create another role first, as shown in the example in Synopsis.

=head2 as_csv

A more efficient version than one provided by L<TableDataRole::Util::CSV>, since
the data is already in CSV form.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataRoles-Standard>.

=head1 SEE ALSO

L<TableDataRole::Source::CSVInDATA>

L<TableDataRole::Source::CSVInFiles>

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
