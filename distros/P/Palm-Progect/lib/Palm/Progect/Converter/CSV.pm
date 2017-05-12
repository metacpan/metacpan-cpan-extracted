
use strict;
package Palm::Progect::Converter::CSV;

=head1 NAME

Palm::Progect::Converter::CSV - Convert between Progect databases and CSV files

=head1 SYNOPSIS

    my $converter = Palm::Progect::Converter->new(
        format => 'CSV',
        # ... other args ...
    );

    $converter->load_records();

    # ... do stuff with records

    $converter->save_records();

=head1 DESCRIPTION

This converts between CSV files and C<Palm::Progect> records and preferences.

The CSV format allows for basic import/export with spreadsheet programs.
The CSV file does not look like a tree structure; instead, there is a C<level>
column, which indicates the indent level for the current row.

The columns in the format are:

=over 4

=item level

The indent level of the record.

=item description

=item priority

The priority of the record from 1 to 5, or 0 for no priority.

=item isAction

=item isProgress

=item isNumeric

=item isInfo

Any record can have one (and only one) of the above types.

If you are going to change the type of a record, remember
to set all the other types to false:

    isAction isProgress isNumeric isInfo
    0        0          0         1

=item completed

Completed has different values depending upon the type of record.
For action items, it is either 1 or 0, for complete or not complete.

For Progress items, it is a number between 1 and 100, indicating a
percentage.

For Numeric items it is a number between 1 and 100 indicating the
the integer percentage of the C<numericActual> value divided by
the C<numericLimit> value.

=item numericActual

The numerator of a numeric record.  If the numeric value of
a record is C<4/5>, then the C<numericActual> value is C<4>.

=item numericLimit

The denominator of a numeric record.  If the numeric value of
a record is C<4/5>, then the C<numericLimit> value is C<5>.

=item DateDue

This is a date in the format specified on the command line with the
C<--csv-date-format> option

=item category

=item opened

=item description

=item note

=back

=head1 OPTIONS

These options can be passed to the C<Palm::Progect::Converter> constructor,
for instance:

    my $converter = Palm::Progect::Converter->new(
        format       => 'CSV',
        use_unix_eol => 1,
    );

=over 4

=item separator

Use the given character as the csv separator (defaults to ;)

=item use_pc_eol

If true, use \r\n as the csv line terminator (the default)

=item use_unix_eol

If true, use \n as the csv line terminator

=item use_mac_eol

If true, use \r the csv line terminator

=item date_format

The format for dates:  Any combination of dd, mm, yy, yyyy (default is dd/mm/yy).

Any dates that are printed will use this format. Dates that are parsed will
be expected to be in this format.

Note that even though the command-line option is called C<csv-date-format>,
when passed to C<Palm::Progect::Converter>, the option is called C<date_format>:

    my $converter = Palm::Progect::Converter->new(
        format      => 'CSV',
        date_format => 'mm-dd-yy',
    );


=item quote_char

Use the given character as the csv quote char (defaults to ")

=back

=cut

use Palm::Progect::Constants;

use CLASS;
use base qw(Class::Accessor Class::Constructor);

use base 'Palm::Progect::Converter';

use Palm::Progect::Date;
use Text::CSV_XS;

use IO::File;

################################################################################
# Class methods for providing info on options

sub provides_import     { 1 }
sub provides_export     { 1 }
sub accepted_extensions { 'csv' }

sub options_spec {
    return {
        separator    => [ 'csv-sep=s',         ';',          '  --csv-sep=c        Use character c as the csv separator (defaults to ;)'  ],
        use_pc_eol   => [ 'csv-eol-pc',        1,            '  --csv-eol-pc       Use \r\n as the csv line terminator (the default)'     ],
        use_unix_eol => [ 'csv-eol-unix',      0,            '  --csv-eol-unix     Use \n as the csv line terminator'                     ],
        use_mac_eol  => [ 'csv-eol-mac',       0,            '  --csv-eol-mac      Use \r the csv line terminator'                        ],
        date_format  => [ 'csv-date-format=s', 'yyyy/mm/dd', '  --date-format=s    Any combination of dd, mm, yy, yyyy (default is dd/mm/yy)'  ],
        quote_char   => [ 'csv-quote-char=s',  '"',          '  --csv-quote-char=c Use character c as the csv quote char (defaults to ")' ],
    };
}

my @CSV_Fields = qw(
    level
    priority
    completed
    isAction
    isProgress
    isNumeric
    isInfo
    hasToDo
    numericActual
    numericLimit
    dateDue
    category
    opened
    description
    note
    todo_link_data
);

my %CSV_Field_Map = qw(
    level                 level
    description           description
    priority              priority
    completed             completed
    hastodo               has_todo
    numericactual         completed_actual
    numericlimit          completed_limit
    category              category_name
    opened                is_opened
    note                  note
    todo_link_data        todo_link_data
);

my @Accessors = qw(
    separator
    use_pc_eol
    use_unix_eol
    use_mac_eol
    date_format
    quote_char
);

CLASS->mk_accessors(@Accessors);
CLASS->mk_constructor(
    Auto_Init => \@Accessors
);

=head1 METHODS

=over 4

=item load_records($file, $append)

Load CSV records from C<$file>, translating them into the
internal C<Palm::Progect::Record> format.

If C<$append> is true then C<load_records> will B<append> the records
imported from C<$file> to the internal records list.  If false,
C<load_records> will B<replace> the internal records list with the
records imported from C<$file>.

=cut

sub load_records {
    my ($self, $filename, $append) = @_;
    print STDERR "Loading CSV format from $filename\n" unless $self->quiet;

    my %legal_csv_fields = map { lc $_ => 1 } @CSV_Fields;

    my @records;

    local ($_);
    my $fh = new IO::File;
    $fh->open("< $filename") or die "Can't open $filename for reading: $!\n";

    my $eol;
    $eol = "\r\n" if $self->use_pc_eol;
    $eol = "\n"   if $self->use_unix_eol;
    $eol = "\r"   if $self->use_mac_eol;

    my $csv = Text::CSV_XS->new({
        eol        => $eol,
        sep_char   => $self->separator,
        quote_char => $self->quote_char,
        binary     => 1,
    });

    my @headings;
    while (my $fields = $csv->getline($fh)) {

        # strip out illegal nulls
        s/\0//g foreach @$fields;

        last if !@$fields;

        unless (@headings) {
            @headings = @$fields;
            my @bad_headings = grep { !$legal_csv_fields{lc $_} } @headings;
            if (@bad_headings > 0) {
                die "Bad heading name(s) in CSV file: (" . (join ", ", @bad_headings) . ")\n";
            }
            next;
        }

        my $record = new Palm::Progect::Record;

        # map each field to its heading

        for (my $i = 0; $i < @headings; $i++) {
            my $heading = lc $headings[$i];
            my $field   = $fields->[$i];

            if ($heading eq 'datedue') {
                $record->date_due(parse_date($field, $self->date_format)) if $field;
            }
            elsif ($heading eq 'isaction') {
                $record->type(RECORD_TYPE_ACTION) if $field;
            }
            elsif ($heading eq 'isprogress') {
                $record->type(RECORD_TYPE_PROGRESS) if $field;
            }
            elsif ($heading eq 'isnumeric') {
                $record->type(RECORD_TYPE_NUMERIC) if $field;
            }
            elsif ($heading eq 'isinfo') {
                $record->type(RECORD_TYPE_INFO) if $field;
            }
            else {
                my $method = $CSV_Field_Map{$heading} or die "Internal error: Unknown CSV Field $heading (snuck past test for that...)";
                $record->$method($field);
            }
        }
        push @records, $record;
    }

    $fh->close;

    if ($append) {
        $self->records(@{ $self->records } , @records);
    }
    else {
        $self->records(@records);
    }

}

=item save_records($file, $append)

Export records in CSV format to C<$file>.

If C<$append> is true then C<load_records> will B<append> the CSV lines to
C<file>.  If false, C<export_records> If false, C<export_records> will
overwrite C<$file> (if it exists) before writing the lines.

=back

=cut

sub save_records {
    my ($self, $filename, $append) = @_;
    print STDERR "Saving CSV format to $filename\n" unless $self->quiet;

    local (*FH);

    if ($filename) {
        if ($append) {
            print STDERR "Appending Records in CSV format to $filename\n" unless $self->quiet;
            open FH, ">>$filename" or die "Can't append to $filename: $!\n";
        }
        else {
            print STDERR "Saving CSV format to $filename\n" unless $self->quiet;
            open FH, ">$filename" or die "Can't clobber $filename: $!\n";
        }
    }
    else {
        print STDERR "Dumping CSV format to STDOUT\n" unless $self->quiet;
        open FH, ">&STDOUT" or die "Can't dup STDOUT: $!\n";
    }

    my $eol;
    $eol = "\r\n" if $self->use_pc_eol;
    $eol = "\n"   if $self->use_unix_eol;
    $eol = "\r"   if $self->use_mac_eol;

    my $csv = Text::CSV_XS->new({
        eol        => $eol,
        sep_char   => $self->separator,
        quote_char => $self->quote_char,
        binary     => 1,
    });

    $csv->combine(@CSV_Fields);
    print FH $csv->string;

    my $i = 0;
    foreach my $record (@{$self->records}) {
        $i++;
        # Skip the invisible root record
        next if $i == 1 and not $record->level;

        my @row;
        foreach my $field (@CSV_Fields) {

            $field = lc $field;

            if ($field eq 'datedue') {
                if ($record->date_due) {
                    push @row, scalar(format_date($record->date_due, $self->date_format));
                }
                else {
                    push @row, '';
                }
            }
            elsif ($field eq 'isaction') {
                push @row, $record->type == RECORD_TYPE_ACTION? 1 : '';
            }
            elsif ($field eq 'isprogress') {
                push @row, $record->type == RECORD_TYPE_PROGRESS? 1 : '';
            }
            elsif ($field eq 'isnumeric') {
                push @row, $record->type == RECORD_TYPE_NUMERIC? 1 : '';
            }
            elsif ($field eq 'isinfo') {
                push @row, $record->type == RECORD_TYPE_INFO? 1 : '';
            }
            else {
                my $method = $CSV_Field_Map{$field} or die "Internal error: Unknown CSV Field $field (snuck past test for that...)";
                push @row, $record->$method();
            }

        }
        $csv->combine(@row);

        print FH $csv->string;
    }
    close FH;
}

1;

__END__

=head1 AUTHOR

Michael Graham E<lt>mag-perl@occamstoothbrush.comE<gt>

Copyright (C) 2002-2005 Michael Graham.  All rights reserved.
This program is free software.  You can use, modify,
and distribute it under the same terms as Perl itself.

The latest version of this module can be found on http://www.occamstoothbrush.com/perl/

=head1 SEE ALSO

C<progconv>

L<Palm::PDB(3)>

http://progect.sourceforge.net/

=cut

