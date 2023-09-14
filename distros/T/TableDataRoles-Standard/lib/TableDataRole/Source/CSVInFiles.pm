package TableDataRole::Source::CSVInFiles;

use 5.010001;
use strict;
use warnings;

use Role::Tiny;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-31'; # DATE
our $DIST = 'TableDataRoles-Standard'; # DIST
our $VERSION = '0.017'; # VERSION

with 'TableDataRole::Spec::Basic';

sub new {
    require Text::CSV_XS;

    my ($class, %args) = @_;

    my $fhs = [];
    if (defined(my $filenames = delete $args{filenames})) {
        for my $filename (@$filenames) {
            open my $fh, "<", $filename
                or die "Can't open file '$filename': $!";
            push @$fhs, $fh;
        }
    } elsif (defined($fhs = delete $args{filehandles})) {
    } else {
        die "Please specify 'filenames' or 'filehandles'";
    }
    @$fhs or die "Please supply at least one filename/filehandle";
    die "Unknown argument(s): ". join(", ", sort keys %args)
        if keys %args;

    my $csv_parser = Text::CSV_XS->new({binary=>1});

    my $files = [];
    my $columns;
    for my $fh (@$fhs) {
        my $fhpos_data_begin = tell $fh;
        $columns = $csv_parser->getline($fh)
            or die "Can't read columns from first row of CSV file";
        my $fhpos_datarow_begin = tell $fh;
        push @$files, {
            fh => $fh,
            fhpos_data_begin => $fhpos_data_begin,
            fhpos_datarow_begin => $fhpos_datarow_begin,
        };
    }
    bless {
        files => $files,
        csv_parser => $csv_parser,
        columns => $columns,
        file_pos => 0, # which file are we at
        pos => 0, # iterator
    }, $class;
}

sub as_csv {
    my $self = shift;

    my $res = "";
    for my $i (0 .. $#{$self->{files}}) {
        my $file = $self->{files}[$i];
        my $fh = $file->{fh};
        my $oldpos = tell $fh;
        seek $fh, ($i ? $file->{fhpos_datarow_begin} : $file->{fhpos_data_begin}), 0;
        local $/;
        $res .= scalar <$fh>;
    }
    $self->{pos} = 0;
    $self->{file_pos} = 0;
    $res;
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
    my $files = $self->{files};
    my $seek = 0;
    while (1) {
        my $file = $self->{files}[$self->{file_pos}];
        my $fh = $file->{fh};
        if ($seek) {
            seek $fh, $file->{fhpos_datarow_begin}, 0;
            $seek = 0;
        }
        return 1 unless eof($fh);
        return 0 if $self->{file_pos} >= $#{$self->{files}};
        $self->{file_pos}++;
        $seek++;
    }
}

sub get_next_item {
    my $self = shift;
    my $files = $self->{files};
    my $seek = 0;
    while (1) {
        my $file = $self->{files}[$self->{file_pos}];
        my $fh = $file->{fh};
        if ($seek) {
            seek $fh, $file->{fhpos_datarow_begin}, 0;
            $seek = 0;
        }
        unless (eof($fh)) {
            my $row = $self->{csv_parser}->getline($fh);
            $self->{pos}++;
            return $row;
        }
        die "StopIteration" if $self->{file_pos} >= $#{$self->{files}};
        $self->{file_pos}++;
        $seek++;
    }
}

sub get_next_row_hashref {
    my $self = shift;
    my $row = $self->get_next_item;
    +{ map {($self->{columns}[$_] => $row->[$_])} 0..$#{$self->{columns}} };
}

sub get_iterator_pos {
    my $self = shift;
    $self->{pos};
}

sub reset_iterator {
    my $self = shift;
    $self->{file_pos} = 0;
    my $fh = $self->{files}[0]{fh};
    seek $fh, $self->{files}[0]{fhpos_datarow_begin}, 0;
    $self->{pos} = 0;
}

1;
# ABSTRACT: Role to access table data from CSV in a set of files/filehandles

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Source::CSVInFiles - Role to access table data from CSV in a set of files/filehandles

=head1 VERSION

This document describes version 0.017 of TableDataRole::Source::CSVInFiles (from Perl distribution TableDataRoles-Standard), released on 2023-08-31.

=head1 SYNOPSIS

To use this role and create a curried constructor:

 package TableDataRole::MyTable;
 use Role::Tiny;
 with 'TableDataRole::Source::CSVInFiles';
 around new => sub {
     my $orig = shift;
     $orig->(@_, filenames => ['/path/to/some.csv', '/path/to/another.csv']); # you can also pass 'filehandles', alternatively
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

This role expects table data in CSV format in a specified set of
files/filehandles. First row of each CSV file MUST contain the column names. All
CSV files must have identical columns.

=for Pod::Coverage ^(.+)$

=head1 ROLES MIXED IN

L<TableDataRole::Spec::Basic>

=head1 PROVIDED METHODS

=head2 new

Usage:

 my $obj = $class->new(%args);

Constructor. Known arguments:

=over

=item * filenames

Supply paths to the CSV files. Alternatively, you can also pass C<filehandles>
instead. Either C<filenames> or C<filehandles> is required.

At least one filename is required.

All the CSV files must have header row and identical columns.

=item * filehandles

Supply handles to the CSV files. Alternatively, you can also pass C<filenames>
instead. Either C<filenames> or C<filehandles> is required.

At least one filehandle is required.

All the CSV files must have header row and identical columns.

=back

Note that if your class wants to wrap this constructor in its own, you need to
create another role first, as shown in the example in Synopsis.

=head2 as_csv

A more efficient version than one provided by L<TableDataRole::Util::CSV>, since
the data is already in CSV files.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataRoles-Standard>.

=head1 SEE ALSO

L<TableDataRole::Source::CSVInFile>

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
